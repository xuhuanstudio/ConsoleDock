# Changelog

All notable changes to ConsoleDock will be documented in this file.

The project follows Semantic Versioning after public releases begin.

## Unreleased

No changes yet.

## v0.1.0 - 2026-06-22

Initial public preview of ConsoleDock as a source-first Swift Package Manager iOS debug SDK.

### Added

- Added the `ConsoleDockCore` Objective-C-compatible core target with `CDK`-prefixed APIs.
- Added the `ConsoleDock` Swift facade target with startup, shutdown, native logging, entry snapshot, clear, and UIKit console controls.
- Added consistent Swift and Objective-C UIKit facade startup behavior when ConsoleDock is already running.
- Added bounded in-memory log storage with message truncation, read/clear APIs, and entries-changed notifications.
- Added startup validation for invalid memory and message length limits, with Swift facade handling for negative values without runtime crashes.
- Added default redaction before storage for obvious authorization bearer values, cookie headers, token, password, passwd, access token, refresh token, API key, client secret, key, and secret patterns.
- Added app-specific redaction configuration hooks in both Swift and Objective-C-compatible APIs.
- Added byte-to-line framing for stdout/stderr chunks, including CRLF normalization, partial flushes, independent source buffers, bounded partial lines, and invalid UTF-8 replacement.
- Added stdout/stderr file-descriptor capture with pass-through to the original descriptors, safe restore on stop, partial flush on stop, direct descriptor write coverage, and capture enable/disable configuration.
- Added native logging levels for debug, info, warning, error, and fault.
- Added Release safety gates so Release startup is disabled by default and requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`.
- Added the bundled UIKit floating button and in-app console panel with live refresh, search, source filtering, level filtering, pause/resume live follow, selected-entry copy, clear, share/export, close, and lifecycle teardown.
- Added Objective-C access to the bundled UIKit console through `CDKConsoleDockUIKit`.
- Added Swift and Objective-C UIKit sample apps that exercise package integration, native logs, stdout, stderr, `NSLog`, redaction, clear, stop, and restart behavior.
- Added README quick start content, a real Simulator screenshot, sample app walkthrough, Release safety documentation, existing logger migration guide, and DocC documentation for public Swift usage.
- Added open-source governance files, issue templates, pull request template, security policy, and contribution guidance.
- Added CI coverage for SwiftPM manifest validation, build, tests, Release safety gates, documentation link validation, DocC conversion, iOS package build, and Swift/Objective-C sample app builds.
- Added release process documentation, reusable DocC and documentation-link validation scripts, tag-triggered release validation, and source archive validation.
- Added release content audit for generated paths, private key blocks, common token shapes, and local absolute paths before publishing.
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
