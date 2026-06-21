#import "ConsoleDockCore.h"

@implementation CDKConfiguration

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maximumEntries = 2000;
        _captureStandardOutput = YES;
        _captureStandardError = YES;
        _showsFloatingButton = YES;
        _allowsReleaseBuilds = NO;
    }
    return self;
}

+ (instancetype)defaultConfiguration
{
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
    CDKConfiguration *copy = [[[self class] allocWithZone:zone] init];
    copy.maximumEntries = self.maximumEntries;
    copy.captureStandardOutput = self.captureStandardOutput;
    copy.captureStandardError = self.captureStandardError;
    copy.showsFloatingButton = self.showsFloatingButton;
    copy.allowsReleaseBuilds = self.allowsReleaseBuilds;
    return copy;
}

@end
