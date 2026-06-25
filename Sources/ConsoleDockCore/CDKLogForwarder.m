#import "ConsoleDockCore.h"

static NSString *CDKForwarderSingleLine(NSString *value)
{
    NSString *safeValue = value ?: @"";
    NSString *withoutCRLF = [safeValue stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    NSString *withoutLF = [withoutCRLF stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSString *withoutCR = [withoutLF stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    return [withoutCR stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL CDKForwarderShouldLog(CDKLogLevel level, CDKLogLevel minimumLevel)
{
    return (NSInteger)level >= (NSInteger)minimumLevel;
}

@implementation CDKLogForwarder

- (instancetype)init
{
    return [self initWithCategory:nil minimumLevel:CDKLogLevelDebug];
}

- (instancetype)initWithCategory:(NSString *)category minimumLevel:(CDKLogLevel)minimumLevel
{
    self = [super init];
    if (self) {
        NSString *normalizedCategory = CDKForwarderSingleLine(category);
        _category = normalizedCategory.length > 0 ? [normalizedCategory copy] : nil;
        _minimumLevel = minimumLevel;
    }
    return self;
}

- (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message
{
    if (!CDKForwarderShouldLog(level, self.minimumLevel)) {
        return;
    }

    NSString *body = message ?: @"";
    NSString *formattedMessage =
        self.category.length > 0 ? [NSString stringWithFormat:@"[%@] %@", self.category, body] : body;
    [CDKConsoleDock logWithLevel:level message:formattedMessage];
}

- (void)debug:(NSString *)message
{
    [self logWithLevel:CDKLogLevelDebug message:message];
}

- (void)info:(NSString *)message
{
    [self logWithLevel:CDKLogLevelInfo message:message];
}

- (void)warning:(NSString *)message
{
    [self logWithLevel:CDKLogLevelWarning message:message];
}

- (void)error:(NSString *)message
{
    [self logWithLevel:CDKLogLevelError message:message];
}

- (void)fault:(NSString *)message
{
    [self logWithLevel:CDKLogLevelFault message:message];
}

@end
