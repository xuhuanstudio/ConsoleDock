# ConsoleDock Product Brief

## Optimized Goal

Build a reusable iOS debug SDK that testers can integrate into an app to view runtime logs directly on device, reducing the need to connect Xcode for basic log inspection.

## Recommended Product Shape

ConsoleDock should be distributed as an SDK/library, not as a copy-pasted source folder.

Primary distribution targets:

1. Swift Package Manager
2. CocoaPods
3. XCFramework

## Capability Tiers

### Base Mode

One-line startup integration:

```objc
[ConsoleDock start];
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

The implementation can write to both ConsoleDock's internal store and Apple unified logging where appropriate.

## Non-Goals

- Do not try to replace Xcode debugger features.
- Do not promise complete capture of Apple unified logging.
- Do not read or expose logs from other processes.
- Do not encourage enabling debug tooling in production builds without safeguards.

## Naming Decision

Chosen name: `ConsoleDock`

Reasoning:

- Modern and platform-neutral without implying Android support directly.
- Avoids Apple/iOS/Xcode trademark-heavy naming.
- Avoids confusion with the existing `iConsole` project.
- Works as a package name and product brand.

