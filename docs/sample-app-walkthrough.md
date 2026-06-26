# Sample App Walkthrough

ConsoleDock includes Swift and Objective-C UIKit sample apps that exercise the package through the same public integration paths real apps should use.

Use the samples to verify:

- Swift package integration;
- Objective-C imports and `CDK` APIs;
- stdout and stderr file-descriptor capture;
- explicit native logging APIs;
- app-specific logger sink forwarding without rewriting every call site;
- runtime diagnostics for capture state and current store counts;
- Debug Actions for app-registered local test shortcuts;
- parameterized Debug Actions for small local test inputs;
- session-only recent parameter reuse and current-session Debug Action execution history;
- App Context snapshots in the bundled Context tab and issue reports;
- manual markers, Session Timeline, reproduction timeline issue reports, local issue report sharing/copying, and Local Session Archive save/review/delete flows;
- `NSLog` output that reaches process stderr;
- redaction before storage;
- UIKit floating button configuration, trigger show/hide controls, plain and structured Logs search, source and level filtering, Logs jump controls, pause/resume live follow, log detail, copy, panel refresh, share/export, Timeline review, Actions search, action parameter forms, Context tab refresh, actions, clear, stop, and restart behavior.

The bundled console and sample controls expose stable accessibility identifiers so future UI smoke tests can target behavior without relying on localized text. Key bundled console identifiers include `consoledock.dock-button`, `consoledock.mode-control`, `consoledock.search`, `consoledock.actions-search`, `consoledock.level-filter`, `consoledock.jump`, `consoledock.jump-latest-log`, `consoledock.jump-first-error`, `consoledock.jump-previous-error`, `consoledock.jump-next-error`, `consoledock.status`, `consoledock.entries-table`, `consoledock.timeline-table`, `consoledock.timeline-refresh`, `consoledock.timeline-action-detail.text`, `consoledock.actions-table`, `consoledock.context-table`, `consoledock.context-refresh`, `consoledock.action-parameters.form`, `consoledock.action-parameters.run`, `consoledock.mark`, `consoledock.marker-text`, `consoledock.add-marker`, `consoledock.share-issue-report`, `consoledock.copy-issue-report`, `consoledock.save-session-archive`, `consoledock.saved-session-archives`, `consoledock.session-archives.table`, and `consoledock.session-archive-detail.text`. Sample app button identifiers use `swift-sample.<button-slug>` and `objc-sample.<button-slug>`.

## Current Simulator Screenshots

These screenshots are captured from the Swift sample app in iOS Simulator UI automation mode:

| Logs | Actions |
| --- | --- |
| ![ConsoleDock Swift sample Logs screen](assets/swift-sample-logs.png) | ![ConsoleDock Swift sample Actions screen](assets/swift-sample-actions.png) |

| Timeline | Local Session Archive |
| --- | --- |
| ![ConsoleDock Swift sample Timeline screen](assets/swift-sample-timeline.png) | ![ConsoleDock Swift sample Local Session Archive screen](assets/swift-sample-archive.png) |

Regenerate the public screenshots after material UIKit changes:

```sh
scripts/capture-swift-sample-screenshots.sh
```

The screenshot capture script is a visual QA companion to the simulator UI smoke tests. UI smoke proves the flows are operable; screenshots prove the public docs still show the current product.

## Swift Sample

Build from the package root:

