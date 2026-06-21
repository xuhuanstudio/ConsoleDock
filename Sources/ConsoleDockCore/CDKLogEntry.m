#import "ConsoleDockCore.h"

@implementation CDKLogEntry

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                            level:(CDKLogLevel)level
                           source:(CDKLogSource)source
                          message:(NSString *)message
{
    self = [super init];
    if (self) {
        _timestamp = [timestamp copy];
        _level = level;
        _source = source;
        _message = [message copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
