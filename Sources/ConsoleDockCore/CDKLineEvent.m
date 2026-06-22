#import "ConsoleDockCore.h"

@implementation CDKLineEvent

- (instancetype)initWithSource:(CDKLogSource)source
                       message:(NSString *)message
                     isPartial:(BOOL)isPartial
{
    self = [super init];
    if (self) {
        _source = source;
        _message = [message copy];
        _partial = isPartial;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