```sh
xcodebuild -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj \
  -scheme SwiftSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run `SwiftSampleApp` in Xcode or install the built app on Simulator.

For a focused simulator UI smoke run of the Swift sample:

```sh
scripts/validate-swift-sample-ui-smoke.sh
```

For a focused simulator UI smoke run of the Objective-C sample:

```sh
scripts/validate-objc-sample-ui-smoke.sh
```

The smoke tests launch each sample app in a native-log-only UI automation mode, write native ConsoleDock entries containing sample tokens, open the bundled console, and verify the diagnostics header, entries table, visible redaction, structured Logs search, level filtering, Logs jump controls, log detail, copy controls, marker creation, Timeline rows and detail navigation, issue-report share action availability, issue-report copy action availability, Local Session Archive menu actions, Swift archive save/detail/delete flow, pause/resume, clear refresh, Debug Actions, Actions search, parameterized Debug Actions, disabled/destructive action metadata, confirmation prompts, App Context tab refresh, and close controls through stable accessibility identifiers. Unit and formatter tests cover local structured query parsing, local Session Timeline building, local action execution history, session-only recent parameter values, temporary issue-report file generation, reproduction timeline report output, and Local Session Archive persistence boundaries.

Manual check:

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap `Hide Floating Button`, then `Show Floating Button`, and confirm the panel can still be opened through the sample button.
4. Tap `Log diagnostics`, `App logger sink`, `ConsoleDock.info`, `ConsoleDock.error`, `ConsoleDock.fault`, `print stdout`, `printf stdout`, `fprintf stderr`, and `NSLog`.
5. Confirm entries appear in the ConsoleDock panel.
6. Confirm `App logger sink` writes through the app's logger forwarder sink, preserving the original app logger output while adding a native ConsoleDock entry.
7. Confirm the diagnostics header reports running state, entry count, stdout/stderr state, limits, and redacted/truncated/partial counts.
8. Confirm generated `token=...` values are stored as `token=<redacted>`.
9. Search for `stderr`, `token`, or `level:error` and confirm the visible list filters without changing stored entries.
10. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
11. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
12. Use `Jump` to move to the latest visible log and first/previous/next visible error/fault without changing filters.
13. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
14. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
15. Tap a visible log row and confirm the detail screen shows the full redacted message, metadata flags, and copy buttons.
16. Tap `Mark`, enter a short reproduction note, and confirm a `[marker]` entry appears under `Logs`.
17. Switch to `Timeline` and confirm the marker plus retained error/fault entries appear in timestamp order; tap a marker or error/fault row and confirm it opens log detail.
18. Tap the share button and choose visible logs, all logs, issue report, or copy issue report; confirm share actions open the system share sheet and the copy action is available for the same local report text. Issue report shares use a temporary local `.txt` item.
19. From the same share menu, choose `Save Session Archive`, open `Saved Session Archives`, open the saved row, confirm copy/share/delete controls exist, then delete it and confirm the empty state returns.
20. Switch to `Actions`, search for `Smoke`, run `Generate Smoke Logs`, and confirm new action start/completion plus sample error entries appear under `Logs`.
21. Switch to `Timeline`, confirm the Debug Action execution and sample error entry appear, then open the action detail and confirm copy is available.
22. Run `Open Order`, enter an order id, keep the provided numeric, boolean, and environment defaults, and confirm the parameterized action writes a log containing the order id. Open the same action again and confirm the form starts with the recent values from the current process session.
23. Confirm `Disabled Placeholder` appears disabled and does not need to be triggered for the smoke path.
24. Run the `Add Marker` action and confirm a sample marker entry appears under `Logs`.
25. Run the `Clear Entries` action and confirm it is marked destructive and asks before executing.
26. Switch to `Context`, refresh, and confirm the sample language, UI smoke mode, running state, and retained entry count are visible.
27. Tap `Clear` in the panel and confirm the list and diagnostics header refresh.
28. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
29. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

Expected sources:

- `ConsoleDock.info`, `ConsoleDock.error`, and `ConsoleDock.fault`: `native`
- `Log diagnostics`: `native`
- `App logger sink`: `native` plus the original logger's stdout output
- `print` and `printf`: `stdout`
- `fprintf(stderr)`: `stderr`
- many `NSLog` messages: `stderr`

## Objective-C Sample

Build from the package root:

```sh
xcodebuild -project Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj \
  -scheme ObjCSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run `ObjCSampleApp` in Xcode or install the built app on Simulator.

