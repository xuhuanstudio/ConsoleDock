# Changelog

All notable changes to ConsoleDock will be documented in this file.

The project follows Semantic Versioning for public releases.

## Unreleased

### Added

- Added clear-button refresh assertions to the Swift sample UI smoke test.
- Added Dependabot configuration for weekly GitHub Actions update checks.
- Added a distribution strategy document and validation gate for SPM, future CocoaPods compatibility, and future XCFramework distribution claims.
- Added distribution artifact validation to prevent premature CocoaPods, XCFramework, framework, Xcode archive, debug symbol, static library, or packaged archive distribution files.
- Added a logging boundary validation gate to keep Swift Logger, os_log, Apple unified logging, Xcode Console, and other-process log claims honest.
- Added a Swift API surface validation gate to protect app-facing facade and UIKit bridge integration points.
- Added bounded retry handling to post-release verification for transient GitHub, SwiftPM, and Swift Package Index network failures.
- Added `.editorconfig` and `.gitattributes` to standardize editor behavior and line endings for global contributors.
- Added `.gitignore` governance validation and expanded generated-artifact ignores for Xcode, SwiftPM, DocC, CocoaPods, and future binary distribution outputs.
- Added the v0.2 integration diagnostics design specification for runtime state, UIKit status, snapshot export, tests, and documentation.
- Added `CDKDiagnostics` and `ConsoleDock.Diagnostics` for runtime state, capture configuration, store limits, and current entry flag counts.
- Added `ConsoleDock.log(level:message:)` for Swift logger sinks and adapters that already carry a severity value.
- Added `CDKConsoleDockDiagnosticsDidChangeNotification` and `ConsoleDock.diagnosticsDidChangeNotification` for custom debug surfaces that need to refresh diagnostics independently from entry-list updates.
- Added a compact UIKit diagnostics header and included diagnostics in share/export snapshots.
- Added diagnostics controls and status output to the Swift and Objective-C sample apps.
- Added app-specific logger sink forwarding controls to the Swift and Objective-C sample apps.
- Added stable accessibility identifiers to bundled console and sample controls for future UI smoke automation.
- Added an opt-in Swift sample UI smoke test and validation script for Simulator-based release checks.
- Added visible redaction assertions to the Swift sample UI smoke test.

### Changed

- Enabled the focused Swift sample UI smoke test in GitHub CI and release-validation workflows.
- Broadened default redaction for common mobile token names including ID, auth, session, CSRF, and `x-api-key` forms.
- Redacted stdout/stderr partial-line continuations from the same source after a sensitive oversized fragment is detected.
- Updated README status and installation guidance now that `v0.1.0` is publicly released.
- Updated Swift Package Index status guidance after the PackageList entry was merged.
- Added public README badges for CI, release validation, latest release, and license status.
- Broadened default redaction for `Authorization` header values beyond bearer tokens.
- Updated GitHub Actions checkout usage to the Node 24-compatible `actions/checkout@v6` runtime.
- Aligned contribution and security policy status wording with the public `v0.x` preview stage.
- Made release validation helper dry-runs use the active release tag instead of hard-coding `v0.1.0`.
- Tightened Swift API surface validation for public initializer signatures and duplicated public message fields.

## v0.1.0 - 2026-06-22

Initial public preview of ConsoleDock as a source-first Swift Package Manager iOS debug SDK.

### Added

