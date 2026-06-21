# ConsoleDock

In-app debug console for iOS testing.

ConsoleDock is a planned iOS debug SDK that lets testers inspect app logs directly on device without connecting Xcode. The project is designed for real iOS app integration: existing Objective-C apps should get useful baseline coverage, while Swift and mixed projects can opt into a more reliable explicit logging API.

## Status

ConsoleDock is currently in the architecture and project-specification phase. The repository does not yet contain SDK source code, a Swift package manifest, or a sample app.

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

## Intended Distribution

Primary distribution:

- Swift Package Manager

Secondary distribution after the SPM package is stable:

- CocoaPods for older Objective-C or mixed projects
- XCFramework for manual or closed-source distribution

## Planned Capability Tiers

### Base Mode

One-line startup integration for stdout/stderr capture:

```swift
import ConsoleDock

ConsoleDock.start()
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

The implementation can write to both ConsoleDock's internal store and Apple unified logging where appropriate, but ConsoleDock's on-device panel must read from its own store.

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

