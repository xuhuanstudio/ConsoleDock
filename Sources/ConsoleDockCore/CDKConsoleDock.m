#import "ConsoleDockCore.h"

NSErrorDomain const CDKConsoleDockErrorDomain = @"CDKConsoleDockErrorDomain";

static BOOL CDKConsoleDockRunning = NO;

@implementation CDKConsoleDock

+ (CDKStartResult)startWithConfiguration:(CDKConfiguration *)configuration
{
    return [self startWithConfiguration:configuration error:nil];
}

+ (CDKStartResult)startWithConfiguration:(CDKConfiguration *)configuration
                                   error:(NSError **)error
{
#if defined(DEBUG) || defined(CONSOLEDOCK_ENABLE_RELEASE)
    if (CDKConsoleDockRunning) {
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

    CDKConsoleDockRunning = YES;
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
    CDKConsoleDockRunning = NO;
}

+ (BOOL)isRunning
{
    return CDKConsoleDockRunning;
}

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message
{
    (void)level;
    (void)message;
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
