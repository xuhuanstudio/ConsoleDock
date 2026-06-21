# ConsoleDock Open Source Readiness Plan

ConsoleDock should be structured as a professional global open-source SDK, not just a local debugging experiment.

## README Internationalization Strategy

Primary repository language: English.

Recommended secondary material:

- short Chinese overview in `README.zh-CN.md` after the English README stabilizes;
- issue templates in English first;
- documentation examples that avoid region-specific services or private company terminology.

The public README should be direct about what ConsoleDock can and cannot capture. Avoid marketing phrases that imply Xcode replacement or system-level logging access.

## License

Recommended license: MIT.

Reasoning:

- familiar to iOS open-source users;
- permissive for commercial app adoption;
- compatible with SDK distribution through SPM, CocoaPods, and XCFramework;
- low friction for global contributors.

Before public release, add:

- `LICENSE`
- copyright owner
- year

## Governance Files

Add before the first public release:

- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/pull_request_template.md`

`SECURITY.md` should state that ConsoleDock is a debug tool and that reports involving accidental sensitive data exposure, release-build activation, or unsafe export behavior are security-relevant.

## Semantic Versioning

Use Semantic Versioning:

- `0.x`: API may change while architecture stabilizes.
- `1.0`: public API is stable enough for production development workflows, while still intended for debug/test builds.

Version gates:

- breaking public API changes require a minor bump before `1.0`;
- breaking public API changes require a major bump after `1.0`;
- bug fixes and documentation improvements use patch releases.

## Package Distribution Strategy

### Swift Package Manager

SPM is the primary distribution channel.

Requirements:

- `Package.swift` with explicit platform support;
- stable target names;
- library products for Swift and Objective-C-compatible integration;
- tagged releases.

### CocoaPods

CocoaPods support should come after the SPM package is stable.

Requirements:

- public headers for `ConsoleDockCore`;
- a podspec that does not require source copying;
- clear compatibility guidance for older Objective-C apps.

### XCFramework

XCFramework support should come after the core API is stable.

Requirements:

- reproducible build script;
- signed or checksummed release artifacts when appropriate;
- release notes for each binary artifact.

## CI Plan

Use GitHub Actions on macOS runners.

Initial checks:

- Swift package resolve;
- Swift package build;
- xcodebuild build for iOS simulator;
- unit tests;
- documentation link check where practical;
- formatting or lint check once a formatter is selected.

Future checks:

- Objective-C sample app build;
- Swift sample app build;
- UI test smoke run on iOS simulator;
- XCFramework packaging validation;
- CocoaPods lint.

CI should avoid tests that require private signing identities.

## Documentation Plan

Minimum public docs:

- README quick start;
- architecture document;
- logging boundary document;
- privacy and redaction guide;
- release-build safety guide;
- migration guide for existing loggers;
- sample app walkthrough.

DocC should be added once public Swift APIs exist.

Documentation must include examples for:

- Swift app setup;
- Objective-C app setup;
- stdout/stderr capture;
- explicit logging API;
- redaction customization;
- disabling ConsoleDock in Release.

## API Stability And Version Compatibility

Public APIs should be small in the MVP.

Rules:

- expose configuration objects instead of many overloads;
- avoid leaking internal storage types;
- avoid exposing UIKit internals as required public API;
- prefix Objective-C symbols with `CDK`;
- keep source-level compatibility notes in `CHANGELOG.md`.

Swift API names should be concise and idiomatic. Objective-C API names should be explicit and stable.

## Privacy and Security Principles

ConsoleDock should default to local-only, memory-only behavior.

Security principles:

- no default network upload;
- no default disk persistence;
- redaction before storage and export;
- release builds disabled by default;
- explicit user action for copy/share/export;
- no collection of logs from other processes;
- no private API.

Public docs should tell adopters that log content may contain sensitive data and that they should configure redaction for app-specific fields.

## Release Checklist

Before `v0.1.0`:

- package builds with SPM;
- sample app demonstrates baseline capture;
- README has installation and quick-start instructions;
- MIT license is present;
- security policy is present;
- `Logger` / `os_log` boundary is documented;
- release notes are written.

Before `v1.0.0`:

- public API has been used in at least one real sample or internal app;
- CI covers supported platforms;
- ObjC integration path is documented and tested;
- redaction has focused tests;
- Release safety behavior is tested;
- documentation is clear enough for external contributors.
