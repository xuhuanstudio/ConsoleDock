# ConsoleDock

In-app debug console for iOS testing.

[简体中文概览](README.zh-CN.md)

[![CI](https://github.com/xuhuanstudio/ConsoleDock/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/xuhuanstudio/ConsoleDock/actions/workflows/ci.yml)
[![Release Validation](https://github.com/xuhuanstudio/ConsoleDock/actions/workflows/release-validation.yml/badge.svg)](https://github.com/xuhuanstudio/ConsoleDock/actions/workflows/release-validation.yml)
[![Release](https://img.shields.io/github/v/release/xuhuanstudio/ConsoleDock?sort=semver)](https://github.com/xuhuanstudio/ConsoleDock/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ConsoleDock is an early-stage iOS debug SDK that lets testers inspect app logs directly on device without connecting Xcode. The project is designed for real iOS app integration: existing Objective-C apps should get useful baseline coverage, while Swift and mixed projects can opt into a more reliable explicit logging API.

<img src="docs/assets/swift-sample-console.png" alt="ConsoleDock iOS sample console showing native, stdout, stderr, NSLog, and redacted token entries" width="320">

## Status

ConsoleDock `v0.1.0` is published as a source-first Swift Package Manager preview release. The current `main` branch contains a Swift Package manifest, `ConsoleDockCore` and `ConsoleDock` targets, Native API storage, bounded in-memory entries with stable session identifiers and partial/redacted/truncated flags, basic redaction, byte-to-line framing utilities, stdout/stderr file-descriptor capture with pass-through and restore, runtime diagnostics, entry change notification, Release startup safety gates, a UIKit-only floating button/panel foundation, Swift and Objective-C sample apps, DocC documentation, release validation workflow, and focused tests.

Current `main` limitations:

- stdout/stderr capture exists in the core and is connected to line framing and in-memory storage.
- Direct descriptor writes and flushed C stdio output can be captured; unflushed `printf` / `fprintf` output depends on standard stream buffering.
- File-descriptor capture can include framework or runtime warnings written through the app process descriptors, not only application-authored messages.
- Runtime diagnostics report current ConsoleDock state and bounded in-memory store counts; they are not evidence of complete Swift `Logger`, `os_log`, or Apple unified logging capture.
- Entry change notification exists as the refresh foundation for UI; notification handlers should fetch a snapshot through `entries`.
- The UIKit floating button and console panel foundation can show, search, source-filter, level-filter, pause/resume live follow, live refresh, selected-entry copy, clear, share/export with diagnostics, and close the current in-memory snapshot.
- Persistence and advanced query syntax are not implemented yet.
- Third-party adapters, CocoaPods, and XCFramework distribution are not implemented yet.
- Redaction is a local in-memory baseline, not a complete privacy guarantee.

## Core Boundary

ConsoleDock must not be described as a full replacement for Xcode Console or Apple unified logging.

ConsoleDock's stdout/stderr capture can cover:

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

## Quick Start

### Add The Package

ConsoleDock is SPM-first.

Add the public repository URL through Xcode's package dependency UI:

```text
https://github.com/xuhuanstudio/ConsoleDock.git
```

Use the `v0.1.0` tag for the first public preview. Then depend on:

- `ConsoleDock` for Swift API plus the bundled UIKit console.
- `ConsoleDockCore` for Objective-C/C-compatible core APIs.

The repository includes Swift Package Index metadata for hosted DocC documentation. The PackageList entry was merged in [SwiftPackageIndex/PackageList#14098](https://github.com/SwiftPackageIndex/PackageList/pull/14098); the hosted package and DocC pages may appear after Swift Package Index finishes indexing the release.

### Start In Swift

```swift
import ConsoleDock

ConsoleDock.start()

ConsoleDock.info("Login succeeded")
print("Visible through stdout capture")
```

`ConsoleDock.start()` enables stdout/stderr capture by default in Debug builds, installs the floating `CD` button, redacts obvious secrets, truncates long messages, and stores entries in local memory.

### Check Runtime Diagnostics

Runtime diagnostics are available on `main` after `v0.1.0` and will be included in the next release tag.

Use diagnostics to confirm the active configuration and current bounded in-memory store counts during integration:

```swift
let diagnostics = ConsoleDock.diagnostics
print("ConsoleDock running: \(diagnostics.isRunning)")
print("Stored entries: \(diagnostics.entryCount)")
```

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
NSLog(@"ConsoleDock running: %@", diagnostics.isRunning ? @"YES" : @"NO");
NSLog(@"Stored entries: %lu", (unsigned long)diagnostics.entryCount);
```

Diagnostics are local state only. They do not imply that Swift `Logger`, `os_log`, Apple unified logging, other-process logs, or debugger-only output are captured.

### Start In Objective-C

```objc
@import ConsoleDock;
@import ConsoleDockCore;

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];

[CDKConsoleDock info:@"Login succeeded"];
```

Use `ConsoleDockCore` directly when an Objective-C app only needs capture, storage, notifications, and explicit logging APIs. Use `ConsoleDock` as well when the app should show the bundled UIKit floating button and console panel.

### Release Safety

Release builds return `disabled` from `start` by default. Starting ConsoleDock in a Release build requires both:

- compiling with `CONSOLEDOCK_ENABLE_RELEASE`;
- setting `allowsReleaseBuilds` to `true`.

Keep ConsoleDock disabled in App Store production builds. See [Release build safety](docs/release-build-safety.md).

## Package Products

Current package products:

- `ConsoleDock`: Swift facade for app-facing API plus an Objective-C-callable UIKit facade.
- `ConsoleDockCore`: Objective-C/C-compatible core with `CDK`-prefixed symbols.

The package includes macOS as a development/test platform so `swift build` and `swift test` can run on local development machines and CI. ConsoleDock's product goal remains an iOS debug SDK.

Local validation:

```sh
scripts/validate-release.sh
```

Local DocC validation:

```sh
scripts/validate-docc.sh
```

GitHub Actions runs the shared release validation script for pull requests, pushes to `main`, and `v*` tag validation. The script validates the working tree is clean, then validates the SwiftPM manifest, package identity, Swift Package Index metadata, Objective-C API surface, UI accessibility identifiers, Swift formatting, SwiftPM build/test, Release safety gates, documentation links, governance metadata, release content audit, DocC documentation, the package iOS Simulator build, both sample app builds, source archive creation, source archive contents, and source archive build/test before a GitHub Release is published. Set `CONSOLEDOCK_RUN_UI_SMOKE=1` to include the opt-in Swift sample simulator UI smoke test.

## Examples And Walkthrough

The repository includes minimal UIKit sample apps:

- [SwiftSampleApp](Examples/SwiftSampleApp/README.md): Swift UIKit app that imports the local package, starts ConsoleDock at launch, shows the floating console button, and generates Native API info/error/fault, Swift `print`, C `printf`, C `fprintf(stderr)`, and `NSLog` messages.
- [ObjCSampleApp](Examples/ObjCSampleApp/README.md): Objective-C UIKit app that imports the local package, starts ConsoleDock through `CDKConsoleDockUIKit`, shows the floating console button, and generates Native API info/error/fault, C stdio, direct descriptor writes, and `NSLog` messages.

For a guided manual check, see [Sample app walkthrough](docs/sample-app-walkthrough.md).

Build the Swift sample from the package root:

```sh
xcodebuild -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj \
  -scheme SwiftSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Build the Objective-C sample from the package root:

```sh
xcodebuild -project Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj \
  -scheme ObjCSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Intended Distribution

Primary distribution:

- Swift Package Manager

Secondary distribution after the SPM package is stable:

- CocoaPods for older Objective-C or mixed projects
- XCFramework for manual or closed-source distribution

For distribution channel boundaries, see [Distribution strategy](docs/distribution-strategy.md).

## Planned Capability Tiers

### Base Mode

One-line startup integration for stdout/stderr capture:

```swift
import ConsoleDock

ConsoleDock.start()
```

In the current implementation, `start()` initializes the local store and installs stdout/stderr capture according to configuration. Captured bytes are passed through to the original descriptors where possible, normalized through the line framer, redacted, truncated, and stored in memory.

```swift
ConsoleDock.start(
    configuration: .init(
        captureStandardOutput: true,
        captureStandardError: true
    )
)

print("Visible through stdout capture")
ConsoleDock.stop()
```

### Adapter Mode

Integrate with existing logging systems by adding a sink/appender/logger target.

Examples:

- CocoaLumberjack
- SwiftyBeaver
- XCGLogger
- app-specific custom loggers

For practical migration patterns, see [Migrating existing loggers](docs/migration-existing-loggers.md).

### Native Mode

Use ConsoleDock's explicit API for the most reliable logs:

```swift
ConsoleDock.info("Login succeeded")
ConsoleDock.fault("Invariant failed")
```

Current Native Mode stores entries in a bounded local memory store only after ConsoleDock has started:

```swift
ConsoleDock.start()
ConsoleDock.info("Login succeeded")

let entries = ConsoleDock.entries
let diagnostics = ConsoleDock.diagnostics
ConsoleDock.clear()
```

Future UI or custom debug surfaces can observe `ConsoleDock.entriesDidChangeNotification` and then read `ConsoleDock.entries`. Observe `ConsoleDock.diagnosticsDidChangeNotification` when the surface also needs to refresh running state, capture configuration, or store counts after start, stop, append, or clear operations. Notifications are posted on the thread that changed ConsoleDock state, so UI code should dispatch to the main queue before touching UIKit.

The future implementation may write to both ConsoleDock's internal store and Apple unified logging where appropriate, but ConsoleDock's on-device panel must read from its own store. ConsoleDock does not write files, upload logs, or read unified logging entries in the current implementation.

### Objective-C Core and UIKit

```objc
@import ConsoleDock;
@import ConsoleDockCore;

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];
[CDKConsoleDock info:@"Login succeeded"];
[CDKConsoleDock fault:@"Invariant failed"];
NSArray<CDKLogEntry *> *entries = [CDKConsoleDock entries];
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
[CDKConsoleDock clearEntries];
[CDKConsoleDockUIKit showConsole];
[CDKConsoleDockUIKit stop];
```

Use `ConsoleDockCore` directly when an Objective-C app only needs capture, storage, and explicit logging APIs. Use `ConsoleDock` as well when the app should show the bundled UIKit floating button and console panel.

## Design Documents

- [Product brief](docs/product-brief.md)
- [DocC catalog](Sources/ConsoleDock/Documentation.docc/ConsoleDock.md)
- [GitHub repository setup](docs/github-repository-setup.md)
- [Integration diagnostics specification](docs/specs/2026-06-22-v0.2-integration-diagnostics.md)
- [Migrating existing loggers](docs/migration-existing-loggers.md)
- [MVP architecture](docs/specs/2026-06-22-mvp-architecture.md)
- [Open-source readiness](docs/open-source-readiness.md)
- [Privacy and redaction](docs/privacy-and-redaction.md)
- [Release process](docs/release-process.md)
- [Release build safety](docs/release-build-safety.md)
- [Sample app walkthrough](docs/sample-app-walkthrough.md)
- [Roadmap](docs/roadmap.md)

## Repository Layout

- `Sources/`: package targets for the Objective-C-compatible core and Swift facade.
- `Tests/`: focused package tests for lifecycle, capture, redaction, filtering, export formatting, and Release safety.
- `Examples/`: Swift and Objective-C sample apps that exercise package integration and runtime behavior.
- `docs/`: architecture notes, release planning, migration guidance, and sample walkthroughs.
- `scripts/`: local validation helpers used by CI and release checks.
- `.github/`: issue templates, pull request template, CI, and release validation workflow.

## Project Principles

- Be honest about iOS logging boundaries.
- Keep the default runtime behavior safe for debug builds.
- Do not enable release-build debug UI by default; Release startup requires both a compile-time flag and runtime opt-in.
- Treat privacy redaction as a core data path, not a later add-on.
- Prefer standards-based packaging, versioning, documentation, and CI.
