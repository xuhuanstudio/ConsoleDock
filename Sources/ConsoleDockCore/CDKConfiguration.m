#import "ConsoleDockCore.h"

@implementation CDKConfiguration

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maximumEntries = 2000;
        _maximumMessageLength = 8192;
        _captureStandardOutput = YES;
        _captureStandardError = YES;
        _showsFloatingButton = YES;
        _floatingButtonPosition = CDKFloatingButtonPositionBottomTrailing;
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
    copy.maximumMessageLength = self.maximumMessageLength;
    copy.captureStandardOutput = self.captureStandardOutput;
    copy.captureStandardError = self.captureStandardError;
    copy.showsFloatingButton = self.showsFloatingButton;
    copy.floatingButtonPosition = self.floatingButtonPosition;
    copy.allowsReleaseBuilds = self.allowsReleaseBuilds;
    copy.redactionBlock = self.redactionBlock;
    return copy;
}

@end
