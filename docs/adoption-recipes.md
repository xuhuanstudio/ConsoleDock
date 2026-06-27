# Adoption Recipes

Use this guide when adding ConsoleDock to an existing app for the first time. It focuses on the practical paths most teams need after installing the Swift package.

ConsoleDock remains local-only and debug/test-first:

- use Swift Package Manager as the supported public distribution channel;
- keep Release builds disabled unless the app has an explicit internal-test policy;
- forward existing app logs explicitly when those logs must reliably appear in the panel;
- generate reports only from user-initiated or app-owned feedback flows;
- do not treat ConsoleDock as analytics, telemetry, a network inspector, crash reporting, or remote command infrastructure.

## Choose A Recipe

| App shape | Recommended path |
| --- | --- |
| New Swift app or mixed app that wants the bundled panel | Depend on `ConsoleDock`, call `ConsoleDock.start()` in a debug/test startup path, then add explicit logs and Debug Actions where useful. |
| Existing Swift app with a central logger | Depend on `ConsoleDock`, start it once, and add `ConsoleDock.LogForwarder` inside the existing logger sink/wrapper. |
| Older Objective-C app that wants the bundled panel | Depend on both `ConsoleDock` and `ConsoleDockCore`, import both modules, and start through `CDKConsoleDockUIKit`. |
| Objective-C or C-heavy app that only wants storage/capture APIs | Depend on `ConsoleDockCore` and use `CDKConsoleDock`, `CDKLogForwarder`, and notifications directly. |
| App-owned feedback or support flow | Use Support Reports on demand and let the host app own consent, upload, retention, and privacy review. |

## Recipe 1: Swift App With The Bundled Panel

Add the package URL in Xcode:

```text
https://github.com/xuhuanstudio/ConsoleDock.git
```

Select the `ConsoleDock` product for the app target. Start ConsoleDock once in an app startup path used by debug or internal test builds:

```swift
import ConsoleDock

#if DEBUG
ConsoleDock.start()
#endif
```

Then verify the basic path:

```swift
ConsoleDock.info("ConsoleDock integration check")
print("stdout capture check")
```

Open the floating button or call:

```swift
ConsoleDock.showConsole()
```

Expected result:

- the bundled panel opens;
- `ConsoleDock integration check` appears as a native entry;
- the `print` line appears if stdout capture is enabled;
- the `Context` tab can copy an Integration Diagnosis if expected data is missing.

## Recipe 2: Existing Swift Logger

Do not replace every old call site. Add ConsoleDock as one destination in the existing logger wrapper, sink, appender, or transport.

```swift
import ConsoleDock

enum AppLog {
    private static let consoleDock = ConsoleDock.LogForwarder(
        category: "AppLog",
        minimumLevel: .info
    )

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

Existing code keeps calling `AppLog.info(...)` and `AppLog.error(...)`. ConsoleDock receives the same app-authored messages through the native storage path.

If the wrapper also writes to Swift `Logger` or `os_log`, keep that output and explicitly forward the same safe message to ConsoleDock. Do not rely on reading Apple unified logging back from inside the app.

For deeper migration patterns, see [Migrating existing loggers](migration-existing-loggers.md).

## Recipe 3: Objective-C App With The Bundled Panel

Select both package products for the app target:

- `ConsoleDock`
- `ConsoleDockCore`

Import both modules and start through the UIKit facade:

```objc
@import ConsoleDock;
@import ConsoleDockCore;

#if DEBUG
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration
                                                             error:nil];
NSLog(@"ConsoleDock start result: %ld", (long)result);
#endif
```

Write a native entry:

```objc
[CDKConsoleDock info:@"ConsoleDock Objective-C integration check"];
[CDKConsoleDockUIKit showConsole];
```

Expected result:

- the panel opens from the UIKit facade;
- native Objective-C entries appear in Logs;
- supported stdout/stderr and many `NSLog` messages appear after validation on the target OS;
- `[CDKConsoleDockUIKit integrationDiagnosisText]` is available when expected data is missing.

## Recipe 4: Objective-C Core-Only Integration

Use `ConsoleDockCore` alone when the app does not want the bundled UIKit panel.

```objc
@import ConsoleDockCore;

