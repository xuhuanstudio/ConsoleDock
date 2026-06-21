#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CDKLogLevel) {
    CDKLogLevelDebug = 0,
    CDKLogLevelInfo,
    CDKLogLevelWarning,
    CDKLogLevelError,
    CDKLogLevelFault
};

typedef NS_ENUM(NSInteger, CDKLogSource) {
    CDKLogSourceNative = 0,
    CDKLogSourceStdout,
    CDKLogSourceStderr
};

typedef NS_ENUM(NSInteger, CDKStartResult) {
    CDKStartResultStarted = 0,
    CDKStartResultAlreadyRunning,
    CDKStartResultDisabled,
    CDKStartResultFailed
};

typedef NSString * _Nonnull (^CDKRedactionBlock)(NSString *message);

FOUNDATION_EXPORT NSErrorDomain const CDKConsoleDockErrorDomain;

@interface CDKConfiguration : NSObject <NSCopying>

@property (nonatomic) NSUInteger maximumEntries;
@property (nonatomic) NSUInteger maximumMessageLength;
@property (nonatomic) BOOL captureStandardOutput;
@property (nonatomic) BOOL captureStandardError;
@property (nonatomic) BOOL showsFloatingButton;
@property (nonatomic) BOOL allowsReleaseBuilds;
@property (nonatomic, copy, nullable) CDKRedactionBlock redactionBlock;

+ (instancetype)defaultConfiguration;

@end

@interface CDKLogEntry : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSDate *timestamp;
@property (nonatomic, readonly) CDKLogLevel level;
@property (nonatomic, readonly) CDKLogSource source;
@property (nonatomic, copy, readonly) NSString *message;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithTimestamp:(NSDate *)timestamp
                            level:(CDKLogLevel)level
                           source:(CDKLogSource)source
                          message:(NSString *)message NS_DESIGNATED_INITIALIZER;

@end

@interface CDKConsoleDock : NSObject

+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration;
+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration
                                   error:(NSError * _Nullable * _Nullable)error;
+ (void)stop;
+ (BOOL)isRunning;

+ (NSArray<CDKLogEntry *> *)entries;
+ (void)clearEntries;

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
+ (void)debug:(NSString *)message;
+ (void)info:(NSString *)message;
+ (void)warning:(NSString *)message;
+ (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
