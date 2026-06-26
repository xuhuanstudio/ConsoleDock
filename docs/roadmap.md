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

## Post-v0.10 - Demand-Driven Compatibility Candidates

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
