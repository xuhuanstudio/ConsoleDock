# Changelog

All notable changes to ConsoleDock will be documented in this file.

The project follows Semantic Versioning for public releases.

## Unreleased

No changes yet.

## v0.11.0 - 2026-06-27

### Added

- Added explicit Local Session Archive APIs for saving, listing, deleting, and clearing bounded local issue-report snapshots.
- Added Objective-C/UIKit archive bridging through `CDKSessionArchive` and `CDKConsoleDockUIKit`.
- Added bundled UIKit `Save Session Archive` and `Saved Session Archives` flows with archive list, detail, copy, share, delete, and clear-all controls.
- Added Swift and Objective-C sample archive actions plus focused UI smoke coverage for archive menu and Swift archive detail/delete flow.
- Added unit tests, API surface validation, accessibility identifier validation, README, DocC, privacy, roadmap, changelog, and sample walkthrough updates for local archive boundaries.

## v0.10.0 - 2026-06-26

### Added

- Added a bundled UIKit `Timeline` mode that aggregates current-session markers, local Debug Action executions, and retained error/fault logs.
- Added a shared internal timeline builder used by both the Timeline view and issue-report reproduction timeline text.
- Added Timeline detail navigation to existing log detail screens and a new Debug Action execution detail screen with copy support.
- Added Swift and Objective-C sample UI smoke coverage for Timeline rows and detail navigation.
- Added unit tests, accessibility identifier validation, README, DocC, roadmap, changelog, and sample walkthrough updates for local Session Timeline triage.

## v0.9.0 - 2026-06-26

### Added

- Added structured local Logs queries for `source:`, `level:`, and `is:` tokens while preserving plain-text search behavior.
- Added quoted phrase search and excluded text terms for local Logs filtering.
- Added previous and next visible error/fault actions to the Logs `Jump` menu.
- Added Swift and Objective-C sample UI smoke coverage for structured Logs queries and expanded Jump controls.
- Added unit tests, accessibility identifier validation, README, DocC, roadmap, changelog, and sample walkthrough updates for local log query triage.

## v0.8.0 - 2026-06-26

### Added

- Added local Debug Action execution history through `ConsoleDock.actionExecutionHistory` and `ConsoleDock.clearActionExecutionHistory()`.
- Added session-only recent parameter value reuse for bundled UIKit Debug Action parameter forms.
- Added issue-report reproduction timelines that combine markers, Debug Action executions, and retained error/fault log entries in timestamp order.
- Added temporary `.txt` issue-report file generation for user-initiated `Share Issue Report` while keeping `Copy Issue Report` and `ConsoleDock.issueReportText()` text-based.
- Added unit tests, API validator coverage, README, DocC, roadmap, privacy, and sample walkthrough updates for the local reproduction workflow.

## v0.7.0 - 2026-06-26

### Added

- Added parameterized Debug Actions with string, number, boolean, and choice inputs for Swift integrations.
- Added Objective-C/UIKit parameterized Debug Action APIs through `CDKDebugActionParameter` and `CDKConsoleDockUIKit`.
- Added a bundled UIKit action parameter form with validation and stable accessibility identifiers.
- Added App Context snapshots through `ConsoleDock.setAppContextProvider` and `CDKConsoleDockUIKit.setAppContextProvider`.
- Added a bundled UIKit Context tab with refresh support.
- Added App Context output to local issue reports.
- Added Swift and Objective-C sample parameterized actions, App Context providers, UI smoke coverage, API validators, DocC, README, roadmap, and sample walkthrough updates for contextual debugging.

## v0.6.0 - 2026-06-26

### Added

- Added configurable UIKit floating button positions through `ConsoleDock.Configuration.floatingButtonPosition` and `CDKConfiguration.floatingButtonPosition`.
- Added `ConsoleDock.showFloatingButton()`, `ConsoleDock.hideFloatingButton()`, `[CDKConsoleDockUIKit showFloatingButton]`, and `[CDKConsoleDockUIKit hideFloatingButton]` for runtime trigger visibility control.
- Added a Logs `Jump` menu for latest visible logs and first visible error/fault entries.
- Added local Debug Actions search by id, title, group, and detail.
- Added Swift and Objective-C sample controls/actions, UI smoke coverage, API validators, DocC, README, and roadmap updates for daily debug usability.

## v0.5.0 - 2026-06-26

### Added

- Added `ConsoleDock.LogForwarder` and `CDKLogForwarder` for forwarding existing app logger sink/appender output into ConsoleDock without rewriting old call sites.
- Added public issue report text APIs through `ConsoleDock.issueReportText()` and `CDKConsoleDockUIKit.issueReportText`.
- Added `Copy Issue Report` to the bundled UIKit share menu alongside visible/all/issue-report sharing.
- Added Debug Actions enabled-state and destructive-style metadata for Swift and Objective-C/UIKit integrations.
- Added sample app usage of Swift and Objective-C logger forwarders plus disabled/destructive Debug Action examples.
- Added unit, UI smoke, API surface, accessibility identifier, sample documentation, README, DocC, and roadmap coverage for the v0.5 integration upgrade.

