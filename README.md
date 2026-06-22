# ConsoleDock

In-app debug console for iOS testing.

ConsoleDock is a planned iOS debug SDK that lets testers inspect app logs directly on device without connecting Xcode. The project is designed for real iOS app integration: existing Objective-C apps should get useful baseline coverage, while Swift and mixed projects can opt into a more reliable explicit logging API.

## Status

ConsoleDock is currently in the UIKit console foundation phase. The repository contains a Swift Package manifest, `ConsoleDockCore` and `ConsoleDock` targets, Native API storage, bounded in-memory entries, basic redaction, byte-to-line framing utilities, stdout/stderr file-descriptor capture with pass-through and restore, entry change notification, a UIKit-only floating button/panel foundation, Swift and Objective-C sample apps, and focused tests.

Current limitations:

- stdout/stderr capture exists in the core and is connected to line framing and in-memory storage.
- Direct descriptor writes and flushed C stdio output can be captured; unflushed `printf` / `fprintf` output depends on standard stream buffering.
- File-descriptor capture can include framework or runtime warnings written through the app process descriptors, not only application-authored messages.
- Entry change notification exists as the refresh foundation for UI; notification handlers should fetch a snapshot through `entries`.
- The UIKit floating button and console panel foundation can show, live refresh, clear, and close the current in-memory snapshot.
- Search, pause/resume, copy, share/export, persistence, and advanced filtering are not implemented yet.
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

## Package Skeleton

Current package products:

- `ConsoleDock`: Swift facade for app-facing API plus an Objective-C-callable UIKit facade.
- `ConsoleDockCore`: Objective-C/C-compatible core with `CDK`-prefixed symbols.

The package includes macOS as a development/test platform so `swift build` and `swift test` can run on local development machines and CI. ConsoleDock's product goal remains an iOS debug SDK.

Local validation:

```sh
swift package dump-package
swift build
swift test
xcodebuild -scheme ConsoleDock-Package -destination 'generic/platform=iOS Simulator' build
```

GitHub Actions currently validates the SwiftPM manifest, SwiftPM build/test, the package iOS Simulator build, and both sample app builds.

## Examples

The repository includes minimal UIKit sample apps:

- [SwiftSampleApp](Examples/SwiftSampleApp/README.md): Swift UIKit app that imports the local package, starts ConsoleDock at launch, shows the floating console button, and generates Native API, Swift `print`, C `printf`, C `fprintf(stderr)`, and `NSLog` messages.
- [ObjCSampleApp](Examples/ObjCSampleApp/README.md): Objective-C UIKit app that imports the local package, starts ConsoleDock through `CDKConsoleDockUIKit`, shows the floating console button, and generates Native API, C stdio, direct descriptor writes, and `NSLog` messages.

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

## Planned Capability Tiers

### Base Mode

Planned one-line startup integration for stdout/stderr capture:

```swift
import ConsoleDock

ConsoleDock.start()
```

In the current core capture stage, `start()` initializes the local store and installs stdout/stderr capture according to configuration. Captured bytes are passed through to the original descriptors where possible, normalized through the line framer, redacted, truncated, and stored in memory.

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

Future UI or custom debug surfaces can observe `ConsoleDock.entriesDidChangeNotification` and then read `ConsoleDock.entries`. Notifications are posted on the thread that changed the store, so UI code should dispatch to the main queue before touching UIKit.

The future implementation may write to both ConsoleDock's internal store and Apple unified logging where appropriate, but ConsoleDock's on-device panel must read from its own store. ConsoleDock does not write files, upload logs, or read unified logging entries in the current implementation.

### Objective-C Core and UIKit

```objc
@import ConsoleDock;
@import ConsoleDockCore;

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];
[CDKConsoleDock info:@"Login succeeded"];
NSArray<CDKLogEntry *> *entries = [CDKConsoleDock entries];
[CDKConsoleDock clearEntries];
[CDKConsoleDockUIKit showConsole];
[CDKConsoleDockUIKit stop];
```

Use `ConsoleDockCore` directly when an Objective-C app only needs capture, storage, and explicit logging APIs. Use `ConsoleDock` as well when the app should show the bundled UIKit floating button and console panel.

## Design Documents

- [Product brief](docs/product-brief.md)
- [MVP architecture](docs/specs/2026-06-22-mvp-architecture.md)
- [Open-source readiness](docs/open-source-readiness.md)
- [Roadmap](docs/roadmap.md)

## Workspace Layout

- `docs/`: project design notes, specifications, and release planning.
- `Examples/`: sample apps that exercise package integration and runtime behavior.
- `work/`: temporary research, scripts, and experiments.
- `outputs/`: user-facing deliverables.

## Project Principles

- Be honest about iOS logging boundaries.
- Keep the default runtime behavior safe for debug builds.
- Do not enable release-build debug UI by default.
- Treat privacy redaction as a core data path, not a later add-on.
- Prefer standards-based packaging, versioning, documentation, and CI.
