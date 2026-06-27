# Roadmap

This roadmap is intentionally conservative. ConsoleDock should ship small, verified releases rather than over-promising Xcode-level logging behavior.

## v0.1 - MVP Capture and Console

Goal: prove the basic product value.

Deliverables:

- Swift Package Manager package.
- `ConsoleDockCore` Objective-C/C-compatible core.
- `ConsoleDock` Swift facade.
- stdout/stderr capture with pass-through.
- in-memory ring buffer.
- default redaction.
- UIKit floating dock and log panel.
- Swift and Objective-C setup examples.
- unit tests for storage, line framing, and redaction.
- integration tests for stdout/stderr capture.
- Release default no-op behavior.

Not included:

- CocoaPods.
- XCFramework.
- remote upload.
- network inspector.
- crash reporting.
- automatic Swift `Logger` / `os_log` ingestion.

## v0.2 - Developer Experience

Goal: make the SDK comfortable for real project trials.

Many developer-experience items may land before the first public tag when they reduce release risk.

Deliverables:

- Swift sample app.
- Objective-C sample app.
- README quick start with screenshots.
- DocC for public Swift APIs.
- better search and filtering in UI.
- share/export redacted log snapshot.
- integration diagnostics for runtime state, capture configuration, store counts, and snapshot context.
- GitHub Actions build and test workflow.
- `LICENSE`, `CONTRIBUTING`, `SECURITY`, `CHANGELOG`, and issue templates.

Not included:

- binary XCFramework release automation.
- large third-party adapter suite.
- network request inspection.

## v0.3 - Functional Console Upgrade

Goal: make the bundled console useful as a local test and debugging surface, not only a log list.

Deliverables:

- log detail screen for full-message viewing and copy actions.
- explicit share choices for visible logs and all logs.
- grouped Debug Actions registered by the host app.
- Swift and Objective-C/UIKit Debug Actions registration APIs.
- confirmation prompts for dangerous actions.
- action start/completion/failure entries written back into ConsoleDock logs.
- Swift and Objective-C sample actions for smoke logs, diagnostics, simulated errors, and clearing entries.
- focused UI smoke coverage for Logs and Actions flows.

Not included:

- automatic route discovery.
- remote command delivery.
- parameterized command forms.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.4 - Test Session Reports

Goal: help testers turn a local reproduction session into a useful issue report without connecting Xcode.

Deliverables:

- local session metadata snapshots for app, process, OS, device, locale, time zone, session, and generation context.
- manual marker APIs for Swift and Objective-C integrations.
- bundled UIKit `Mark` action for adding timeline markers during a test session.
- `Share Issue Report` action that exports a local plain-text report with metadata, diagnostics, marker index, and currently retained redacted logs.
- Swift and Objective-C sample marker actions.
- focused UI smoke coverage for marker creation and issue-report share action availability.

Not included:

- persistent log storage.
- automatic upload.
- remote issue creation.
- parameterized Debug Actions.
- crash reporting.
- network inspector.

## v0.5 - Integration Upgrade

Goal: make ConsoleDock easier to adopt in existing Swift, Objective-C, and mixed UIKit projects without expanding distribution channels.

Deliverables:

- `ConsoleDock.LogForwarder` for existing Swift logger sinks/appender paths.
- `CDKLogForwarder` for Objective-C logger functions, macros, and wrappers.
- public issue report text APIs for Swift and Objective-C/UIKit integrations.
- `Copy Issue Report` in the bundled UIKit share menu.
- Debug Actions enabled-state metadata so unavailable local shortcuts can be shown without running.
- Debug Actions destructive-style metadata for actions such as clearing local debug data.
- Swift and Objective-C sample apps updated to demonstrate logger forwarders and disabled/destructive actions.
- tests, UI smoke coverage, validators, README, DocC, migration guide, and sample walkthrough updates for the new integration path.

Not included:

- CocoaPods.
- XCFramework.
- packaged third-party logger adapters.
- default persistent logging.
- automatic upload.
- remote commands.
- automatic route discovery.
- network inspector.
- crash reporting.

## v0.6 - Daily Debug Usability

Goal: make repeated local test sessions faster without expanding ConsoleDock into a remote automation platform.

Deliverables:

