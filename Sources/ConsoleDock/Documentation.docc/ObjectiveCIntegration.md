# Objective-C Integration

Use `ConsoleDockCore` for Objective-C-compatible capture and storage APIs, and `ConsoleDock` for the bundled UIKit console facade.

## Import The Products

Objective-C and mixed apps can import both products:

```objc
@import ConsoleDock;
@import ConsoleDockCore;
```

Use `ConsoleDockCore` directly when the app only needs capture, storage, notifications, and explicit logging APIs. Add `ConsoleDock` when the app should show the bundled UIKit floating button and console panel.

## Start With The UIKit Facade

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.floatingButtonPosition = CDKFloatingButtonPositionBottomLeading;
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];

if (result == CDKStartResultStarted || result == CDKStartResultAlreadyRunning) {
    [CDKConsoleDock info:@"Login succeeded"];
    [CDKConsoleDock error:@"Request failed"];
    [CDKConsoleDock fault:@"Invariant failed"];
}
```

`CDKConsoleDockUIKit` installs the floating console when configured. The core `CDKConsoleDock` APIs remain available for reading, clearing, and writing native entries.

Use the UIKit facade to hide or show the bundled trigger at runtime without stopping ConsoleDock:

```objc
[CDKConsoleDockUIKit hideFloatingButton];
[CDKConsoleDockUIKit showFloatingButton];
```

## Keep Existing Logger Call Sites

For older Objective-C projects, prefer adding a sink or appender to the existing logger instead of rewriting every call site. The appender can forward formatted messages through `CDKLogForwarder` while the original logger keeps its current outputs.

```objc
static CDKLogForwarder *AppLogConsoleDockForwarder(void)
{
    static CDKLogForwarder *forwarder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        forwarder = [[CDKLogForwarder alloc] initWithCategory:@"AppLog"
                                                 minimumLevel:CDKLogLevelInfo];
    });
    return forwarder;
}

void AppLogInfo(NSString *message) {
    NSLog(@"%@", message);
    [AppLogConsoleDockForwarder() info:message];
}
```

ConsoleDock cannot fully capture Swift `Logger`, `os_log`, or Apple unified logging from inside the app, so adapters should forward to ConsoleDock explicitly when reliable in-app visibility is required.

See <doc:ExistingLoggerMigration> for a macro-based forwarding example.

## Mark A Test Session

Objective-C apps can add local reproduction markers through `CDKConsoleDock`:

```objc
[CDKConsoleDock mark:@"Opened checkout"];

CDKSessionMetadata *metadata = [CDKConsoleDock sessionMetadata];
NSLog(@"ConsoleDock session: %@", metadata.sessionIdentifier);
```

Markers are native info entries with a stable `[marker]` prefix. The bundled UIKit console can also create markers, share a local issue report, or copy the report text with session metadata, diagnostics, markers, and currently retained redacted logs.

```objc
NSString *report = [CDKConsoleDockUIKit issueReportText];
```
