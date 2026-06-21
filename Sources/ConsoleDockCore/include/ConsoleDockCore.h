#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CDKLogLevel) {
    CDKLogLevelDebug = 0,
    CDKLogLevelInfo,
    CDKLogLevelWarning,
    CDKLogLevelError,
    CDKLogLevelFault
};

typedef NS_ENUM(NSInteger, CDKStartResult) {
    CDKStartResultStarted = 0,
    CDKStartResultAlreadyRunning,
    CDKStartResultDisabled,
    CDKStartResultFailed
};

FOUNDATION_EXPORT NSErrorDomain const CDKConsoleDockErrorDomain;

@interface CDKConfiguration : NSObject <NSCopying>

@property (nonatomic) NSUInteger maximumEntries;
@property (nonatomic) BOOL captureStandardOutput;
@property (nonatomic) BOOL captureStandardError;
@property (nonatomic) BOOL showsFloatingButton;
@property (nonatomic) BOOL allowsReleaseBuilds;

+ (instancetype)defaultConfiguration;

@end

@interface CDKConsoleDock : NSObject

+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration;
+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration
                                   error:(NSError * _Nullable * _Nullable)error;
+ (void)stop;
+ (BOOL)isRunning;

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
+ (void)debug:(NSString *)message;
+ (void)info:(NSString *)message;
+ (void)warning:(NSString *)message;
+ (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
