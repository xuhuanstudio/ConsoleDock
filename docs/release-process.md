# Release Process

ConsoleDock releases are source-first Swift Package Manager releases. A public release is a git tag plus release notes; CocoaPods and XCFramework artifacts remain future distribution channels.

## Release Principles

- Ship small, verified releases.
- Keep Release builds disabled by default.
- Keep logs local and memory-first by default.
- Do not describe ConsoleDock as a full Xcode Console, Swift `Logger`, `os_log`, or Apple unified logging replacement.
- Do not move a public tag after consumers may have resolved it. Prefer a new patch release.

## Before Tagging

1. Decide the version, for example `v0.1.0`.
2. Move completed `CHANGELOG.md` entries from `Unreleased` into a heading that matches the tag, for example `## v0.1.0 - 2026-06-22`.
3. Confirm README, DocC, sample app walkthrough, release-build safety, security policy, and roadmap still describe the current shipped behavior.
4. Confirm there are no secrets, production logs, credentials, tokens, or private screenshots in docs, examples, or screenshots.
5. Confirm `git status --short` is clean before the final validation run.

## Required Local Validation

Run these from the package root:

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
swift package archive-source --output .build/ConsoleDock-source.zip
test -s .build/ConsoleDock-source.zip
```

## Manual Sample Smoke Check

Run at least one iOS Simulator smoke check before the first public release in a minor series:

1. Launch `SwiftSampleApp`.
2. Generate native, stdout, stderr, and `NSLog` entries.
3. Confirm generated `token=...` values are displayed as `token=<redacted>`.
4. Open the ConsoleDock panel.
5. Verify search, source filter, level filter, pause/resume, selected-entry copy, share, clear, stop, and restart behavior.
6. Repeat the import/start/logging path in `ObjCSampleApp` when Objective-C compatibility changed.

## Tag And Validate

Create an annotated tag only after local validation passes:

```sh
git tag -a v0.1.0 -m "ConsoleDock v0.1.0"
git push origin main
git push origin v0.1.0
```

The `Release Validation` GitHub Actions workflow runs on `v*` tags. It verifies:

- semantic version tag shape;
- matching `CHANGELOG.md` release heading;
- SwiftPM manifest, build, and tests;
- Release safety gates;
- DocC conversion with warnings treated as errors;
- iOS package build;
- Swift and Objective-C sample app builds;
- source archive creation.

Do not publish a GitHub Release until the tag workflow passes.

## GitHub Release Notes

Use the matching changelog section as the source of truth. Keep release notes factual:

```markdown
## ConsoleDock v0.1.0

### Highlights

- In-app UIKit debug console for iOS test/debug use.
- Objective-C-compatible core plus Swift facade.
- stdout/stderr capture with pass-through and safe restore.
- Local in-memory storage with redaction before storage, copy, and share.
- Release builds disabled by default.

### Boundaries

- Not a full replacement for Xcode Console.
- Does not promise complete Swift Logger, os_log, or Apple unified logging capture.
- No default persistence, upload, network inspector, CocoaPods, or XCFramework distribution.

### Validation

- Link to the passing Release Validation workflow run.
```

## After Publishing

1. Verify Xcode can add the repository URL as a Swift Package dependency at the tag.
2. Verify the `ConsoleDock` and `ConsoleDockCore` products resolve.
3. Open the generated DocC archive locally if documentation changed materially.
4. Leave the working tree clean.

## Patch Or Rollback

For public releases, prefer a new patch tag such as `v0.1.1` over changing or deleting `v0.1.0`.

Only delete or move a tag when it was never public, never announced, and no consumer could have resolved it.