#if DEBUG
[CDKConsoleDock startWithConfiguration:nil];
#endif

[CDKConsoleDock info:@"Core-only integration check"];
NSArray<CDKLogEntry *> *entries = [CDKConsoleDock entries];
```

Add a forwarder inside the existing Objective-C logger function or macro:

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

void AppLogInfo(NSString *message)
{
    NSLog(@"%@", message);
    [AppLogConsoleDockForwarder() info:message];
}
```

This keeps the old logger as the source of truth while adding ConsoleDock as an in-app debug destination.

## Recipe 5: Local Debug Actions

Use Debug Actions for explicit test shortcuts that the app chooses to expose. ConsoleDock does not discover routes or bypass business permissions.

```swift
ConsoleDock.registerAction(
    id: "open.checkout",
    title: "Open Checkout",
    group: "Navigation",
    detail: "Open the checkout test entry"
) {
    AppRouter.shared.openCheckout()
}
```

Good action candidates:

- open a hard-to-reach debug screen;
- seed local test data;
- generate a smoke-test log set;
- copy or show non-secret local diagnostics;
- clear local debug data with confirmation.

Avoid actions that:

- run remote commands;
- bypass authentication or authorization;
- collect unnecessary personal data;
- depend on production-only state;
- become a replacement for automated tests.

## Recipe 6: App-Owned Feedback Flow

Use Support Reports when the app already has a reviewed feedback or support path and needs a bounded local report.

```swift
let report = ConsoleDock.supportReport(options: .last10Minutes)
let fileURL = try ConsoleDock.makeTemporarySupportReportFile(options: .last60Minutes)
```

ConsoleDock only generates the report locally. The host app owns:

- when the user or tester is asked to send it;
- where it is uploaded or attached;
- privacy copy and consent;
- server retention and access control;
- cleanup of file URLs the host app keeps.

Use `ConsoleDock.SupportReportOptions.last5Minutes`, `last10Minutes`, `last30Minutes`, or `last60Minutes` based on the support flow. Longer windows cannot recover entries already evicted from ConsoleDock's bounded in-memory store.

## Release And Privacy Checklist

Before sharing a build with testers:

- start ConsoleDock only from the intended debug or internal-test startup path;
- confirm Release builds return disabled unless both Release opt-in gates are intentionally enabled;
- add an app-specific redactor for identifiers not covered by the default redactor;
- verify sample tokens, cookies, and app-specific IDs appear as `<redacted>`;
- keep Debug Action parameters limited to small local test inputs;
- confirm App Context values contain no raw secrets or unnecessary personal data;
- confirm Support Report upload or attachment is app-owned and reviewed separately.

See [Privacy and redaction](privacy-and-redaction.md) and [Release build safety](release-build-safety.md) for the detailed rules.

## First Integration Validation

Run this check after the first integration:

1. Start the app in a Debug build.
2. Open the ConsoleDock panel.
3. Emit one native log through `ConsoleDock.info(...)` or `[CDKConsoleDock info:...]`.
4. Emit one existing app logger message through the app's normal logger.
5. Confirm the old logging destination still receives the message.
6. Confirm ConsoleDock Logs receives the forwarded message.
7. Register and run one harmless Debug Action.
8. Copy Integration Diagnosis from the `Context` tab if any expected data is missing.
9. Generate one issue report or Support Report and verify sensitive data is redacted.
10. Build a Release configuration and confirm ConsoleDock startup is disabled by default.

If a log does not appear, first check whether it is written through a supported stdout/stderr path, through ConsoleDock's explicit API, or through an app-owned forwarder. Swift `Logger`, `os_log`, Apple unified logging, debugger-only output, other-process logs, and sanitizer diagnostics are not complete zero-intrusion capture paths for ConsoleDock.
