# Contributing to ConsoleDock

ConsoleDock is an in-app debug console for iOS testing. Contributions should keep the project honest about its logging boundaries and safe by default.

## Current Stage

The repository is in package skeleton and stub API stage. The current code is intentionally minimal and does not implement stdout/stderr capture, a real UI panel, third-party adapters, CocoaPods, or XCFramework distribution.

## Local Setup

Use a recent Xcode toolchain with Swift Package Manager support.

Recommended checks before opening a pull request:

```sh
swift package dump-package
swift build
swift test
```

## Contribution Rules

- Keep Objective-C symbols prefixed with `CDK`.
- Do not claim complete zero-intrusion capture of Swift `Logger` or `os_log`.
- Do not add Release-build activation without explicit safeguards.
- Do not add network upload, persistence, or export behavior without privacy review.
- Keep public APIs small and documented.
- Add tests for lifecycle, configuration, redaction, and capture behavior as those areas are implemented.

## Pull Requests

Pull requests should describe:

- what changed;
- why the change is needed;
- how it was tested;
- whether it affects public API, privacy, or Release-build behavior.