- configurable UIKit floating button start position.
- runtime show/hide controls for the bundled floating trigger.
- manual console presentation that still works when the bundled floating trigger is disabled.
- Logs jump menu for latest visible entries and first visible error/fault entries.
- local Debug Actions search by id, title, group, and detail.
- Swift and Objective-C samples updated to demonstrate trigger controls.
- focused UI smoke coverage for Logs jump and Actions search.
- tests, validators, README, DocC, and sample walkthrough updates for daily usability.

Not included:

- shake-to-open as a public promise.
- default persistence of button position, filters, or action search.
- parameterized Debug Actions.
- remote commands.
- automatic route discovery.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.7 - Contextual Debug Actions

Goal: make local Debug Actions useful for realistic tester flows that need small input values, and make issue reports carry app-owned context without expanding ConsoleDock into a remote testing platform.

Deliverables:

- parameterized Debug Actions with string, number, boolean, and choice parameters.
- Swift parameter access through `ConsoleDock.DebugActionParameters`.
- Objective-C/UIKit parameterized action registration through `CDKDebugActionParameter`.
- bundled UIKit action parameter forms with local validation.
- app-owned App Context sections and items for local diagnostics.
- bundled UIKit Context tab with manual refresh.
- issue reports including App Context snapshots.
- Swift and Objective-C samples updated to demonstrate parameterized actions and App Context.
- focused unit tests, UI smoke coverage, validators, README, DocC, and sample walkthrough updates for contextual debugging.

Not included:

- remote command delivery.
- automatic route discovery.
- default persistence of parameters or context.
- async action state management.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.8 - Local Reproduction Workflow

Goal: make repeated local reproduction sessions easier to run and easier to explain to a developer without connecting Xcode.

Deliverables:

- local Debug Action execution history for the current process session.
- public Swift access to action execution outcomes through `ConsoleDock.actionExecutionHistory`.
- session-only recent parameter value reuse in bundled UIKit action parameter forms.
- issue report reproduction timelines combining markers, Debug Action executions, and retained error/fault logs in timestamp order.
- user-initiated temporary `.txt` item generation for `Share Issue Report`.
- unchanged text report access through `ConsoleDock.issueReportText()` and `CDKConsoleDockUIKit.issueReportText`.
- tests, validators, README, DocC, privacy, and sample walkthrough updates for the local reproduction workflow.

Not included:

- default persistent action history or parameter storage.
- remote command delivery.
- automatic route discovery.
- async action state management.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.9 - Local Log Query And Triage

Goal: make larger local log sessions easier to narrow and navigate without turning ConsoleDock into a logging database or remote debug platform.

Deliverables:

- structured local Logs queries for source, level, and entry flags.
- quoted phrase search and excluded text terms.
- compatibility with existing plain-text search behavior.
- Logs search placeholder that exposes the compact query hint.
- Jump actions for previous and next visible error/fault entries in the current filtered result set.
- Swift and Objective-C sample UI smoke coverage for structured Logs queries and expanded Jump controls.
- focused unit tests, accessibility identifier validation, README, DocC, changelog, and sample walkthrough updates for local query triage.

Not included:

- default persistent logs, filters, or saved searches.
- regex, boolean grouping, date ranges, or a public query-language API.
- remote upload.
- automatic route discovery.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.10 - Session Timeline

Goal: make the current local debug session easier to understand at a glance without adding persistence or remote automation.

Deliverables:

- bundled UIKit `Timeline` mode alongside Logs, Actions, and Context.
- shared internal timeline builder for manual markers, Debug Action executions, and retained error/fault logs.
- Timeline rows for marker, action, and error/fault events in stable timestamp order.
- log detail navigation for marker and error/fault timeline rows.
- action detail navigation and copy support for Debug Action execution rows.
- issue-report reproduction timeline reuse of the same internal builder.
- Swift and Objective-C sample UI smoke coverage for Timeline rows and detail navigation.
- focused unit tests, accessibility identifier validation, README, DocC, changelog, and sample walkthrough updates for current-session timeline triage.

Not included:

- default persistent logs, timeline history, filters, actions, parameters, context, or reports.
- timeline filtering, saved views, regex, date ranges, or a public Timeline API.
- remote upload.
- automatic route discovery.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.11 - Local Session Archive

Goal: let testers explicitly save a bounded local issue-report snapshot so reproduction evidence can be reopened after an app restart without turning ConsoleDock into persistent raw logging.

