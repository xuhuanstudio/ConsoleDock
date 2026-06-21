# ConsoleDock

In-app debug console for iOS testing.

ConsoleDock is a planned iOS debug SDK that lets testers inspect app logs directly on device without connecting Xcode. The project is designed for real iOS app integration: existing Objective-C apps should get useful baseline coverage, while Swift and mixed projects can opt into a more reliable explicit logging API.

## Status

ConsoleDock is currently in the core in-memory store phase. The repository contains a Swift Package manifest, `ConsoleDockCore` and `ConsoleDock` targets, Native API storage, bounded in-memory entries, basic redaction, and focused tests.

Current limitations:

- stdout/stderr capture is not implemented yet.
- `dup2`, pipe readers, and line framing are not implemented yet.
- The UIKit floating button and console panel are not implemented yet.
- Third-party adapters, CocoaPods, and XCFramework distribution are not implemented yet.
- Redaction is a local in-memory baseline, not a complete privacy guarantee.

## Core Boundary

ConsoleDock must not be described as a full replacement for Xcode Console or Apple unified logging.

Planned zero-intrusion capture can cover:

- stdout
- stderr
- Swift `print`
- C `printf` / `fprintf`
- many `NSLog` outputs when they are written through process stderr

ConsoleDock cannot promise complete, reliable, live, zero-intrusion capture of:

- Swift `Logger`
- `os_log`
- Apple unified logging entries
- logs from other apps or system processes
- debugger-only output, breakpoints, LLDB expressions, or sanitizer diagnostics

Reliable complete logging should go through ConsoleDock's explicit API or an adapter for an existing logging framework.

## Package Skeleton

Current package products:

- `ConsoleDock`: Swift facade stub for app-facing API.
- `ConsoleDockCore`: Objective-C/C-compatible core stub with `CDK`-prefixed symbols.

The package includes macOS as a development/test platform so `swift build` and `swift test` can run on local development machines and CI. ConsoleDock's product goal remains an iOS debug SDK.

Local validation:

```sh
swift package dump-package
swift build
swift test
```

## Intended Distribution

Primary distribution:

- Swift Package Manager

Secondary distribution after the SPM package is stable:

- CocoaPods for older Objective-C or mixed projects
- XCFramework for manual or closed-source distribution

## Planned Capability Tiers

### Base Mode

Planned one-line startup integration for stdout/stderr capture:

```swift
import ConsoleDock

ConsoleDock.start()
```

In the current skeleton stage, `start()` only updates stub lifecycle state. It does not install stdout/stderr capture.

### Adapter Mode

Integrate with existing logging systems by adding a sink/appender/logger target.

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

Current Native Mode stores entries in a bounded local memory store only after ConsoleDock has started:

```swift
ConsoleDock.start()
ConsoleDock.info("Login succeeded")

let entries = ConsoleDock.entries
ConsoleDock.clear()
```

The future implementation may write to both ConsoleDock's internal store and Apple unified logging where appropriate, but ConsoleDock's on-device panel must read from its own store. ConsoleDock does not write files, upload logs, or read unified logging entries in the current implementation.

### Objective-C Core

```objc
#import <ConsoleDockCore/ConsoleDockCore.h>

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDock startWithConfiguration:configuration];
[CDKConsoleDock info:@"Login succeeded"];
NSArray<CDKLogEntry *> *entries = [CDKConsoleDock entries];
[CDKConsoleDock clearEntries];
[CDKConsoleDock stop];
```

## Design Documents

- [Product brief](docs/product-brief.md)
- [MVP architecture](docs/specs/2026-06-22-mvp-architecture.md)
- [Open-source readiness](docs/open-source-readiness.md)
- [Roadmap](docs/roadmap.md)

## Workspace Layout

- `docs/`: project design notes, specifications, and release planning.
- `work/`: temporary research, scripts, and experiments.
- `outputs/`: user-facing deliverables.

## Project Principles

- Be honest about iOS logging boundaries.
- Keep the default runtime behavior safe for debug builds.
- Do not enable release-build debug UI by default.
- Treat privacy redaction as a core data path, not a later add-on.
- Prefer standards-based packaging, versioning, documentation, and CI.
