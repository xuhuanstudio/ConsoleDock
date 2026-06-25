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
- manual markers and local issue report sharing;
- `NSLog` output that reaches process stderr;
- redaction before storage;
- UIKit floating button, search, source and level filtering, pause/resume live follow, log detail, copy, panel refresh, share/export, actions, clear, stop, and restart behavior.

The bundled console and sample controls expose stable accessibility identifiers so future UI smoke tests can target behavior without relying on localized text. Key bundled console identifiers include `consoledock.dock-button`, `consoledock.mode-control`, `consoledock.search`, `consoledock.level-filter`, `consoledock.status`, `consoledock.entries-table`, `consoledock.actions-table`, `consoledock.mark`, `consoledock.marker-text`, `consoledock.add-marker`, and `consoledock.share-issue-report`. Sample app button identifiers use `swift-sample.<button-slug>` and `objc-sample.<button-slug>`.

![ConsoleDock Swift sample console](assets/swift-sample-console.png)

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

The smoke tests launch each sample app in a native-log-only UI automation mode, write native ConsoleDock entries containing sample tokens, open the bundled console, and verify the diagnostics header, entries table, visible redaction, search control rendering, level filtering, log detail, copy controls, marker creation, issue-report share action availability, pause/resume, clear refresh, Debug Actions, confirmation prompts, and close controls through stable accessibility identifiers.

Manual check:

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap `Log diagnostics`, `App logger sink`, `ConsoleDock.info`, `ConsoleDock.error`, `ConsoleDock.fault`, `print stdout`, `printf stdout`, `fprintf stderr`, and `NSLog`.
4. Confirm entries appear in the ConsoleDock panel.
5. Confirm the diagnostics header reports running state, entry count, stdout/stderr state, limits, and redacted/truncated/partial counts.
6. Confirm generated `token=...` values are stored as `token=<redacted>`.
7. Search for `stderr` or `token` and confirm the visible list filters without changing stored entries.
8. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
9. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
10. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
11. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
12. Tap a visible log row and confirm the detail screen shows the full redacted message, metadata flags, and copy buttons.
13. Tap `Mark`, enter a short reproduction note, and confirm a `[marker]` entry appears under `Logs`.
14. Tap the share button and choose visible logs, all logs, or issue report; confirm the system share sheet opens with a plain-text redacted snapshot and diagnostics.
15. Switch to `Actions`, run `Generate Smoke Logs`, and confirm new action start/completion plus sample error entries appear under `Logs`.
16. Run the `Add Marker` action and confirm a sample marker entry appears under `Logs`.
17. Run the `Clear Entries` action and confirm it asks before executing.
18. Tap `Clear` in the panel and confirm the list and diagnostics header refresh.
19. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
20. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

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
3. Tap `Log diagnostics`, `App logger sink`, the native `CDKConsoleDock`, C stdio, direct descriptor write, and `NSLog` buttons.
4. Confirm entries appear in the ConsoleDock panel.
5. Confirm the diagnostics header reports running state, entry count, stdout/stderr state, limits, and redacted/truncated/partial counts.
6. Confirm generated `token=...` values are stored as `token=<redacted>`.
7. Search for `stderr` or `token` and confirm the visible list filters without changing stored entries.
8. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
9. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
10. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
11. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
12. Tap a visible log row and confirm the detail screen shows the full redacted message, metadata flags, and copy buttons.
13. Tap `Mark`, enter a short reproduction note, and confirm a `[marker]` entry appears under `Logs`.
14. Tap the share button and choose visible logs, all logs, or issue report; confirm the system share sheet opens with a plain-text redacted snapshot and diagnostics.
15. Switch to `Actions`, run `Generate Smoke Logs`, and confirm new action start/completion plus sample error entries appear under `Logs`.
16. Run the `Add Marker` action and confirm a sample marker entry appears under `Logs`.
17. Run the `Clear Entries` action and confirm it asks before executing.
18. Tap `Clear` in the panel and confirm the list and diagnostics header refresh.
19. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
20. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

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

The share sheet can export the current visible in-memory ConsoleDock entries, all currently retained entries, or a local issue report with session metadata, diagnostics, markers, and all currently retained redacted logs. ConsoleDock does not write an export file by default, does not persist logs by default, and does not upload logs.

Markers are normal native info entries with a stable `[marker]` prefix. They are useful as a reproduction timeline, but they are not a separate persistent note system.

Debug Actions are local, app-registered shortcuts. ConsoleDock does not discover pages, control routing, bypass app permissions, or receive remote commands.

Diagnostics describe ConsoleDock's active configuration and currently retained store counts only. They do not validate complete Swift `Logger`, `os_log`, or Apple unified logging capture.
