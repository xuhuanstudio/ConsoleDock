#import "ConsoleDockCore.h"

@implementation CDKLogEntry

- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _timestamp = [timestamp copy];
        _level = level;
        _source = source;
        _message = [message copy];
    }
    return self;
}

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                            level:(CDKLogLevel)level
                           source:(CDKLogSource)source
                          message:(NSString *)message
{
    return [self initWithIdentifier:0
                          timestamp:timestamp
                              level:level
                             source:source
                            message:message];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
