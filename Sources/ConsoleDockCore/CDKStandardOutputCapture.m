#import "CDKStandardOutputCapture.h"
#import "ConsoleDockCore.h"

#import <errno.h>
#import <fcntl.h>
#import <stdio.h>
#import <unistd.h>

typedef NS_ENUM(NSInteger, CDKCaptureErrorCode) {
    CDKCaptureErrorCodeBase = 100
};

enum {
    CDKCaptureReadBufferSize = 4096
};

static NSError *CDKCaptureError(NSInteger code, NSString *message)
{
    return [NSError errorWithDomain:CDKConsoleDockErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static void CDKCloseDescriptor(int *descriptor)
{
    if (*descriptor >= 0) {
        close(*descriptor);
        *descriptor = -1;
    }
}

static BOOL CDKSetCloseOnExec(int descriptor)
{
    int flags = fcntl(descriptor, F_GETFD);
    if (flags < 0) {
        return NO;
    }
    return fcntl(descriptor, F_SETFD, flags | FD_CLOEXEC) == 0;
}

static BOOL CDKWriteAll(int descriptor, const void *bytes, size_t length)
{
    const uint8_t *cursor = bytes;
    size_t remaining = length;

    while (remaining > 0) {
        ssize_t written = write(descriptor, cursor, remaining);
        if (written < 0) {
            if (errno == EINTR) {
                continue;
            }
            return NO;
        }
        if (written == 0) {
            return NO;
        }

        cursor += written;
        remaining -= (size_t)written;
    }

    return YES;
}

@interface CDKDescriptorCapture : NSObject

- (instancetype)initWithTargetDescriptor:(int)targetDescriptor
                                  source:(CDKLogSource)source
                     maximumPartialBytes:(NSUInteger)maximumPartialBytes NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (BOOL)startWithError:(NSError **)error;
- (BOOL)isExecutingOnReaderThread;
- (void)stop;

@end

@interface CDKDescriptorCapture ()

@property (nonatomic, readonly) int targetDescriptor;
@property (nonatomic, readonly) CDKLogSource source;
@property (nonatomic, readonly) CDKLineFramer *framer;
@property (nonatomic, readonly) NSCondition *condition;
@property (nonatomic) int originalDescriptor;
@property (nonatomic) int pipeReadDescriptor;
@property (nonatomic) int pipeWriteDescriptor;
@property (nonatomic) BOOL didRedirect;
@property (nonatomic) BOOL readerFinished;
@property (nonatomic, nullable) NSThread *readerThread;

@end

@implementation CDKDescriptorCapture

- (instancetype)initWithTargetDescriptor:(int)targetDescriptor
                                  source:(CDKLogSource)source
                     maximumPartialBytes:(NSUInteger)maximumPartialBytes
{
    self = [super init];
    if (self) {
        _targetDescriptor = targetDescriptor;
        _source = source;
        _framer = [[CDKLineFramer alloc] initWithMaximumPartialBytes:maximumPartialBytes];
        _condition = [[NSCondition alloc] init];
        _originalDescriptor = -1;
        _pipeReadDescriptor = -1;
        _pipeWriteDescriptor = -1;
    }
    return self;
}

- (BOOL)startWithError:(NSError **)error
{
    self.originalDescriptor = dup(self.targetDescriptor);
    if (self.originalDescriptor < 0) {
        if (error != nil) {
            *error = CDKCaptureError(CDKCaptureErrorCodeBase + 1, @"Failed to duplicate the original standard descriptor.");
        }
        return NO;
    }
    CDKSetCloseOnExec(self.originalDescriptor);

    int pipeDescriptors[2] = {-1, -1};
    if (pipe(pipeDescriptors) != 0) {
        if (error != nil) {
            *error = CDKCaptureError(CDKCaptureErrorCodeBase + 2, @"Failed to create a capture pipe.");
        }
        [self cleanupAfterFailedStart];
        return NO;
    }

    self.pipeReadDescriptor = pipeDescriptors[0];
    self.pipeWriteDescriptor = pipeDescriptors[1];
    CDKSetCloseOnExec(self.pipeReadDescriptor);
    CDKSetCloseOnExec(self.pipeWriteDescriptor);

    if (dup2(self.pipeWriteDescriptor, self.targetDescriptor) < 0) {
        if (error != nil) {
            *error = CDKCaptureError(CDKCaptureErrorCodeBase + 3, @"Failed to redirect the standard descriptor to the capture pipe.");
        }
        [self cleanupAfterFailedStart];
        return NO;
    }

    self.didRedirect = YES;
    CDKCloseDescriptor(&_pipeWriteDescriptor);

    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(readerMain) object:nil];
    self.readerThread = thread;
    [thread start];
    return YES;
}

- (void)stop
{
    if (self.targetDescriptor == STDOUT_FILENO) {
        fflush(stdout);
    } else if (self.targetDescriptor == STDERR_FILENO) {
        fflush(stderr);
    }

    if (self.didRedirect && self.originalDescriptor >= 0) {
        dup2(self.originalDescriptor, self.targetDescriptor);
        self.didRedirect = NO;
    }

    [self waitForReaderToFinish];
    CDKCloseDescriptor(&_pipeReadDescriptor);
    CDKCloseDescriptor(&_pipeWriteDescriptor);
    CDKCloseDescriptor(&_originalDescriptor);
}

- (BOOL)isExecutingOnReaderThread
{
    return self.readerThread == NSThread.currentThread;
}

- (void)cleanupAfterFailedStart
{
    if (self.didRedirect && self.originalDescriptor >= 0) {
        dup2(self.originalDescriptor, self.targetDescriptor);
        self.didRedirect = NO;
    }
    CDKCloseDescriptor(&_pipeReadDescriptor);
    CDKCloseDescriptor(&_pipeWriteDescriptor);
    CDKCloseDescriptor(&_originalDescriptor);
}

- (void)readerMain
{
    @autoreleasepool {
        uint8_t buffer[CDKCaptureReadBufferSize];
        while (self.pipeReadDescriptor >= 0) {
            ssize_t bytesRead = read(self.pipeReadDescriptor, buffer, sizeof(buffer));
            if (bytesRead > 0) {
                CDKWriteAll(self.originalDescriptor, buffer, (size_t)bytesRead);
                NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)bytesRead];
                [self appendEvents:[self.framer appendData:data source:self.source]];
                continue;
            }
            if (bytesRead < 0 && errno == EINTR) {
                continue;
            }
            break;
        }

        [self appendEvents:[self.framer flushSource:self.source]];

        [self.condition lock];
        self.readerFinished = YES;
        [self.condition broadcast];
        [self.condition unlock];
    }
}

