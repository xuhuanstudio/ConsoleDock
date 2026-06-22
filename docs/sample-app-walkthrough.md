# Sample App Walkthrough

ConsoleDock includes Swift and Objective-C UIKit sample apps that exercise the package through the same public integration paths real apps should use.

Use the samples to verify:

- Swift package integration;
- Objective-C imports and `CDK` APIs;
- stdout and stderr file-descriptor capture;
- explicit native logging APIs;
- `NSLog` output that reaches process stderr;
- redaction before storage;
- UIKit floating button, search, source and level filtering, pause/resume live follow, selected-entry copy, panel refresh, share/export, clear, stop, and restart behavior.

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

Manual check:

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap `ConsoleDock.info`, `ConsoleDock.error`, `ConsoleDock.fault`, `print stdout`, `printf stdout`, `fprintf stderr`, and `NSLog`.
4. Confirm entries appear in the ConsoleDock panel.
5. Confirm generated `token=...` values are stored as `token=<redacted>`.
6. Search for `stderr` or `token` and confirm the visible list filters without changing stored entries.
7. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
8. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
9. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
10. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
11. Tap a visible log row and confirm the selected redacted entry is copied to the clipboard.
12. Tap the share button and confirm the system share sheet opens with a plain-text redacted log snapshot for the visible entries.
13. Tap `Clear` in the panel and confirm the list refreshes.
14. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
15. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

Expected sources:

- `ConsoleDock.info`, `ConsoleDock.error`, and `ConsoleDock.fault`: `native`
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
3. Tap the native `CDKConsoleDock`, C stdio, direct descriptor write, and `NSLog` buttons.
4. Confirm entries appear in the ConsoleDock panel.
5. Confirm generated `token=...` values are stored as `token=<redacted>`.
6. Search for `stderr` or `token` and confirm the visible list filters without changing stored entries.
7. Change the source scope to `stdout` or `stderr` and confirm only matching entries remain visible.
8. Change the level scope to `Info` or `Error` and confirm only matching entries remain visible.
9. Tap the pause button, generate another message from the sample, and confirm the visible list does not auto-refresh.
10. Tap the play/resume button and confirm the panel catches up to the latest stored entries.
11. Tap a visible log row and confirm the selected redacted entry is copied to the clipboard.
12. Tap the share button and confirm the system share sheet opens with a plain-text redacted log snapshot for the visible entries.
13. Tap `Clear` in the panel and confirm the list refreshes.
14. Tap `Stop ConsoleDock`, generate another message, and confirm it is not stored.
15. Tap `Start ConsoleDock`, generate another message, and confirm entries resume.

Expected sources:

- `CDKConsoleDock` APIs: `native`
- `printf` and `write(STDOUT_FILENO, ...)`: `stdout`
- `fprintf(stderr)`, `write(STDERR_FILENO, ...)`, and many `NSLog` messages: `stderr`

## Capture Notes

Do not use `simctl launch --stdout` or `simctl launch --stderr` as the primary validation path for ConsoleDock's own stdout/stderr capture. Those flags also modify the app process descriptors and can hide descriptor-restore issues.

Run from Xcode or launch normally through Simulator when checking integration behavior.

Swift `Logger`, `os_log`, and Apple unified logging are not validated by these samples because ConsoleDock does not promise complete zero-intrusion capture of those systems.

Search, source filtering, and level filtering only affect the visible list and the share sheet's exported snapshot. ConsoleDock does not delete or mutate stored entries when a filter is active.

Pause/resume only affects live UI follow. ConsoleDock continues capturing and storing entries while the panel is paused.

Tapping a row copies only that visible, already-redacted entry. It does not copy hidden filtered entries.

The share sheet exports the current visible in-memory ConsoleDock entries only. ConsoleDock does not write an export file by default, does not persist logs by default, and does not upload logs.
