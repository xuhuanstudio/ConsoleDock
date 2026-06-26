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

## Post-v0.12 - Demand-Driven Compatibility Candidates

Goal: improve adoption in existing apps only when real integration feedback shows SPM and the current explicit API are not enough.

Candidate work, not committed deliverables:

- CocoaLumberjack adapter if real users need it.
- XCGLogger or SwiftyBeaver adapter, selected by real adoption demand.
- CocoaPods compatibility evaluation only if real older Objective-C or mixed projects cannot adopt the Swift Package.
- richer issue report formatting only if real tester workflows need it.
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
