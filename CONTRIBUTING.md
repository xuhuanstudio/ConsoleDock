# Contributing to ConsoleDock

ConsoleDock is an in-app debug console for iOS testing. Contributions should keep the project honest about its logging boundaries and safe by default.

## Current Stage

The repository is in the UIKit console foundation stage. Current code includes `ConsoleDockCore`, the Swift facade, stdout/stderr file-descriptor capture, in-memory storage, redaction, a UIKit floating console foundation, Swift and Objective-C sample apps, and Release safety gates.

Still out of scope for the current stage:

- third-party logger adapters;
- CocoaPods and XCFramework distribution;
- persistence, remote upload, or network inspection;
- complete zero-intrusion capture of Swift `Logger`, `os_log`, or Apple unified logging.

## Local Setup

Use a recent Xcode toolchain with Swift Package Manager support.

Recommended checks before opening a pull request:

```sh
swift package dump-package
swift build
swift test
swift test -c release --filter ConsoleDockCoreTests/testReleaseBuild
swift test -c release -Xcc -DCONSOLEDOCK_ENABLE_RELEASE -Xswiftc -DCONSOLEDOCK_ENABLE_RELEASE --filter ConsoleDockCoreTests/testReleaseBuild
scripts/validate-docc.sh
xcodebuild -scheme ConsoleDock-Package -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj -scheme SwiftSampleApp -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj -scheme ObjCSampleApp -destination 'generic/platform=iOS Simulator' build
```

## Contribution Rules

- Keep Objective-C symbols prefixed with `CDK`.
- Do not claim complete zero-intrusion capture of Swift `Logger` or `os_log`.
- Do not weaken the Release-build gate. Release startup requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`.
- Do not add network upload, persistence, or export behavior without privacy review.
- Keep public APIs small and documented.
- Add tests for lifecycle, configuration, redaction, capture, UI-facing state, and Release safety when those areas change.

## Pull Requests

Pull requests should describe:

- what changed;
- why the change is needed;
- how it was tested;
- whether it affects public API, privacy, or Release-build behavior.
