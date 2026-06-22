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

/// Maximum number of entries retained in memory before oldest entries are evicted. Must be greater than zero.
@property (nonatomic) NSUInteger maximumEntries;
/// Maximum stored message length after redaction. Must be greater than zero.
@property (nonatomic) NSUInteger maximumMessageLength;
/// Captures stdout writes from the app process when enabled.
@property (nonatomic) BOOL captureStandardOutput;
/// Captures stderr writes from the app process when enabled.
@property (nonatomic) BOOL captureStandardError;
/// Installs the bundled UIKit floating button when used through the UIKit facade.
@property (nonatomic) BOOL showsFloatingButton;

/// Allows ConsoleDock to start in Release builds only when the app also defines CONSOLEDOCK_ENABLE_RELEASE.
@property (nonatomic) BOOL allowsReleaseBuilds;
/// Optional app-specific redaction hook. The default redactor runs before this block.
@property (nonatomic, copy, nullable) CDKRedactionBlock redactionBlock;

/// Returns the debug-safe default configuration.
+ (instancetype)defaultConfiguration;

@end

@interface CDKLogEntry : NSObject <NSCopying>

/// The time this entry was stored.
@property (nonatomic, copy, readonly) NSDate *timestamp;
/// The severity associated with this entry.
@property (nonatomic, readonly) CDKLogLevel level;
/// The source path that produced this entry.
@property (nonatomic, readonly) CDKLogSource source;
/// The redacted, truncated message stored by ConsoleDock.
@property (nonatomic, copy, readonly) NSString *message;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithTimestamp:(NSDate *)timestamp
                            level:(CDKLogLevel)level
                           source:(CDKLogSource)source
                          message:(NSString *)message NS_DESIGNATED_INITIALIZER;

@end

@interface CDKLineEvent : NSObject <NSCopying>

/// The descriptor source that produced this framed line.
@property (nonatomic, readonly) CDKLogSource source;
/// The UTF-8-normalized message for this line.
@property (nonatomic, copy, readonly) NSString *message;
/// Whether this event was flushed from an incomplete line.
@property (nonatomic, readonly, getter=isPartial) BOOL partial;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithSource:(CDKLogSource)source
                       message:(NSString *)message
                     isPartial:(BOOL)isPartial NS_DESIGNATED_INITIALIZER;

@end

@interface CDKLineFramer : NSObject

/// Maximum buffered bytes allowed for an incomplete line before it is emitted.
@property (nonatomic, readonly) NSUInteger maximumPartialBytes;

- (instancetype)init;
- (instancetype)initWithMaximumPartialBytes:(NSUInteger)maximumPartialBytes NS_DESIGNATED_INITIALIZER;
/// Appends bytes for one source and returns any complete line events.
- (NSArray<CDKLineEvent *> *)appendData:(NSData *)data source:(CDKLogSource)source;
/// Emits and clears any incomplete buffered line for one source.
- (NSArray<CDKLineEvent *> *)flushSource:(CDKLogSource)source;

@end

@interface CDKConsoleDock : NSObject

/// Starts ConsoleDock with the supplied configuration, or the default configuration when nil.
+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration;
/// Starts ConsoleDock and optionally returns a configuration or capture error.
+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration
                                   error:(NSError * _Nullable * _Nullable)error;
/// Stops capture and restores redirected descriptors.
+ (void)stop;
/// Whether ConsoleDock is currently running.
+ (BOOL)isRunning;

/// Returns a snapshot of current in-memory entries.
+ (NSArray<CDKLogEntry *> *)entries;
/// Clears the in-memory store.
+ (void)clearEntries;
/// Appends a framed stdout/stderr event through the normal redaction and storage path.
+ (void)appendLineEvent:(CDKLineEvent *)event;

/// Appends a native entry at a specific level.
+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
/// Appends a native debug entry.
+ (void)debug:(NSString *)message;
/// Appends a native info entry.
+ (void)info:(NSString *)message;
/// Appends a native warning entry.
+ (void)warning:(NSString *)message;
/// Appends a native error entry.
+ (void)error:(NSString *)message;
/// Appends a native fault entry.
+ (void)fault:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
