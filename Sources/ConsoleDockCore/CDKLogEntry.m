#import "ConsoleDockCore.h"

@implementation CDKLogEntry

- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message
{
    return [self initWithIdentifier:identifier
                          timestamp:timestamp
                              level:level
                             source:source
                            message:message
                           redacted:NO
                          truncated:NO];
}

- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message
                          redacted:(BOOL)redacted
                         truncated:(BOOL)truncated
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _timestamp = [timestamp copy];
        _level = level;
        _source = source;
        _message = [message copy];
        _redacted = redacted;
        _truncated = truncated;
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
