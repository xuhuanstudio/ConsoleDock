#import "ConsoleDockCore.h"
#import "CDKStandardOutputCapture.h"

#import <dispatch/dispatch.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

NSErrorDomain const CDKConsoleDockErrorDomain = @"CDKConsoleDockErrorDomain";
NSNotificationName const CDKConsoleDockEntriesDidChangeNotification = @"CDKConsoleDockEntriesDidChangeNotification";
NSNotificationName const CDKConsoleDockDiagnosticsDidChangeNotification = @"CDKConsoleDockDiagnosticsDidChangeNotification";

static BOOL CDKConsoleDockRunning = NO;
static BOOL CDKConsoleDockStopping = NO;
static CDKConfiguration *CDKConsoleDockConfiguration = nil;
static NSMutableArray<CDKLogEntry *> *CDKConsoleDockEntries = nil;
static CDKStandardOutputCapture *CDKConsoleDockCapture = nil;
static unsigned long long CDKConsoleDockNextEntryIdentifier = 0;
static NSString *CDKConsoleDockSessionIdentifier = nil;
static NSDate *CDKConsoleDockStartedAt = nil;
static BOOL CDKConsoleDockRedactNativeContinuation = NO;
static BOOL CDKConsoleDockRedactStdoutContinuation = NO;
static BOOL CDKConsoleDockRedactStderrContinuation = NO;
static NSString *CDKConsoleDockSensitiveNativeContinuationTail = nil;
static NSString *CDKConsoleDockSensitiveStdoutContinuationTail = nil;
static NSString *CDKConsoleDockSensitiveStderrContinuationTail = nil;

static NSString *const CDKRedactedPartialContinuationMessage = @"<redacted partial continuation>";
static NSString *const CDKMarkerPrefix = @"[marker]";
static NSString *const CDKDefaultMarkerText = @"Marker";
static NSUInteger const CDKSensitiveContinuationTailLength = 64;

static NSString *CDKStringByReplacingMatches(NSString *message, NSString *pattern, NSString *replacement)
{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:nil];
    NSRange range = NSMakeRange(0, message.length);
    return [expression stringByReplacingMatchesInString:message
                                                options:0
                                                  range:range
                                           withTemplate:replacement];
}

static NSString *CDKDefaultRedactedMessage(NSString *message)
{
    NSString *redacted = [message copy];
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\bAuthorization\\s*[:=]\\s*[^\\r\\n]+",
                                           @"Authorization: <redacted>");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\b(Set-Cookie|Cookie)\\s*:\\s*[^\\r\\n]+",
                                           @"$1: <redacted>");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"(\"?(?:password|passwd|token|id[_-]?token|auth[_-]?token|session[_-]?token|csrf[_-]?token|access[_-]?token|refresh[_-]?token|x[_-]?api[_-]?key|api[_-]?key|client[_-]?secret|key|secret)\"?\\s*[:=]\\s*\")([^\"]+)(\")",
                                           @"$1<redacted>$3");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\b(password|passwd|token|id[_-]?token|auth[_-]?token|session[_-]?token|csrf[_-]?token|access[_-]?token|refresh[_-]?token|x[_-]?api[_-]?key|api[_-]?key|client[_-]?secret|key|secret)\\b\\s*[:=]\\s*[^\\s,;&]+",
                                           @"$1=<redacted>");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\bBearer\\s+[^\\s,;&]+",
                                           @"Bearer <redacted>");
    return redacted;
}

static BOOL CDKStringMatchesPattern(NSString *message, NSString *pattern)
{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:nil];
    NSRange range = NSMakeRange(0, message.length);
    return [expression firstMatchInString:message options:0 range:range] != nil;
}

static BOOL CDKDefaultRedactorWouldChangeMessage(NSString *message)
{
    NSString *original = message ?: @"";
    return ![CDKDefaultRedactedMessage(original) isEqualToString:original];
}

