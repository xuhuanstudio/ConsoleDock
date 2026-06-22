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
FOUNDATION_EXPORT NSNotificationName const CDKConsoleDockEntriesDidChangeNotification;

@interface CDKConfiguration : NSObject <NSCopying>

@property (nonatomic) NSUInteger maximumEntries;
@property (nonatomic) NSUInteger maximumMessageLength;
@property (nonatomic) BOOL captureStandardOutput;
@property (nonatomic) BOOL captureStandardError;
@property (nonatomic) BOOL showsFloatingButton;

/// Allows ConsoleDock to start in Release builds only when the app also defines CONSOLEDOCK_ENABLE_RELEASE.
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

@interface CDKLineEvent : NSObject <NSCopying>

@property (nonatomic, readonly) CDKLogSource source;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, readonly, getter=isPartial) BOOL partial;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithSource:(CDKLogSource)source
                       message:(NSString *)message
                     isPartial:(BOOL)isPartial NS_DESIGNATED_INITIALIZER;

@end

@interface CDKLineFramer : NSObject

@property (nonatomic, readonly) NSUInteger maximumPartialBytes;

- (instancetype)init;
- (instancetype)initWithMaximumPartialBytes:(NSUInteger)maximumPartialBytes NS_DESIGNATED_INITIALIZER;
- (NSArray<CDKLineEvent *> *)appendData:(NSData *)data source:(CDKLogSource)source;
- (NSArray<CDKLineEvent *> *)flushSource:(CDKLogSource)source;

@end

@interface CDKConsoleDock : NSObject

+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration;
+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration
                                   error:(NSError * _Nullable * _Nullable)error;
+ (void)stop;
+ (BOOL)isRunning;

+ (NSArray<CDKLogEntry *> *)entries;
+ (void)clearEntries;
+ (void)appendLineEvent:(CDKLineEvent *)event;

+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
+ (void)debug:(NSString *)message;
+ (void)info:(NSString *)message;
+ (void)warning:(NSString *)message;
+ (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
