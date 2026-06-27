#import "ConsoleDockCore.h"

@implementation CDKDiagnostics

- (instancetype)initWithRunning:(BOOL)running
          captureStandardOutput:(BOOL)captureStandardOutput
           captureStandardError:(BOOL)captureStandardError
            showsFloatingButton:(BOOL)showsFloatingButton
          floatingButtonPosition:(CDKFloatingButtonPosition)floatingButtonPosition
            allowsReleaseBuilds:(BOOL)allowsReleaseBuilds
                 maximumEntries:(NSUInteger)maximumEntries
           maximumMessageLength:(NSUInteger)maximumMessageLength
                     entryCount:(NSUInteger)entryCount
             redactedEntryCount:(NSUInteger)redactedEntryCount
            truncatedEntryCount:(NSUInteger)truncatedEntryCount
              partialEntryCount:(NSUInteger)partialEntryCount
{
    self = [super init];
    if (self) {
        _running = running;
        _captureStandardOutput = captureStandardOutput;
        _captureStandardError = captureStandardError;
        _showsFloatingButton = showsFloatingButton;
        _floatingButtonPosition = floatingButtonPosition;
        _allowsReleaseBuilds = allowsReleaseBuilds;
        _maximumEntries = maximumEntries;
        _maximumMessageLength = maximumMessageLength;
        _entryCount = entryCount;
        _redactedEntryCount = redactedEntryCount;
        _truncatedEntryCount = truncatedEntryCount;
        _partialEntryCount = partialEntryCount;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
