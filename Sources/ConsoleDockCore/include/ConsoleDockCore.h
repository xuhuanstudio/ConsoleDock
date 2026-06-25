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
FOUNDATION_EXPORT NSNotificationName const CDKConsoleDockDiagnosticsDidChangeNotification;

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

/// Stable identifier assigned when the entry is stored in the current ConsoleDock session.
@property (nonatomic, readonly) unsigned long long identifier;
/// The time this entry was stored.
@property (nonatomic, copy, readonly) NSDate *timestamp;
/// The severity associated with this entry.
@property (nonatomic, readonly) CDKLogLevel level;
/// The source path that produced this entry.
@property (nonatomic, readonly) CDKLogSource source;
/// The redacted, truncated message stored by ConsoleDock.
@property (nonatomic, copy, readonly) NSString *message;
/// Whether this entry was flushed from an incomplete framed line.
@property (nonatomic, readonly, getter=isPartial) BOOL partial;
/// Whether ConsoleDock changed the message while applying default or app-specific redaction.
@property (nonatomic, readonly) BOOL redacted;
/// Whether ConsoleDock shortened the message to respect maximumMessageLength.
@property (nonatomic, readonly) BOOL truncated;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message;
- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message
                          redacted:(BOOL)redacted
                         truncated:(BOOL)truncated;
- (instancetype)initWithIdentifier:(unsigned long long)identifier
                         timestamp:(NSDate *)timestamp
                             level:(CDKLogLevel)level
                            source:(CDKLogSource)source
                           message:(NSString *)message
                          isPartial:(BOOL)isPartial
                          redacted:(BOOL)redacted
                         truncated:(BOOL)truncated NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTimestamp:(NSDate *)timestamp
                            level:(CDKLogLevel)level
                           source:(CDKLogSource)source
                          message:(NSString *)message;

@end

@interface CDKDiagnostics : NSObject <NSCopying>

/// Whether ConsoleDock is currently running and able to append new entries.
@property (nonatomic, readonly, getter=isRunning) BOOL running;
/// Whether stdout capture is enabled in the effective configuration.
@property (nonatomic, readonly) BOOL captureStandardOutput;
/// Whether stderr capture is enabled in the effective configuration.
@property (nonatomic, readonly) BOOL captureStandardError;
/// Whether the effective configuration requests the bundled UIKit floating button.
@property (nonatomic, readonly) BOOL showsFloatingButton;
/// Whether the effective runtime configuration allows Release startup when compiled with CONSOLEDOCK_ENABLE_RELEASE.
@property (nonatomic, readonly) BOOL allowsReleaseBuilds;
/// Maximum number of entries retained in memory before oldest entries are evicted.
@property (nonatomic, readonly) NSUInteger maximumEntries;
/// Maximum stored message length after redaction.
@property (nonatomic, readonly) NSUInteger maximumMessageLength;
/// Current number of entries in the bounded in-memory store.
@property (nonatomic, readonly) NSUInteger entryCount;
/// Number of currently stored entries marked redacted.
@property (nonatomic, readonly) NSUInteger redactedEntryCount;
/// Number of currently stored entries marked truncated.
@property (nonatomic, readonly) NSUInteger truncatedEntryCount;
/// Number of currently stored entries flushed from incomplete lines.
@property (nonatomic, readonly) NSUInteger partialEntryCount;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithRunning:(BOOL)running
          captureStandardOutput:(BOOL)captureStandardOutput
           captureStandardError:(BOOL)captureStandardError
            showsFloatingButton:(BOOL)showsFloatingButton
            allowsReleaseBuilds:(BOOL)allowsReleaseBuilds
                 maximumEntries:(NSUInteger)maximumEntries
           maximumMessageLength:(NSUInteger)maximumMessageLength
                     entryCount:(NSUInteger)entryCount
             redactedEntryCount:(NSUInteger)redactedEntryCount
            truncatedEntryCount:(NSUInteger)truncatedEntryCount
              partialEntryCount:(NSUInteger)partialEntryCount NS_DESIGNATED_INITIALIZER;