Deliverables:

- `ConsoleDock.SessionArchive` metadata and report-text model.
- Swift APIs for `saveSessionArchive`, `sessionArchives`, `deleteSessionArchive`, and `clearSessionArchives`.
- Objective-C/UIKit facade APIs through `CDKSessionArchive` and `CDKConsoleDockUIKit`.
- app-local JSON persistence of already-redacted issue-report snapshots, bounded by archive count and report length.
- bundled UIKit `Save Session Archive` and `Saved Session Archives` flows from the Logs share menu.
- archive list and detail screens with copy, share, delete, and clear-all controls.
- Swift and Objective-C sample actions plus focused UI smoke coverage for archive menu and Swift archive detail/delete flow.
- unit tests, accessibility identifier validation, README, DocC, privacy, roadmap, changelog, and sample walkthrough updates for explicit local session archives.

Not included:

- default persistent raw logs.
- background auto-save of every session.
- crash-final log recovery guarantees.
- archive search, database queries, saved filters, or diffing.
- remote upload, sync, remote issue creation, or automation-platform behavior.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.12 - Public Readiness And Visual QA

Goal: make the public repository, screenshots, and release validation reflect the product ConsoleDock has become before considering a stable `1.0.0` release.

Deliverables:

- current iOS Simulator screenshots captured from the Swift sample app.
- curated public screenshot set for Logs, Actions, Timeline, and Local Session Archive.
- screenshot capture script for regenerating the public Swift sample assets.
- documentation asset validator for required PNG files, dimensions, references, and release-audit allow-list coverage.
- release-process visual QA guidance that distinguishes behavioral UI smoke from public screenshot review.
- README, simplified Chinese README, sample walkthrough, DocC, roadmap, changelog, and release validator cleanup for the current public presentation.
- focused public API and compatibility wording review without unnecessary breaking changes.

Not included:

- new debugging panels or product modes.
- UIKit redesign, SwiftUI rewrite, or marketing site.
- default persistent raw logs.
- remote upload, sync, remote issue creation, or automation-platform behavior.
- network inspector.
- crash reporting.
- CocoaPods or XCFramework distribution.

## v0.13 - Integration Doctor

Goal: help developers and testers understand the current ConsoleDock integration state when expected logs or local debugging signals do not appear.

Deliverables:

- generated local Integration Diagnosis text.
- `ConsoleDock.integrationDiagnosisText()` for Swift integrations.
- `CDKConsoleDockUIKit.integrationDiagnosisText` for Objective-C/UIKit integrations.
- ConsoleDock-owned `ConsoleDock Health` section in the existing Context tab.
- `Copy Integration Diagnosis` from the Context tab.
- source and level counts, redacted/truncated/partial counts, Debug Action counts, App Context status, Local Session Archive count, and local recommendations.
- issue reports include the same ConsoleDock Health section.
- Swift sample UI smoke coverage for the Context health section and copy action.
- focused unit tests, API validators, README, DocC, changelog, and sample walkthrough updates.

Not included:

- automatic repair or configuration mutation.
- complete Swift `Logger`, `os_log`, or Apple unified logging capture.
- new tab, large UIKit redesign, or SwiftUI rewrite.
- stable public typed health model.
- remote upload, remote issue creation, network inspector, crash reporting, CocoaPods, or XCFramework distribution.

## v0.14 - Support Reports

Goal: support app-owned feedback and support flows with bounded, on-demand local reports without turning ConsoleDock into analytics, telemetry, or background logging.

Deliverables:

- `ConsoleDock.SupportReport`, `SupportReportOptions`, and `SupportReportTimeRange`.
- Swift APIs for `supportReport(options:)` and `makeTemporarySupportReportFile(options:)`.
- Objective-C/UIKit facade APIs through `CDKSupportReport` and `CDKConsoleDockUIKit`.
- default last-10-minutes report window, presets for 5/10/30/60 minutes, all-retained reports, and explicit date ranges.
- report headers with included/omitted entry and action-execution counts, time range, size limit, truncation state, storage boundary, and current-session scope.
- bounded report text with explicit truncation notices.
- on-demand temporary support-report text files with ConsoleDock-owned temp-directory pruning.
- focused unit tests, API validators, README, DocC, privacy, roadmap, changelog, and sample walkthrough updates.

