#import "ConsoleDockCore.h"
#import "CDKStandardOutputCapture.h"

NSErrorDomain const CDKConsoleDockErrorDomain = @"CDKConsoleDockErrorDomain";
NSNotificationName const CDKConsoleDockEntriesDidChangeNotification = @"CDKConsoleDockEntriesDidChangeNotification";

static BOOL CDKConsoleDockRunning = NO;
static BOOL CDKConsoleDockStopping = NO;
static CDKConfiguration *CDKConsoleDockConfiguration = nil;
static NSMutableArray<CDKLogEntry *> *CDKConsoleDockEntries = nil;
static CDKStandardOutputCapture *CDKConsoleDockCapture = nil;
static unsigned long long CDKConsoleDockNextEntryIdentifier = 0;

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
                                           @"Authorization\\s*[:=]\\s*Bearer\\s+[^\\s,;]+",
                                           @"Authorization: Bearer <redacted>");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\b(Set-Cookie|Cookie)\\s*:\\s*[^\\r\\n]+",
                                           @"$1: <redacted>");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"(\"?(?:password|passwd|token|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|key|secret)\"?\\s*[:=]\\s*\")([^\"]+)(\")",
                                           @"$1<redacted>$3");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\b(password|passwd|token|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|key|secret)\\b\\s*[:=]\\s*[^\\s,;&]+",
                                           @"$1=<redacted>");
    return redacted;
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

static void CDKPostEntriesDidChangeNotification(void)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CDKConsoleDockEntriesDidChangeNotification
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
        CDKConsoleDockRunning = YES;
    }
    if (didResetEntries) {
        CDKPostEntriesDidChangeNotification();
    }
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

    [capture stop];

    @synchronized(self) {
        CDKConsoleDockRunning = NO;
        CDKConsoleDockStopping = NO;
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
                                  allowsReleaseBuilds:configuration.allowsReleaseBuilds
                                       maximumEntries:configuration.maximumEntries
                                 maximumMessageLength:configuration.maximumMessageLength
                                           entryCount:CDKConsoleDockEntries.count
                                   redactedEntryCount:redactedEntryCount
                                  truncatedEntryCount:truncatedEntryCount
                                    partialEntryCount:partialEntryCount];
    }
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
    }
}

+ (void)appendEntryWithLevel:(CDKLogLevel)level
                      source:(CDKLogSource)source
                     message:(NSString *)message
                   isPartial:(BOOL)isPartial
{
    BOOL didAppend = NO;
    @synchronized(self) {
        if (!CDKConsoleDockRunning || CDKConsoleDockConfiguration == nil) {
            return;
        }

        BOOL redacted = NO;
        BOOL truncated = NO;
        NSString *preparedMessage = CDKPreparedMessage(message, CDKConsoleDockConfiguration, &redacted, &truncated);
        CDKConsoleDockNextEntryIdentifier += 1;
        CDKLogEntry *entry = [[CDKLogEntry alloc] initWithIdentifier:CDKConsoleDockNextEntryIdentifier
                                                           timestamp:[NSDate date]
                                                               level:level
                                                              source:source
                                                             message:preparedMessage
                                                           isPartial:isPartial
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
    }
}

+ (void)appendLineEvent:(CDKLineEvent *)event
{
    [self appendEntryWithLevel:CDKDefaultLevelForSource(event.source)
                        source:event.source
                       message:event.message
                     isPartial:event.partial];
}

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message
{
    [self appendEntryWithLevel:level source:CDKLogSourceNative message:message isPartial:NO];
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
