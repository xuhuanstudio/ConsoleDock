# Distribution Strategy

ConsoleDock is a source-first Swift Package Manager SDK. Other distribution channels are compatibility work, not the primary release path.

## Current Channel

### Swift Package Manager

SPM is the only supported public distribution channel today.

Use the repository URL:

```text
https://github.com/xuhuanstudio/ConsoleDock.git
```

Release tags must keep the existing package products stable:

- `ConsoleDock`: Swift facade plus bundled UIKit console.
- `ConsoleDockCore`: Objective-C/C-compatible core APIs.

SPM release validation must prove package resolution, package build/test, DocC metadata, iOS Simulator package build, Swift sample app build, Objective-C sample app build, release safety gates, source archive creation, source archive audit, and source archive build/test from a temporary extraction.

Distribution validation also rejects tracked CocoaPods podspecs, Pods output, SwiftPM lock files, XCFrameworks, frameworks, Xcode archives, debug symbol bundles, static libraries, and packaged archives until those channels are intentionally implemented and validated.

## Future Channel: CocoaPods

No CocoaPods podspec is shipped yet.

CocoaPods should be treated as a legacy compatibility bridge for older Objective-C and mixed projects. It should not become ConsoleDock's primary distribution channel because the CocoaPods maintainers have announced plans for the trunk service to become read-only in the future. Keep SPM as the canonical source of public releases.

References:

- [CocoaPods trunk read-only announcement](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)
- [CocoaPods support for Swift packages](https://blog.cocoapods.org/CocoaPods-Swift-Packages/)

Before adding a podspec, confirm all of these are true:

- the SPM package has a stable tagged release used by external consumers;
- the podspec consumes source from the repository tag rather than requiring source copying;
- Objective-C public headers remain under `Sources/ConsoleDockCore/include`;
- public Objective-C symbols keep the `CDK` prefix;
- Release startup remains gated by both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`;
- no default network upload, no default disk persistence, and no private API are introduced;
- the podspec lint path is documented and can be run locally without private signing credentials;
- repository docs describe CocoaPods as a compatibility channel, not as the primary install path.

Acceptable first CocoaPods shape:

- one `ConsoleDockCore` pod for Objective-C/C-compatible capture, storage, notifications, and explicit logging APIs;
- optionally one `ConsoleDock` pod that depends on `ConsoleDockCore` and includes the Swift facade plus UIKit console;
- no third-party runtime dependencies unless there is a strong compatibility reason.

Do not add a CocoaPods release until a validation script can check the podspec and CI can run that script.

## Future Channel: XCFramework

No XCFramework artifact is shipped yet.

XCFramework distribution should come after the public API is stable enough for binary consumers. It is useful for teams that cannot or do not want to resolve source packages, but it adds artifact integrity, architecture, signing, and release-note obligations.

Before shipping an XCFramework artifact, require:

- a reproducible build script committed to the repository;
- explicit iOS device and iOS Simulator slices;
- no private signing identity requirement for validation;
- a checksum or documented integrity check for published artifacts;
- release notes that identify the source tag used to build the binary;
- validation that the binary still preserves Release startup safety, local-only behavior, and redaction-before-storage behavior.

Do not publish XCFramework binaries from an ad hoc local Xcode build.

## Release Communication Rules

Use this wording until the future channels are actually implemented:

- Supported: Swift Package Manager.
- Planned compatibility channel: CocoaPods.
- Planned binary distribution channel: XCFramework.

Avoid these claims until they are true and validated:

- "Install with CocoaPods"
- "CocoaPods supported"
- "Download the XCFramework"
- "Binary release available"

When CocoaPods or XCFramework support is added later, update this document, `README.md`, `README.zh-CN.md`, `docs/open-source-readiness.md`, `docs/roadmap.md`, release notes, and release validation scripts in the same change.
