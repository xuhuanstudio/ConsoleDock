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
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];

if (result == CDKStartResultStarted || result == CDKStartResultAlreadyRunning) {
    [CDKConsoleDock info:@"Login succeeded"];
    [CDKConsoleDock error:@"Request failed"];
    [CDKConsoleDock fault:@"Invariant failed"];
}
```

`CDKConsoleDockUIKit` installs the floating console when configured. The core `CDKConsoleDock` APIs remain available for reading, clearing, and writing native entries.

## Keep Existing Logger Call Sites

For older Objective-C projects, prefer adding a sink or appender to the existing logger instead of rewriting every call site. The appender can forward formatted messages to `CDKConsoleDock` while the original logger keeps its current outputs.

ConsoleDock cannot fully capture Swift `Logger`, `os_log`, or Apple unified logging from inside the app, so adapters should forward to ConsoleDock explicitly when reliable in-app visibility is required.