static BOOL CDKTrailingIdentifierMayBeSensitivePrefix(NSString *message)
{
    NSCharacterSet *identifierCharacters = [NSCharacterSet characterSetWithCharactersInString:
                                            @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"];
    NSUInteger end = message.length;
    while (end > 0) {
        unichar character = [message characterAtIndex:end - 1];
        if ([identifierCharacters characterIsMember:character]) {
            break;
        }
        end -= 1;
    }
    if (end == 0) {
        return NO;
    }

    NSUInteger start = end;
    while (start > 0) {
        unichar character = [message characterAtIndex:start - 1];
        if (![identifierCharacters characterIsMember:character]) {
            break;
        }
        start -= 1;
    }

    NSString *trailingIdentifier = [[message substringWithRange:NSMakeRange(start, end - start)] lowercaseString];
    NSString *compactTrailingIdentifier =
        [[trailingIdentifier stringByReplacingOccurrencesOfString:@"_" withString:@""]
            stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (compactTrailingIdentifier.length < 3) {
        return NO;
    }

    NSArray<NSString *> *sensitiveNames = @[
        @"authorization",
        @"setcookie",
        @"cookie",
        @"password",
        @"passwd",
        @"token",
        @"idtoken",
        @"authtoken",
        @"sessiontoken",
        @"csrftoken",
        @"accesstoken",
        @"refreshtoken",
        @"xapikey",
        @"apikey",
        @"clientsecret",
        @"privatekey",
        @"bearer",
        @"secret"
    ];
    for (NSString *name in sensitiveNames) {
        if ([name hasPrefix:compactTrailingIdentifier]) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDKMessageMayStartSensitiveContinuation(NSString *message)
{
    NSString *trimmed = [(message ?: @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return NO;
    }

    NSArray<NSString *> *patterns = @[
        @"\\bAuthorization\\s*[:=]\\s*(?:Bearer\\s*)?$",
        @"\\bBearer\\s*$",
        @"\\b(?:Set-Cookie|Cookie)\\s*:\\s*$",
        @"\\b(?:password|passwd|token|id[_-]?token|auth[_-]?token|session[_-]?token|csrf[_-]?token|access[_-]?token|refresh[_-]?token|x[_-]?api[_-]?key|api[_-]?key|client[_-]?secret|key|secret)\\b\\s*[:=]\\s*\"?$"
    ];
    for (NSString *pattern in patterns) {
        if (CDKStringMatchesPattern(trimmed, pattern)) {
            return YES;
        }
    }

    return CDKTrailingIdentifierMayBeSensitivePrefix(trimmed);
}

static NSString *CDKContinuationTail(NSString *message)
{
    NSString *text = message ?: @"";
    if (text.length <= CDKSensitiveContinuationTailLength) {
        return [text copy];
    }
    return [text substringFromIndex:text.length - CDKSensitiveContinuationTailLength];
}

static NSString *CDKPreparedMessage(NSString *message,
                                    CDKConfiguration *configuration,
                                    BOOL *redacted,
                                    BOOL *truncated)
{
    NSString *original = message ?: @"";
    NSString *prepared = CDKDefaultRedactedMessage(original);
    BOOL didRedact = ![prepared isEqualToString:original];
    if (configuration.redactionBlock != nil) {
        NSString *beforeCustomRedaction = prepared;
        NSString *customRedacted = configuration.redactionBlock(prepared);
        if (customRedacted != nil) {
            prepared = customRedacted;
            didRedact = didRedact || ![prepared isEqualToString:beforeCustomRedaction];
        }
    }

    BOOL didTruncate = NO;
    if (prepared.length > configuration.maximumMessageLength) {
        prepared = [prepared substringToIndex:configuration.maximumMessageLength];
        didTruncate = YES;
    }

    if (redacted != NULL) {
        *redacted = didRedact;
    }
    if (truncated != NULL) {
        *truncated = didTruncate;
    }

    return prepared;
}

static BOOL CDKShouldRedactContinuationForSource(CDKLogSource source)
{
    switch (source) {
        case CDKLogSourceStdout:
            return CDKConsoleDockRedactStdoutContinuation;
        case CDKLogSourceStderr:
            return CDKConsoleDockRedactStderrContinuation;
        case CDKLogSourceNative:
        default:
            return CDKConsoleDockRedactNativeContinuation;
    }
}

static void CDKSetRedactContinuationForSource(CDKLogSource source, BOOL value)
{
    switch (source) {
        case CDKLogSourceStdout:
            CDKConsoleDockRedactStdoutContinuation = value;
            break;
        case CDKLogSourceStderr:
            CDKConsoleDockRedactStderrContinuation = value;
            break;
        case CDKLogSourceNative:
        default:
            CDKConsoleDockRedactNativeContinuation = value;
            break;
    }
}

static NSString *CDKSensitiveContinuationTailForSource(CDKLogSource source)
{
    switch (source) {
        case CDKLogSourceStdout:
            return CDKConsoleDockSensitiveStdoutContinuationTail;
        case CDKLogSourceStderr:
            return CDKConsoleDockSensitiveStderrContinuationTail;
        case CDKLogSourceNative:
        default:
            return CDKConsoleDockSensitiveNativeContinuationTail;
    }
}

static void CDKSetSensitiveContinuationTailForSource(CDKLogSource source, NSString *value)
{
    switch (source) {
        case CDKLogSourceStdout:
            CDKConsoleDockSensitiveStdoutContinuationTail = [value copy];
            break;
        case CDKLogSourceStderr:
            CDKConsoleDockSensitiveStderrContinuationTail = [value copy];
            break;
        case CDKLogSourceNative:
        default:
            CDKConsoleDockSensitiveNativeContinuationTail = [value copy];
            break;
    }
}

static void CDKClearRedactContinuationState(void)
{
    CDKConsoleDockRedactNativeContinuation = NO;
    CDKConsoleDockRedactStdoutContinuation = NO;
    CDKConsoleDockRedactStderrContinuation = NO;
    CDKConsoleDockSensitiveNativeContinuationTail = nil;
    CDKConsoleDockSensitiveStdoutContinuationTail = nil;
    CDKConsoleDockSensitiveStderrContinuationTail = nil;
}

static CDKLogLevel CDKDefaultLevelForSource(CDKLogSource source)
{
    switch (source) {
        case CDKLogSourceStderr:
            return CDKLogLevelError;
        case CDKLogSourceStdout:
        case CDKLogSourceNative:
        default:
            return CDKLogLevelInfo;
    }
}

static NSString *CDKTrimmedString(NSString *message)
{
    return [(message ?: @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *CDKMarkerMessage(NSString *message)
{
    NSString *trimmedMessage = CDKTrimmedString(message);
    NSString *body = trimmedMessage.length > 0 ? trimmedMessage : CDKDefaultMarkerText;
    return [NSString stringWithFormat:@"%@ %@", CDKMarkerPrefix, body];
}

static NSString *CDKCurrentSessionIdentifier(void)
{
    if (CDKConsoleDockSessionIdentifier == nil) {
        CDKConsoleDockSessionIdentifier = [[NSUUID UUID] UUIDString];
    }
    return CDKConsoleDockSessionIdentifier;
}

static NSString *CDKDeviceModel(void)
{
#if __has_include(<UIKit/UIKit.h>)
    return UIDevice.currentDevice.model ?: @"unknown";
#else
    return @"unknown";
#endif
}

static NSString *CDKBundleString(NSString *key)
{
    id value = [NSBundle.mainBundle objectForInfoDictionaryKey:key];
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static void CDKPostEntriesDidChangeNotification(void)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CDKConsoleDockEntriesDidChangeNotification
                                                        object:CDKConsoleDock.class];
}

static void CDKPostDiagnosticsDidChangeNotification(void)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CDKConsoleDockDiagnosticsDidChangeNotification
                                                        object:CDKConsoleDock.class];
}

@implementation CDKConsoleDock

+ (CDKStartResult)startWithConfiguration:(CDKConfiguration *)configuration
{
    return [self startWithConfiguration:configuration error:nil];
}

+ (CDKStartResult)startWithConfiguration:(CDKConfiguration *)configuration
                                   error:(NSError **)error
{
#if defined(DEBUG) || defined(CONSOLEDOCK_ENABLE_RELEASE)
    BOOL didResetEntries = NO;
    @synchronized(self) {
        if (CDKConsoleDockRunning || CDKConsoleDockStopping) {
            return CDKStartResultAlreadyRunning;
        }

        CDKConfiguration *effectiveConfiguration = configuration ?: [CDKConfiguration defaultConfiguration];
#if !defined(DEBUG) && defined(CONSOLEDOCK_ENABLE_RELEASE)
        if (!effectiveConfiguration.allowsReleaseBuilds) {
            return CDKStartResultDisabled;
        }
#endif
        if (effectiveConfiguration.maximumEntries == 0) {
            if (error != nil) {
                *error = [NSError errorWithDomain:CDKConsoleDockErrorDomain
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey: @"maximumEntries must be greater than zero"}];
            }
            return CDKStartResultFailed;
        }
        if (effectiveConfiguration.maximumMessageLength == 0) {
            if (error != nil) {
                *error = [NSError errorWithDomain:CDKConsoleDockErrorDomain
                                             code:2
                                         userInfo:@{NSLocalizedDescriptionKey: @"maximumMessageLength must be greater than zero"}];
            }
            return CDKStartResultFailed;
        }

        didResetEntries = CDKConsoleDockEntries.count > 0;
        CDKConsoleDockConfiguration = [effectiveConfiguration copy];
        CDKConsoleDockEntries = [NSMutableArray arrayWithCapacity:MIN(CDKConsoleDockConfiguration.maximumEntries, 64)];
        CDKConsoleDockNextEntryIdentifier = 0;
        CDKClearRedactContinuationState();
        CDKStandardOutputCapture *capture = [[CDKStandardOutputCapture alloc] initWithConfiguration:CDKConsoleDockConfiguration];
        NSError *captureError = nil;
        if (![capture startWithError:&captureError]) {
            [capture stop];
            CDKConsoleDockConfiguration = nil;
            CDKConsoleDockEntries = nil;
            if (error != nil) {
                *error = captureError ?: [NSError errorWithDomain:CDKConsoleDockErrorDomain
                                                             code:100
                                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to start standard output capture."}];
            }
            return CDKStartResultFailed;
        }

        CDKConsoleDockCapture = capture;
        CDKConsoleDockSessionIdentifier = [[NSUUID UUID] UUIDString];
        CDKConsoleDockStartedAt = [NSDate date];
        CDKConsoleDockRunning = YES;
    }
    if (didResetEntries) {
        CDKPostEntriesDidChangeNotification();
    }
    CDKPostDiagnosticsDidChangeNotification();
    return CDKStartResultStarted;
#else
    (void)configuration;
    if (error != nil) {
        *error = nil;
    }
    return CDKStartResultDisabled;
#endif
}

+ (void)stop
{
    CDKStandardOutputCapture *capture = nil;
    @synchronized(self) {
        if ((!CDKConsoleDockRunning && CDKConsoleDockCapture == nil) || CDKConsoleDockStopping) {
            return;
        }
        CDKConsoleDockStopping = YES;
        capture = CDKConsoleDockCapture;
        CDKConsoleDockCapture = nil;
    }

    void (^finishStopping)(void) = ^{
        [capture stop];

        @synchronized(self) {
            CDKConsoleDockRunning = NO;
            CDKConsoleDockStopping = NO;
            CDKClearRedactContinuationState();
        }
        CDKPostDiagnosticsDidChangeNotification();
    };

    if ([capture isExecutingOnReaderThread]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), finishStopping);
    } else {
        finishStopping();
    }
}

+ (BOOL)isRunning
{
    @synchronized(self) {
        return CDKConsoleDockRunning;
    }
}

+ (CDKDiagnostics *)diagnostics
{
    @synchronized(self) {
        BOOL hasStoredEntries = CDKConsoleDockEntries.count > 0;
        BOOL shouldUseActiveConfiguration = CDKConsoleDockRunning || hasStoredEntries;
        CDKConfiguration *configuration =
            shouldUseActiveConfiguration && CDKConsoleDockConfiguration != nil
                ? CDKConsoleDockConfiguration
                : [CDKConfiguration defaultConfiguration];
        NSUInteger redactedEntryCount = 0;
        NSUInteger truncatedEntryCount = 0;
        NSUInteger partialEntryCount = 0;

        for (CDKLogEntry *entry in CDKConsoleDockEntries) {
            if (entry.redacted) {
                redactedEntryCount += 1;
            }
            if (entry.truncated) {
                truncatedEntryCount += 1;
            }
            if (entry.isPartial) {
                partialEntryCount += 1;
            }
        }

        return [[CDKDiagnostics alloc] initWithRunning:CDKConsoleDockRunning
                                captureStandardOutput:configuration.captureStandardOutput
                                 captureStandardError:configuration.captureStandardError
                                  showsFloatingButton:configuration.showsFloatingButton
                                floatingButtonPosition:configuration.floatingButtonPosition
                                  allowsReleaseBuilds:configuration.allowsReleaseBuilds
                                       maximumEntries:configuration.maximumEntries
                                 maximumMessageLength:configuration.maximumMessageLength
                                           entryCount:CDKConsoleDockEntries.count
                                   redactedEntryCount:redactedEntryCount
                                  truncatedEntryCount:truncatedEntryCount
                                    partialEntryCount:partialEntryCount];
    }
}

+ (CDKSessionMetadata *)sessionMetadata
{
    NSString *sessionIdentifier = nil;
    NSDate *startedAt = nil;
    @synchronized(self) {
        sessionIdentifier = [CDKCurrentSessionIdentifier() copy];
        startedAt = [CDKConsoleDockStartedAt copy];
    }

    NSProcessInfo *processInfo = NSProcessInfo.processInfo;
    return [[CDKSessionMetadata alloc] initWithSessionIdentifier:sessionIdentifier
                                                      startedAt:startedAt
                                                    generatedAt:[NSDate date]
                                               bundleIdentifier:NSBundle.mainBundle.bundleIdentifier
                                                     appVersion:CDKBundleString(@"CFBundleShortVersionString")
                                                       appBuild:CDKBundleString(@"CFBundleVersion")
                                                    processName:processInfo.processName ?: @"unknown"
                                         operatingSystemVersion:processInfo.operatingSystemVersionString ?: @"unknown"
                                                    deviceModel:CDKDeviceModel()
                                               localeIdentifier:NSLocale.currentLocale.localeIdentifier ?: @"unknown"
                                             timeZoneIdentifier:NSTimeZone.localTimeZone.name ?: @"unknown"];
}

+ (NSArray<CDKLogEntry *> *)entries
{
    @synchronized(self) {
        return [CDKConsoleDockEntries copy] ?: @[];
    }
}

+ (void)clearEntries
{
    BOOL didClear = NO;
    @synchronized(self) {
        didClear = CDKConsoleDockEntries.count > 0;
        if (didClear) {
            [CDKConsoleDockEntries removeAllObjects];
        }
    }

    if (didClear) {
        CDKPostEntriesDidChangeNotification();
        CDKPostDiagnosticsDidChangeNotification();
    }
}

+ (void)appendEntryWithLevel:(CDKLogLevel)level
                      source:(CDKLogSource)source
                     message:(NSString *)message
                   isPartial:(BOOL)isPartial
                    isMarker:(BOOL)isMarker
{
    BOOL didAppend = NO;
    @synchronized(self) {
        if (!CDKConsoleDockRunning || CDKConsoleDockConfiguration == nil) {
            return;
        }

        BOOL redacted = NO;
        BOOL truncated = NO;
        BOOL shouldRedactContinuation = CDKShouldRedactContinuationForSource(source);
        NSString *continuationTail = CDKSensitiveContinuationTailForSource(source);
        NSString *messageForContinuationCheck = message ?: @"";
        NSString *combinedContinuationMessage =
            continuationTail.length > 0 ? [continuationTail stringByAppendingString:messageForContinuationCheck] : nil;
        BOOL combinedMessageLooksSensitive = continuationTail.length > 0
            && CDKDefaultRedactorWouldChangeMessage(combinedContinuationMessage);
        BOOL shouldRedactCurrentFragment = shouldRedactContinuation || combinedMessageLooksSensitive;
        NSString *messageToPrepare = shouldRedactCurrentFragment ? CDKRedactedPartialContinuationMessage : message;
        NSString *preparedMessage = CDKPreparedMessage(messageToPrepare, CDKConsoleDockConfiguration, &redacted, &truncated);
        redacted = redacted || shouldRedactCurrentFragment;
        if (isPartial) {
            CDKSetRedactContinuationForSource(source, redacted || CDKMessageMayStartSensitiveContinuation(message));
            CDKSetSensitiveContinuationTailForSource(source, CDKContinuationTail(message));
        } else {
            CDKSetRedactContinuationForSource(source, NO);
            CDKSetSensitiveContinuationTailForSource(source, nil);
        }
        CDKConsoleDockNextEntryIdentifier += 1;
        CDKLogEntry *entry = [[CDKLogEntry alloc] initWithIdentifier:CDKConsoleDockNextEntryIdentifier
                                                           timestamp:[NSDate date]
                                                               level:level
                                                              source:source
                                                             message:preparedMessage
                                                           isPartial:isPartial
                                                            isMarker:isMarker
                                                            redacted:redacted
                                                           truncated:truncated];
        if (CDKConsoleDockEntries == nil) {
            CDKConsoleDockEntries = [NSMutableArray array];
        }
        [CDKConsoleDockEntries addObject:entry];

        while (CDKConsoleDockEntries.count > CDKConsoleDockConfiguration.maximumEntries) {
            [CDKConsoleDockEntries removeObjectAtIndex:0];
        }
        didAppend = YES;
    }

    if (didAppend) {
        CDKPostEntriesDidChangeNotification();
        CDKPostDiagnosticsDidChangeNotification();
    }
}

+ (void)appendLineEvent:(CDKLineEvent *)event
{
    [self appendEntryWithLevel:CDKDefaultLevelForSource(event.source)
                        source:event.source
                       message:event.message
                     isPartial:event.partial
                      isMarker:NO];
}

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message
{
    [self appendEntryWithLevel:level source:CDKLogSourceNative message:message isPartial:NO isMarker:NO];
}

+ (void)mark:(NSString *)message
{
    [self appendEntryWithLevel:CDKLogLevelInfo
                        source:CDKLogSourceNative
                       message:CDKMarkerMessage(message)
                     isPartial:NO
                      isMarker:YES];
}

+ (void)debug:(NSString *)message
{
    [self logWithLevel:CDKLogLevelDebug message:message];
}

+ (void)info:(NSString *)message
{
    [self logWithLevel:CDKLogLevelInfo message:message];
}

+ (void)warning:(NSString *)message
{
    [self logWithLevel:CDKLogLevelWarning message:message];
}

+ (void)error:(NSString *)message
{
    [self logWithLevel:CDKLogLevelError message:message];
}

+ (void)fault:(NSString *)message
{
    [self logWithLevel:CDKLogLevelFault message:message];
}

@end
