#import "ConsoleDockCore.h"

static NSUInteger const CDKDefaultMaximumPartialBytes = 8192;

static void CDKAppendScalar(NSMutableString *string, uint32_t scalar)
{
    if (scalar <= 0xFFFF) {
        unichar character = (unichar)scalar;
        [string appendString:[NSString stringWithCharacters:&character length:1]];
        return;
    }

    scalar -= 0x10000;
    unichar pair[2] = {
        (unichar)(0xD800 + (scalar >> 10)),
        (unichar)(0xDC00 + (scalar & 0x3FF))
    };
    [string appendString:[NSString stringWithCharacters:pair length:2]];
}

static NSString *CDKStringFromUTF8DataReplacingInvalid(NSData *data)
{
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (decoded != nil) {
        return decoded;
    }

    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;
    NSMutableString *result = [NSMutableString string];
    NSUInteger index = 0;

    while (index < length) {
        uint8_t byte = bytes[index];
        if (byte < 0x80) {
            CDKAppendScalar(result, byte);
            index += 1;
            continue;
        }

        uint32_t scalar = 0;
        NSUInteger needed = 0;
        if (byte >= 0xC2 && byte <= 0xDF) {
            scalar = byte & 0x1F;
            needed = 1;
        } else if (byte >= 0xE0 && byte <= 0xEF) {
            scalar = byte & 0x0F;
            needed = 2;
        } else if (byte >= 0xF0 && byte <= 0xF4) {
            scalar = byte & 0x07;
            needed = 3;
        } else {
            CDKAppendScalar(result, 0xFFFD);
            index += 1;
            continue;
        }

        if (index + needed >= length) {
            CDKAppendScalar(result, 0xFFFD);
            index += 1;
            continue;
        }

        BOOL valid = YES;
        for (NSUInteger offset = 1; offset <= needed; offset += 1) {
            uint8_t continuation = bytes[index + offset];
            if ((continuation & 0xC0) != 0x80) {
                valid = NO;
                break;
            }
            scalar = (scalar << 6) | (continuation & 0x3F);
        }

        if (!valid ||
            (needed == 2 && scalar < 0x800) ||
            (needed == 3 && (scalar < 0x10000 || scalar > 0x10FFFF)) ||
            (scalar >= 0xD800 && scalar <= 0xDFFF)) {
            CDKAppendScalar(result, 0xFFFD);
            index += 1;
            continue;
        }

        CDKAppendScalar(result, scalar);
        index += needed + 1;
    }

    return result;
}

@interface CDKLineFramer ()

@property (nonatomic) NSMutableData *nativeBuffer;
@property (nonatomic) NSMutableData *stdoutBuffer;
@property (nonatomic) NSMutableData *stderrBuffer;

@end

@implementation CDKLineFramer

- (instancetype)init
{
    return [self initWithMaximumPartialBytes:CDKDefaultMaximumPartialBytes];
}

- (instancetype)initWithMaximumPartialBytes:(NSUInteger)maximumPartialBytes
{
    self = [super init];
    if (self) {
        _maximumPartialBytes = MAX(maximumPartialBytes, 1);
        _nativeBuffer = [NSMutableData data];
        _stdoutBuffer = [NSMutableData data];
        _stderrBuffer = [NSMutableData data];
    }
    return self;
}

- (NSArray<CDKLineEvent *> *)appendData:(NSData *)data source:(CDKLogSource)source
{
    if (data.length == 0) {
        return @[];
    }

    @synchronized(self) {
        NSMutableArray<CDKLineEvent *> *events = [NSMutableArray array];
        NSMutableData *buffer = [self bufferForSource:source];
        const uint8_t *bytes = data.bytes;
        NSUInteger segmentStart = 0;

        for (NSUInteger index = 0; index < data.length; index += 1) {
            if (bytes[index] != '\n') {
                continue;
            }

            if (index > segmentStart) {
                [buffer appendBytes:bytes + segmentStart length:index - segmentStart];
            }
            [events addObject:[self eventFromBuffer:buffer source:source isPartial:NO]];
            [buffer setLength:0];
            segmentStart = index + 1;
        }

        if (segmentStart < data.length) {
            [buffer appendBytes:bytes + segmentStart length:data.length - segmentStart];
            [events addObjectsFromArray:[self drainOversizedBuffer:buffer source:source]];
        }

        return events;
    }
}

- (NSArray<CDKLineEvent *> *)flushSource:(CDKLogSource)source
{
    @synchronized(self) {
        NSMutableData *buffer = [self bufferForSource:source];
        if (buffer.length == 0) {
            return @[];
        }

        CDKLineEvent *event = [self eventFromBuffer:buffer source:source isPartial:YES];
        [buffer setLength:0];
        return @[event];
    }
}

- (NSMutableData *)bufferForSource:(CDKLogSource)source
{
    switch (source) {
        case CDKLogSourceStdout:
            return self.stdoutBuffer;
        case CDKLogSourceStderr:
            return self.stderrBuffer;
        case CDKLogSourceNative:
        default:
            return self.nativeBuffer;
    }
}

- (NSArray<CDKLineEvent *> *)drainOversizedBuffer:(NSMutableData *)buffer source:(CDKLogSource)source
{
    NSMutableArray<CDKLineEvent *> *events = [NSMutableArray array];
    while (buffer.length > self.maximumPartialBytes) {
        NSData *prefix = [buffer subdataWithRange:NSMakeRange(0, self.maximumPartialBytes)];
        [events addObject:[[CDKLineEvent alloc] initWithSource:source
                                                       message:CDKStringFromUTF8DataReplacingInvalid(prefix)
                                                     isPartial:YES]];
        [buffer replaceBytesInRange:NSMakeRange(0, self.maximumPartialBytes) withBytes:NULL length:0];
    }
    return events;
}

- (CDKLineEvent *)eventFromBuffer:(NSData *)buffer source:(CDKLogSource)source isPartial:(BOOL)isPartial
{
    NSData *lineData = buffer;
    if (lineData.length > 0) {
        const uint8_t *bytes = lineData.bytes;
        if (bytes[lineData.length - 1] == '\r') {
            lineData = [lineData subdataWithRange:NSMakeRange(0, lineData.length - 1)];
        }
    }

    return [[CDKLineEvent alloc] initWithSource:source
                                       message:CDKStringFromUTF8DataReplacingInvalid(lineData)
                                     isPartial:isPartial];
}

@end