Manual check:

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap `Hide Floating Button`, then `Show Floating Button`, and confirm the panel can still be opened through the sample button.
4. Tap `Log diagnostics`, `App logger sink`, the native `CDKConsoleDock`, C stdio, direct descriptor write, and `NSLog` buttons.
5. Confirm entries appear in the ConsoleDock panel.
6. Confirm the diagnostics header reports running state, entry count, stdout/stderr state, limits, and redacted/truncated/partial counts.
7. Confirm generated `token=...` values are stored as `token=<redacted>`.
8. Search for `stderr`, `token`, or `level:error` and confirm the visible list filters without changing stored entries.
9. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
10. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
11. Use `Jump` to move to the latest visible log and first/previous/next visible error/fault without changing filters.
12. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
13. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
14. Tap a visible log row and confirm the detail screen shows the full redacted message, metadata flags, and copy buttons.
15. Tap `Mark`, enter a short reproduction note, and confirm a `[marker]` entry appears under `Logs`.
16. Switch to `Timeline` and confirm the marker plus retained error/fault entries appear in timestamp order; tap a marker or error/fault row and confirm it opens log detail.
17. Tap the share button and confirm visible logs, all logs, issue report, copy issue report, `Save Session Archive`, and `Saved Session Archives` are available. Issue report shares use a temporary local `.txt` item.
18. Switch to `Actions`, search for `Smoke`, run `Generate Smoke Logs`, and confirm new action start/completion plus sample error entries appear under `Logs`.
19. Switch to `Timeline`, confirm the Debug Action execution and sample error entry appear, then open the action detail and confirm copy is available.
20. Run `Open Order`, enter an order id, keep the provided numeric, boolean, and environment defaults, and confirm the parameterized action writes a log containing the order id. Open the same action again and confirm the form starts with the recent values from the current process session.
21. Confirm `Disabled Placeholder` appears disabled and does not need to be triggered for the smoke path.
22. Run the `Add Marker` action and confirm a sample marker entry appears under `Logs`.
23. Run the `Clear Entries` action and confirm it is marked destructive and asks before executing.
24. Switch to `Context`, refresh, and confirm the sample language, UI smoke mode, running state, and retained entry count are visible.
25. Tap `Clear` in the panel and confirm the list and diagnostics header refresh.
26. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
27. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

Expected sources:

- `CDKConsoleDock` APIs: `native`
- `Log diagnostics`: `native`
- `App logger sink`: `native` plus the original logger's `NSLog` stderr output
- `printf` and `write(STDOUT_FILENO, ...)`: `stdout`
- `fprintf(stderr)`, `write(STDERR_FILENO, ...)`, and many `NSLog` messages: `stderr`

## Capture Notes

Do not use `simctl launch --stdout` or `simctl launch --stderr` as the primary validation path for ConsoleDock's own stdout/stderr capture. Those flags also modify the app process descriptors and can hide descriptor-restore issues.

Run from Xcode or launch normally through Simulator when checking integration behavior.

Swift `Logger`, `os_log`, and Apple unified logging are not validated by these samples because ConsoleDock does not promise complete zero-intrusion capture of those systems.

Search, source filtering, and level filtering only affect the visible list and the share sheet's exported snapshot. ConsoleDock does not delete or mutate stored entries when a filter is active.

Pause/resume only affects live UI follow. ConsoleDock continues capturing and storing entries while the panel is paused.

Tapping a row opens the log detail screen. Copy actions on that screen copy only that visible, already-redacted message or the selected entry with its metadata. They do not copy hidden filtered entries.

The share sheet can export the current visible in-memory ConsoleDock entries, all currently retained entries, or a local issue report with session metadata, diagnostics, App Context, a reproduction timeline, markers, and all currently retained redacted logs. `Share Issue Report` creates a temporary local `.txt` item only for the user-initiated system share sheet. `Copy Issue Report` copies the same local report text to the pasteboard. `Save Session Archive` explicitly persists a bounded, already-redacted issue-report snapshot until deleted. ConsoleDock does not write raw log files by default, does not persist logs by default, and does not upload logs.

Markers are normal native info entries with a stable `[marker]` prefix. They are useful as part of the Session Timeline and issue-report reproduction timeline, but they are not a separate persistent note system.

Debug Actions are local, app-registered shortcuts. ConsoleDock does not discover pages, control routing, bypass app permissions, or receive remote commands.

Actions search is local UI filtering by id, title, group, and detail. It does not execute actions, persist queries, or change action registration.

Parameterized Debug Actions are local forms for small tester inputs. The bundled form can reuse recent values within the current process session only. ConsoleDock does not persist parameter values across restarts, keep async action state, or turn actions into a remote automation layer.

App Context is an app-provided snapshot displayed in the bundled Context tab and included in issue reports. ConsoleDock reads it on demand and does not persist, upload, redact, or automatically refresh it in the background.

Diagnostics describe ConsoleDock's active configuration and currently retained store counts only. They do not validate complete Swift `Logger`, `os_log`, or Apple unified logging capture.
