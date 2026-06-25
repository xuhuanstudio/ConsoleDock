# ConsoleDock Product Brief

## Optimized Goal

Build a reusable iOS debug SDK that testers can integrate into an app to view runtime logs directly on device, reducing the need to connect Xcode for basic log inspection.

## Recommended Product Shape

ConsoleDock should be distributed as an SDK/library, not as a copy-pasted source folder.

Distribution policy:

1. Swift Package Manager as the canonical public release channel.
2. Swift Package Index and hosted DocC as discovery and documentation surfaces.
3. CocoaPods and XCFramework are demand-driven compatibility evaluations, not active release targets.

See [Distribution strategy](distribution-strategy.md) for the current channel policy. ConsoleDock should not claim CocoaPods or XCFramework support until those paths are implemented, validated, and documented.

## Capability Tiers

### Base Mode

One-line startup integration:

```swift
import ConsoleDock

ConsoleDock.start()
```

Expected capture:

- Swift `print`
- C `printf`
- writes to stdout/stderr
- many `NSLog` outputs

### Adapter Mode

Integrate with existing logger systems by adding a sink/appender/logger target.

Examples:

- CocoaLumberjack
- SwiftyBeaver
- XCGLogger
- app-specific custom loggers

### Native Mode

Use ConsoleDock's explicit API for the most reliable logs:

```swift
ConsoleDock.info("Login succeeded")
```

ConsoleDock's in-app console reads from ConsoleDock's internal in-memory store. The current implementation does not write to Apple unified logging or read Apple unified logging back from inside the app. If an app also needs Apple unified logging output, that output should remain in the app's existing logger while the same already-formatted message is forwarded to ConsoleDock.

### Debug Actions Mode

Expose app-owned local test shortcuts inside the ConsoleDock panel:

```swift
ConsoleDock.registerAction(id: "open.checkout", title: "Open Checkout") {
    AppRouter.shared.openCheckout()
}
```

ConsoleDock only displays and triggers actions that the app registers. It should not discover routes, control app navigation automatically, bypass business permissions, or accept remote commands.

## Non-Goals

- Do not try to replace Xcode debugger features.
- Do not promise complete capture of Apple unified logging.
- Do not read or expose logs from other processes.
- Do not encourage enabling debug tooling in production builds without safeguards.
- Do not turn Debug Actions into a remote command system or automatic route discovery layer.

## Naming Decision

Chosen name: `ConsoleDock`

Reasoning:

- Modern and platform-neutral without implying Android support directly.
- Avoids Apple/iOS/Xcode trademark-heavy naming.
- Avoids confusion with the existing `iConsole` project.
- Works as a package name and product brand.