Not included:

- analytics, telemetry, user statistics, or behavioral event collection.
- background upload, automatic remote issue creation, or server SDK behavior.
- continuous raw log file persistence.
- crash reporting, network inspector, remote commands, CocoaPods, or XCFramework distribution.

## v0.15 - Readiness Hardening

Goal: make the current SDK more trustworthy for 1.0 evaluation by fixing real edge cases and tightening validation without changing the product boundary.

Deliverables:

- stronger partial-fragment redaction for oversized lines split around sensitive keys or values.
- baseline redaction for App Context values, Debug Action summaries/messages, and Local Session Archive notes before they appear in reports.
- bounded Debug Action execution history and cleanup of session-only recent parameter values on unregister.
- local-only expiring pasteboard writes for bundled UIKit copy actions where supported.
- file protection where available plus backup exclusion for ConsoleDock-owned temporary report and archive files.
- Objective-C/UIKit start side effects aligned with the Swift facade.
- API validators updated for effective floating button position diagnostics.
- versioned documentation validation that derives the current release tag from the changelog.
- README, DocC, privacy, roadmap, changelog, and sample walkthrough cleanup for the hardened behavior.

Not included:

- analytics, telemetry, automatic upload, or user-statistics collection.
- default continuous file logging or background persistence.
- marker storage model changes or broader public API freezing work.
- SwiftUI rewrite, network inspector, crash reporting, remote commands, CocoaPods, or XCFramework distribution.

## v0.16 - API Readiness

Goal: remove 1.0 API-readiness issues that are already visible in the current SDK without expanding product scope.

Deliverables:

- first-class marker metadata on core and Swift log entries so Timeline and issue reports do not infer markers from a user-visible `[marker]` prefix alone.
- `ConsoleDock.Configuration` no longer conforms to `Equatable` because its redactor closure cannot be compared lawfully.
- Objective-C/UIKit action-history cleanup parity through `CDKConsoleDockUIKit.clearActionExecutionHistory`.
- focused tests and API validators for marker metadata, ordinary `[marker]`-prefixed logs, and UIKit facade cleanup.
- README, DocC, roadmap, changelog, and sample walkthrough cleanup for the API-readiness behavior.

Not included:

- analytics, telemetry, automatic upload, or user-statistics collection.
- default continuous file logging or background persistence.
- broad public API renaming unrelated to the equality correction.
- SwiftUI rewrite, network inspector, crash reporting, remote commands, CocoaPods, or XCFramework distribution.

## Post-v0.16 - Demand-Driven Compatibility Candidates

Goal: improve adoption in existing apps only when real integration feedback shows SPM and the current explicit API are not enough.

Candidate work, not committed deliverables:

- CocoaLumberjack adapter if real users need it.
- XCGLogger or SwiftyBeaver adapter, selected by real adoption demand.
- CocoaPods compatibility evaluation only if real older Objective-C or mixed projects cannot adopt the Swift Package.
- richer report formatting only if real tester workflows need it.
- saved local-only presets only if real tester workflows prove session-only recent values are not enough.

Not included:

- default persistent logging.
- automatic network upload.
- system log reading.

## v1.0 - Stable Public SDK

Goal: provide a stable, documented debug SDK for broad open-source use.

Deliverables:

- stable public API.
- semantic versioning policy enforced through changelog.
- SPM tagged release.
- CI coverage for package, sample apps, and focused UI smoke tests.
- complete privacy/redaction documentation.
- release-build safety tests.
- documented decision to keep CocoaPods and XCFramework out of scope unless real consumer demand justifies them.
- maintained migration guide from `print`, `NSLog`, and common logger frameworks.
- public API audit for initializer visibility, low-level core exposure, and long-term source stability.

Not included:

- promises of complete Swift `Logger` / `os_log` zero-intrusion capture.
- private API usage.
- reading logs from other processes.
- debugger features such as breakpoints or LLDB expression evaluation.

## Post-1.0 Ideas

Future features should be driven by real user demand:

- network request panel;
- crash breadcrumbs;
- richer adapter ecosystem;
- remote issue attachment workflow;
- advanced log sharing formats;
- SwiftUI-specific presentation helpers.

Each post-1.0 feature should preserve the default local-only, debug-first safety model.
