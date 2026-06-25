#import "ConsoleDockCore.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

@implementation CDKSessionMetadata

- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                                startedAt:(NSDate *)startedAt
                              generatedAt:(NSDate *)generatedAt
                         bundleIdentifier:(NSString *)bundleIdentifier
                               appVersion:(NSString *)appVersion
                                 appBuild:(NSString *)appBuild
                              processName:(NSString *)processName
                   operatingSystemVersion:(NSString *)operatingSystemVersion
                              deviceModel:(NSString *)deviceModel
                         localeIdentifier:(NSString *)localeIdentifier
                       timeZoneIdentifier:(NSString *)timeZoneIdentifier
{
    self = [super init];
    if (self) {
        _sessionIdentifier = [sessionIdentifier copy];
        _startedAt = [startedAt copy];
        _generatedAt = [generatedAt copy];
        _bundleIdentifier = [bundleIdentifier copy];
        _appVersion = [appVersion copy];
        _appBuild = [appBuild copy];
        _processName = [processName copy];
        _operatingSystemVersion = [operatingSystemVersion copy];
        _deviceModel = [deviceModel copy];
        _localeIdentifier = [localeIdentifier copy];
        _timeZoneIdentifier = [timeZoneIdentifier copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
