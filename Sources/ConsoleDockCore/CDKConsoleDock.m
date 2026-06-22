#import "ConsoleDockCore.h"
#import "CDKStandardOutputCapture.h"

NSErrorDomain const CDKConsoleDockErrorDomain = @"CDKConsoleDockErrorDomain";
NSNotificationName const CDKConsoleDockEntriesDidChangeNotification = @"CDKConsoleDockEntriesDidChangeNotification";

static BOOL CDKConsoleDockRunning = NO;
static BOOL CDKConsoleDockStopping = NO;
static CDKConfiguration *CDKConsoleDockConfiguration = nil;
static NSMutableArray<CDKLogEntry *> *CDKConsoleDockEntries = nil;
static CDKStandardOutputCapture *CDKConsoleDockCapture = nil;

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
                                           @"(\"?(?:password|token|api[_-]?key|key|secret)\"?\\s*[:=]\\s*\")([^\"]+)(\")",
                                           @"$1<redacted>$3");
    redacted = CDKStringByReplacingMatches(redacted,
                                           @"\\b(password|token|api[_-]?key|key|secret)\\b\\s*[:=]\\s*[^\\s,;&]+",
                                           @"$1=<redacted>");
    return redacted;
}

static NSString *CDKPreparedMessage(NSString *message, CDKConfiguration *configuration)
{
    NSString *prepared = CDKDefaultRedactedMessage(message ?: @"");
    if (configuration.redactionBlock != nil) {
        NSString *customRedacted = configuration.redactionBlock(prepared);
        if (customRedacted != nil) {
            prepared = customRedacted;
        }
    }

    if (prepared.length > configuration.maximumMessageLength) {
        prepared = [prepared substringToIndex:configuration.maximumMessageLength];
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

+ (void)appendEntryWithLevel:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message
{
    BOOL didAppend = NO;
    @synchronized(self) {
        if (!CDKConsoleDockRunning || CDKConsoleDockConfiguration == nil) {
            return;
        }

        NSString *preparedMessage = CDKPreparedMessage(message, CDKConsoleDockConfiguration);
        CDKLogEntry *entry = [[CDKLogEntry alloc] initWithTimestamp:[NSDate date]
                                                              level:level
                                                             source:source
                                                            message:preparedMessage];
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
                       message:event.message];
}

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message
{
    [self appendEntryWithLevel:level source:CDKLogSourceNative message:message];
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

@end