- Added the `ConsoleDockCore` Objective-C-compatible core target with `CDK`-prefixed APIs.
- Added the `ConsoleDock` Swift facade target with startup, shutdown, native logging, entry snapshot, clear, and UIKit console controls.
- Added consistent Swift and Objective-C UIKit facade startup behavior when ConsoleDock is already running.
- Added bounded in-memory log storage with stable session identifiers, partial/redacted/truncated processing flags, message truncation, read/clear APIs, and entries-changed notifications.
- Added scoped entries-change observation so the bundled Swift UI refresh path ignores unrelated notifications that reuse the same notification name.
- Added startup validation for invalid memory and message length limits, with Swift facade handling for negative values without runtime crashes.
- Added configuration snapshot behavior so startup uses the configuration values supplied at the time of `start`, even if callers mutate their original configuration object later.
- Added default redaction before storage for obvious authorization bearer values, cookie headers, token, password, passwd, access token, refresh token, API key, client secret, key, and secret patterns.
- Added app-specific redaction configuration hooks in both Swift and Objective-C-compatible APIs.
- Added byte-to-line framing for stdout/stderr chunks, including CRLF normalization, partial flushes, independent source buffers, bounded partial lines, and invalid UTF-8 replacement.
- Added stdout/stderr file-descriptor capture with pass-through to the original descriptors, safe restore on stop, partial flush on stop, direct descriptor write coverage, and capture enable/disable configuration.
- Added integration coverage for Swift `print` and flushed C stdio stdout/stderr capture with pass-through.
- Added native logging levels for debug, info, warning, error, and fault.
- Added Release safety gates so Release startup is disabled by default and requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`.
- Added the bundled UIKit floating button and in-app console panel with live refresh, search, source filtering, level filtering, pause/resume live follow, selected-entry copy, clear, share/export, close, and lifecycle teardown.
- Added Objective-C access to the bundled UIKit console through `CDKConsoleDockUIKit`.
- Added Swift and Objective-C UIKit sample apps that exercise package integration, native logs, stdout, stderr, `NSLog`, redaction, clear, stop, and restart behavior.
- Added README quick start content, a real Simulator screenshot, sample app walkthrough, Release safety documentation, existing logger migration guide, and DocC documentation for public Swift usage.
- Added open-source governance files, issue templates, pull request template, security policy, and contribution guidance.
- Added governance metadata validation for required open-source files, workflows, issue templates, and pull request template safeguards.
- Added CI coverage for SwiftPM manifest validation, build, tests, Release safety gates, documentation link validation, DocC conversion, iOS package build, and Swift/Objective-C sample app builds.
- Added GitHub Actions hardening with read-only permissions, concurrency controls, job timeouts, and non-persistent checkout credentials.
- Added release process documentation, reusable DocC and documentation-link validation scripts, tag-triggered release validation, and source archive validation.
- Added release content audit for generated paths, private key blocks, common token shapes, and local absolute paths before publishing.
- Added source archive content audit before publishing release artifacts.
- Added source archive package build/test validation before publishing release artifacts.
- Added public release preflight validation for tag metadata, repository governance, content audit, remote branch HEAD matching, and remote tag collision checks.
- Added post-release verification for GitHub Release state, tag validation workflow status, external SwiftPM consumer builds, and optional Swift Package Index package/DocC availability checks.
- Added release helper script dry-runs to the shared release validation gate.
- Added a local post-release verifier self-test for repository parsing, semantic version tag parsing, and SwiftPM `v*` tag exact-version resolution.
- Added clean working tree enforcement to release validation so source archive checks match the committed state being released.
- Added package identity validation for Swift tools version, public products, platforms, targets, and target dependencies.
- Added Swift formatting lint validation with a minimal cross-runner configuration for source, tests, and the Swift sample app.
- Added Swift Package Index metadata for hosted DocC documentation.
- Added Swift Package Index metadata validation to the release gate.
- Added Objective-C API surface validation to protect the `CDK`-prefixed public core API.
- Added a GitHub repository setup checklist for public repository identity, topics, Actions, vulnerability reporting, first push, first tag, and post-release SPM verification.
- Added a Simplified Chinese README overview while keeping English README, DocC, and `docs/` as the authoritative documentation.
- Added a standalone privacy and redaction guide covering the core redaction order, default patterns, app-specific redactors, copy/share behavior, and Release-build privacy checklist.
- Added a reusable release validation script shared by local release checks, CI, and tag validation.
- Clarified the security reporting path for vulnerability and sensitive-data exposure reports before the first public stable release.
- Updated public project-stage documentation to match the implemented MVP capture, UIKit console, and SPM-first distribution state.

### Boundaries

- ConsoleDock is not a full replacement for Xcode Console or Apple unified logging.
- ConsoleDock does not promise complete zero-intrusion capture of Swift `Logger`, `os_log`, Apple unified logging entries, other-process logs, debugger output, LLDB expressions, or sanitizer diagnostics.
- Reliable in-app visibility should use ConsoleDock's explicit API or a sink/appender in an existing logger.
- This release does not include CocoaPods, XCFramework distribution, network inspection, crash reporting, default persistence, remote upload, or packaged third-party logger adapters.