@end

@interface CDKSessionMetadata : NSObject <NSCopying>

/// Stable identifier for the current ConsoleDock runtime session.
@property (nonatomic, copy, readonly) NSString *sessionIdentifier;
/// Time when ConsoleDock most recently started successfully, or nil before the first successful start.
@property (nonatomic, copy, readonly, nullable) NSDate *startedAt;
/// Time when this metadata snapshot was generated.
@property (nonatomic, copy, readonly) NSDate *generatedAt;
/// Main bundle identifier, when available.
@property (nonatomic, copy, readonly, nullable) NSString *bundleIdentifier;
/// Main bundle short version string, when available.
@property (nonatomic, copy, readonly, nullable) NSString *appVersion;
/// Main bundle build version string, when available.
@property (nonatomic, copy, readonly, nullable) NSString *appBuild;
/// Current process name.
@property (nonatomic, copy, readonly) NSString *processName;
/// Operating system version string from ProcessInfo.
@property (nonatomic, copy, readonly) NSString *operatingSystemVersion;
/// Device model on UIKit platforms, otherwise unknown.
@property (nonatomic, copy, readonly) NSString *deviceModel;
/// Current locale identifier.
@property (nonatomic, copy, readonly) NSString *localeIdentifier;
/// Current time zone identifier.
@property (nonatomic, copy, readonly) NSString *timeZoneIdentifier;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
                                startedAt:(nullable NSDate *)startedAt
                              generatedAt:(NSDate *)generatedAt
                         bundleIdentifier:(nullable NSString *)bundleIdentifier
                               appVersion:(nullable NSString *)appVersion
                                 appBuild:(nullable NSString *)appBuild
                              processName:(NSString *)processName
                   operatingSystemVersion:(NSString *)operatingSystemVersion
                              deviceModel:(NSString *)deviceModel
                         localeIdentifier:(NSString *)localeIdentifier
                       timeZoneIdentifier:(NSString *)timeZoneIdentifier NS_DESIGNATED_INITIALIZER;

@end

@interface CDKLogForwarder : NSObject

/// Optional single-line category prefix added to forwarded messages.
@property (nonatomic, copy, readonly, nullable) NSString *category;
/// Lowest severity forwarded into ConsoleDock.
@property (nonatomic, readonly) CDKLogLevel minimumLevel;

- (instancetype)init;
- (instancetype)initWithCategory:(nullable NSString *)category
                    minimumLevel:(CDKLogLevel)minimumLevel NS_DESIGNATED_INITIALIZER;

/// Forwards a message to ConsoleDock when the level is at or above minimumLevel.
- (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
/// Forwards a debug message when enabled by minimumLevel.
- (void)debug:(NSString *)message;
/// Forwards an info message when enabled by minimumLevel.
- (void)info:(NSString *)message;
/// Forwards a warning message when enabled by minimumLevel.
- (void)warning:(NSString *)message;
/// Forwards an error message when enabled by minimumLevel.
- (void)error:(NSString *)message;
/// Forwards a fault message when enabled by minimumLevel.
- (void)fault:(NSString *)message;

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
/// Returns a snapshot of runtime configuration and current in-memory store counts.
+ (CDKDiagnostics *)diagnostics;
/// Returns local session and app metadata for issue reports.
+ (CDKSessionMetadata *)sessionMetadata;

/// Returns a snapshot of current in-memory entries.
+ (NSArray<CDKLogEntry *> *)entries;
/// Clears the in-memory store.
+ (void)clearEntries;
/// Appends a framed stdout/stderr event through the normal redaction and storage path.
+ (void)appendLineEvent:(CDKLineEvent *)event;

/// Appends a native entry at a specific level.
+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;
/// Appends a native marker entry for a local test session timeline.
+ (void)mark:(NSString *)message;
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
