# Migrating Existing Loggers

Use ConsoleDock without rewriting every old log call site.

ConsoleDock has three practical integration paths for existing iOS apps:

1. Start ConsoleDock and rely on supported stdout/stderr capture for baseline visibility.
2. Add one sink, appender, transport, or forwarding call inside the app's existing logger.
3. Use ConsoleDock's explicit API for new logs that must always appear in the in-app panel.

The second path is the recommended migration strategy for older projects. Keep the current logger as the source of truth, and add ConsoleDock as another destination.

## Choose The Right Path

| Existing logging path | Recommended ConsoleDock integration | Notes |
| --- | --- | --- |
| Swift `print` | Start ConsoleDock with stdout capture enabled. | Useful baseline coverage, but not structured. |
| C `printf` / `fprintf` | Start ConsoleDock with stdout/stderr capture enabled. | C stdio buffering still applies; flush when testing. |
| `NSLog` | Start ConsoleDock with stderr capture enabled, then validate on the target OS. | Many outputs are visible, but this is not a complete guarantee. |
| App-specific Swift logger | Add one ConsoleDock sink in the central logger. | Best migration path for Swift projects. |
| App-specific Objective-C logger or macro | Add one forward call in the existing macro/function. | Best migration path for older Objective-C projects. |
| CocoaLumberjack, XCGLogger, SwiftyBeaver | Add an appender/destination if the framework exposes one. | Packaged adapters are not included yet. |
| Swift `Logger` / `os_log` | Forward explicitly from your wrapper or adapter. | Do not rely on reading unified logging back from inside the app. |

## Start With Baseline Capture

For many existing apps, the first trial can be one startup call in Debug builds:

```swift
import ConsoleDock

ConsoleDock.start()
```

The default configuration captures supported stdout and stderr writes, installs the UIKit floating button, stores entries in local memory, and keeps Release builds disabled by default.

This can make Swift `print`, flushed C stdio, direct descriptor writes, and many `NSLog` messages visible. Treat it as baseline coverage, not as a complete replacement for the original logger or Xcode Console.

## Add A Swift Logger Sink

If the app already has a central Swift logger, add ConsoleDock there instead of changing every call site.

Before:

```swift
enum AppLog {
    static func info(_ message: String) {
        print("[info] \(message)")
    }

    static func error(_ message: String) {
        print("[error] \(message)")
    }
}
```

After:

```swift
import ConsoleDock

enum AppLog {
    static func info(_ message: String) {
        print("[info] \(message)")
        ConsoleDock.info(message)
    }

    static func error(_ message: String) {
        print("[error] \(message)")
        ConsoleDock.error(message)
    }
}
```

Existing call sites keep using `AppLog.info(...)` and `AppLog.error(...)`. ConsoleDock becomes one additional destination.

The Swift sample app includes an `App logger sink` button that follows this pattern: it writes through the app's logger wrapper and forwards the already-formatted message to ConsoleDock.

If the existing logger writes to Swift `Logger`, keep that output and also forward to ConsoleDock:

```swift
import ConsoleDock
import OSLog

enum AppLog {
    private static let logger = Logger(subsystem: "com.example.app", category: "app")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        ConsoleDock.info(message)
    }
}
```

Do not depend on ConsoleDock reading Swift `Logger` or `os_log` entries back from Apple unified logging. Reliable in-app visibility needs an explicit forward.

## Add An Objective-C Macro Or Function Forward

For Objective-C projects, the best migration point is usually the existing macro, function, or logger class.

```objc
@import ConsoleDockCore;

#define AppLogInfo(format, ...) do { \
    NSString *message = [NSString stringWithFormat:(format), ##__VA_ARGS__]; \
    NSLog(@"%@", message); \
    [CDKConsoleDock info:message]; \
} while (0)

#define AppLogError(format, ...) do { \
    NSString *message = [NSString stringWithFormat:(format), ##__VA_ARGS__]; \
    NSLog(@"%@", message); \
    [CDKConsoleDock error:message]; \
} while (0)
```

Existing call sites keep using `AppLogInfo(...)` and `AppLogError(...)`. The original output remains, and ConsoleDock receives the same formatted message through the native storage path.

The Objective-C sample app includes an `App logger sink` button that follows this pattern with an `NSLog`-style central forwarding function.

Use `@import ConsoleDock;` and `CDKConsoleDockUIKit` when the Objective-C app also wants the bundled floating button and panel.

## Third-Party Logging Frameworks

ConsoleDock does not currently ship packaged CocoaLumberjack, XCGLogger, or SwiftyBeaver adapters.

Until those adapters exist, use the framework's extension point if it has one:

- CocoaLumberjack: add a logger that forwards formatted messages to `CDKConsoleDock` or `ConsoleDock`.
- XCGLogger: add a destination that forwards level and message to ConsoleDock.
- SwiftyBeaver: add a destination that forwards level and message to ConsoleDock.

Keep the existing framework's file, console, or remote outputs unchanged unless the app has a separate reason to remove them.

## Privacy And Release Safety

ConsoleDock redacts before storing entries, but migration is still a good time to reduce sensitive logs at the source.

Recommended checks:

- Start ConsoleDock only in intended debug or internal testing builds.
- Keep Release builds disabled unless the app has an explicit internal distribution policy.
- Add an app-specific redactor for identifiers, tokens, tenant names, or account fields that are not covered by the default patterns.
- Forward already-formatted messages only after the existing logger has applied its own privacy rules.
- Do not forward production secrets, authentication headers, cookies, or raw request bodies.

## Validation Checklist

After adding ConsoleDock to an existing project, verify:

- the app starts and stops ConsoleDock without crashing;
- old logger call sites still compile unchanged;
- Xcode Console or the existing logger output still receives messages;
- the in-app ConsoleDock panel receives messages from the new sink/appender;
- obvious secrets are redacted before they appear in the panel, copy, or share output;
- Release builds return disabled unless both the compile-time flag and runtime opt-in are intentionally enabled.

This keeps migration low-risk: old logging behavior remains in place, while ConsoleDock adds an on-device debug view for testers.