## v0.4.0 - 2026-06-26

### Added

- Added local session metadata snapshots for Swift and Objective-C integrations so issue reports can include app, process, OS, device, locale, time zone, session, and generation context.
- Added manual marker APIs through `ConsoleDock.mark(_:)` and `[CDKConsoleDock mark:]`; markers are stored as native info entries and continue through the existing redaction and truncation path.
- Added `Mark` and `Share Issue Report` actions to the bundled UIKit log panel.
- Added an internal plain-text issue report formatter containing session metadata, diagnostics, marker index, and currently retained redacted logs.
- Added sample app marker actions and UI smoke coverage for marker creation and issue-report share action availability.
- Added DocC, README, roadmap, sample walkthrough, validator, and release-process documentation for Test Session Reports.

## v0.3.2 - 2026-06-26

### Changed

- Stabilized sample UI smoke level-filter selection on slow CI by retrying segmented-control selection and matching visible-entry counts with whitespace-tolerant status parsing.
- Updated public installation guidance so the latest release tag points to `v0.3.2` after the failed `v0.3.1` release-validation candidate.

## v0.3.1 - 2026-06-26

### Changed

- Stabilized Swift and Objective-C sample UI smoke tests by waiting for the console status visible-entry count before asserting filtered log rows.
- Updated public installation guidance so the latest release tag points to `v0.3.1` after the failed `v0.3.0` release-validation candidate.

## v0.3.0 - 2026-06-26

### Added

- Added local Debug Actions registration for Swift and Objective-C/UIKit integrations so apps can expose explicit test shortcuts in the bundled console.
- Added a Logs / Actions switch in the bundled UIKit console, grouped Debug Actions, confirmation prompts for dangerous actions, and automatic action start/completion/failure log entries.
- Added a log detail screen with full-message viewing and separate copy-message/copy-entry actions.
- Added explicit share options for visible logs and all logs.
- Added Debug Actions sample registrations and UI smoke coverage for the Swift and Objective-C sample apps.

## v0.2.0 - 2026-06-23

### Added

- Added Release safety coverage for the Swift facade and Objective-C/UIKit facade entry points.
- Added clear-button refresh assertions to the Swift sample UI smoke test.
- Added Dependabot configuration for weekly GitHub Actions update checks.
- Added a distribution strategy document and validation gate for SPM, future CocoaPods compatibility, and future XCFramework distribution claims.
- Added distribution artifact validation to prevent premature CocoaPods, XCFramework, framework, Xcode archive, debug symbol, static library, or packaged archive distribution files.
- Added a logging boundary validation gate to keep Swift Logger, os_log, Apple unified logging, Xcode Console, and other-process log claims honest.
- Added a Swift API surface validation gate to protect app-facing facade and UIKit bridge integration points.
- Added Swift and Objective-C API surface validator self-tests for missing APIs, public symbol leaks, and package header-path regressions.
- Added versioned documentation and distribution policy validator self-tests for main-only API leaks, premature channel claims, and tracked future artifacts.
- Added bounded retry handling to post-release verification for transient GitHub, SwiftPM, and Swift Package Index network failures.
- Added explicit post-release verifier handling for Swift Package Index access challenges that require manual browser confirmation.
- Added search-control rendering and level-filtering assertions to the Swift and Objective-C sample UI smoke tests.
- Added selected-row tap assertions to the Swift and Objective-C sample UI smoke tests.
- Added GitHub Release notes boundary and validation-link checks to the post-release verifier.
- Added public release preflight self-tests and dry-run input validation for malformed release rehearsal tags.
- Added release metadata validator self-tests for tag shape, changelog heading, and cleared Unreleased checks.
- Added post-release verification that GitHub Release notes link to the matching repository and tag validation workflow run.
- Added post-release verification that the tag validation workflow ran against the current remote tag commit.
- Added logging-boundary validator self-tests and tightened roadmap wording around Swift Logger/os_log ingestion.
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
- Added an opt-in Objective-C sample UI smoke test and validation script for Simulator-based release checks.
- Added sample app documentation and automation validation to keep smoke-test guidance in sync.
- Added visible redaction assertions to the Swift sample UI smoke test.

### Changed

- Tightened Apple unified logging wording so README and product docs describe only current explicit-forwarding behavior instead of speculative future logging outputs.
- Clarified README diagnostics examples as `main`-only until the next tag and tightened the release gate for versioned public documentation.
- Enabled focused Swift and Objective-C sample UI smoke tests in GitHub CI and release-validation workflows.
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
