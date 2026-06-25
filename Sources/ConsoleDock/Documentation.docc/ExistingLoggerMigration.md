# Existing Logger Migration

Add ConsoleDock to an existing logging stack without rewriting every call site.

## Overview

The recommended migration path is to keep the app's current logger and add ConsoleDock as one more destination. In most projects, that means adding ``ConsoleDock/LogForwarder`` or `CDKLogForwarder` inside the existing logger's sink, appender, destination, transport, macro forward, or wrapper.

Baseline stdout/stderr capture is useful for first trials, but reliable in-app visibility should go through ConsoleDock's explicit API or an adapter in the app's logging stack.

## Swift Logger Wrapper

If the app already has a central Swift logger, forward from that wrapper:

```swift
import ConsoleDock

enum AppLog {
    private static let consoleDock = ConsoleDock.LogForwarder(category: "AppLog")

    static func info(_ message: String) {
        print("[info] \(message)")
        consoleDock.info(message)
    }

    static func error(_ message: String) {
        print("[error] \(message)")
        consoleDock.error(message)
    }
}
```

Existing call sites keep using `AppLog.info(...)` and `AppLog.error(...)`.

The Swift sample app includes an `App logger sink` button that demonstrates this pattern with a small app-owned wrapper.
Use ``ConsoleDock/LogForwarder/log(level:message:)`` when the existing logger already has a severity value to preserve during forwarding.

If the wrapper also writes to Swift `Logger` or `os_log`, keep that output and explicitly forward to ConsoleDock. ConsoleDock does not promise complete zero-intrusion capture of Apple unified logging.

## Objective-C Logger Wrapper

For Objective-C projects, add the forward inside the existing macro, function, or logger class:

```objc
@import ConsoleDockCore;

static CDKLogForwarder *AppLogConsoleDockForwarder(void)
{
    static CDKLogForwarder *forwarder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        forwarder = [[CDKLogForwarder alloc] initWithCategory:@"AppLog"
                                                 minimumLevel:CDKLogLevelDebug];
    });
    return forwarder;
}

#define AppLogInfo(format, ...) do { \
    NSString *message = [NSString stringWithFormat:(format), ##__VA_ARGS__]; \
    NSLog(@"%@", message); \
    [AppLogConsoleDockForwarder() info:message]; \
} while (0)
```

Use `CDKConsoleDockUIKit` from the `ConsoleDock` product when the app also wants the bundled UIKit floating button and panel.

The Objective-C sample app includes an `App logger sink` button that demonstrates this pattern with an `NSLog`-style central forwarding function and `CDKLogForwarder`.

## Integration Rules

- Keep the existing logger's outputs unless the app has a separate reason to remove them.
- Add ConsoleDock in one central place, not at every old call site.
- Treat stdout/stderr capture as useful baseline coverage, not a full logging strategy.
- Forward Swift `Logger` and `os_log` messages explicitly when they must appear in the panel.
- Keep Release builds disabled unless the app intentionally opts in through both Release gates.
- Add app-specific redaction before exposing logs to testers.