- (void)appendEvents:(NSArray<CDKLineEvent *> *)events
{
    for (CDKLineEvent *event in events) {
        [CDKConsoleDock appendLineEvent:event];
    }
}

- (void)waitForReaderToFinish
{
    NSThread *thread = self.readerThread;
    if (thread == nil) {
        return;
    }

    [self.condition lock];
    while (!self.readerFinished) {
        [self.condition wait];
    }
    [self.condition unlock];
    self.readerThread = nil;
}

@end

@interface CDKStandardOutputCapture ()

@property (nonatomic, readonly) CDKConfiguration *configuration;
@property (nonatomic, nullable) CDKDescriptorCapture *stdoutCapture;
@property (nonatomic, nullable) CDKDescriptorCapture *stderrCapture;

@end

@implementation CDKStandardOutputCapture

- (instancetype)initWithConfiguration:(CDKConfiguration *)configuration
{
    self = [super init];
    if (self) {
        _configuration = [configuration copy];
    }
    return self;
}

- (BOOL)startWithError:(NSError **)error
{
    if (self.configuration.captureStandardOutput) {
        self.stdoutCapture = [[CDKDescriptorCapture alloc] initWithTargetDescriptor:STDOUT_FILENO
                                                                             source:CDKLogSourceStdout
                                                                maximumPartialBytes:self.configuration.maximumMessageLength];
        if (![self.stdoutCapture startWithError:error]) {
            [self stop];
            return NO;
        }
    }

    if (self.configuration.captureStandardError) {
        self.stderrCapture = [[CDKDescriptorCapture alloc] initWithTargetDescriptor:STDERR_FILENO
                                                                             source:CDKLogSourceStderr
                                                                maximumPartialBytes:self.configuration.maximumMessageLength];
        if (![self.stderrCapture startWithError:error]) {
            [self stop];
            return NO;
        }
    }

    return YES;
}

- (void)stop
{
    [self.stdoutCapture stop];
    [self.stderrCapture stop];
    self.stdoutCapture = nil;
    self.stderrCapture = nil;
}

- (BOOL)isExecutingOnReaderThread
{
    return [self.stdoutCapture isExecutingOnReaderThread] || [self.stderrCapture isExecutingOnReaderThread];
}

@end
