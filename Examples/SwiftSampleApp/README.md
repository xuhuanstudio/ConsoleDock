# ConsoleDock Swift Sample App

Minimal UIKit sample app for validating local ConsoleDock package integration.

The sample starts ConsoleDock on launch, enables stdout/stderr capture, shows the UIKit floating `CD` button from a non-default corner, and provides buttons that generate:

- Native ConsoleDock info/error/fault entries
- Runtime diagnostics through `ConsoleDock.diagnostics`
- Debug Actions registered through `ConsoleDock.registerAction`
- Parameterized Debug Actions for small local test inputs
- Session-only recent parameter reuse and local action execution history
- App Context snapshots for the bundled Context tab and issue reports
- Session Timeline rows for markers, Debug Actions, and retained error/fault logs
- Local Session Archive save/review/delete flows
- Floating trigger controls through `ConsoleDock.showFloatingButton()` and `ConsoleDock.hideFloatingButton()`
- Manual markers through `ConsoleDock.mark`
- App-specific logger sink forwarding through `ConsoleDock.LogForwarder`
- Swift `print` stdout
- C `printf` stdout
- C `fprintf(stderr)` stderr
- `NSLog`

Messages intentionally include `token=...` values so the console can show the core redaction path in action.

## Build

From the package root:

```sh
xcodebuild -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj \
  -scheme SwiftSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Run

Open `Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj` in Xcode and run the `SwiftSampleApp` scheme on an iOS Simulator.

The project uses a local Swift package reference to the repository root, so changes to `Sources/` are picked up by the sample without publishing a package release.

## Automated Smoke Check

From the package root:

```sh
scripts/validate-swift-sample-ui-smoke.sh
```

The script chooses an available iPhone simulator unless `CONSOLEDOCK_UI_SMOKE_DESTINATION` is set. It launches the app with `--consoledock-ui-smoke` so the test focuses on native ConsoleDock entries, redaction, the bundled panel, structured Logs search, level filtering, Logs jump controls, log detail, markers, Timeline rows and detail navigation, issue report sharing, Local Session Archive save/detail/delete, Debug Actions, Actions search, parameterized Debug Actions, disabled/destructive action metadata, App Context tab refresh, pause/resume, clear refresh, and close behavior without stdout/stderr capture descriptor noise. Unit tests cover structured Logs query parsing, the session-only recent parameter values, local action execution history, Session Timeline building, reproduction timeline, temporary issue-report file output, and Local Session Archive persistence boundaries behind the sample flows.

## Manual Check

For the full shared checklist, see [Sample app walkthrough](../../docs/sample-app-walkthrough.md).

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap `Hide Floating Button`, then `Show Floating Button`, and confirm the console can still be opened from the sample button.
4. Tap each logging button, including `Log diagnostics` and `App logger sink`.
5. Confirm entries appear in the console, diagnostics are readable, and `token=...` values are displayed as `<redacted>`.
6. Search Logs with `level:error`, then use the Logs `Jump` menu to jump to the latest visible log and first/previous/next visible error.
7. Add a marker from the console and confirm the `[marker]` entry appears.
8. Switch to `Timeline` and confirm marker plus error/fault rows can open detail.
9. Open the share menu and confirm `Share Issue Report`, `Copy Issue Report`, `Save Session Archive`, and `Saved Session Archives` are available. `Share Issue Report` uses a temporary local `.txt` item.
10. Save a session archive, open it, confirm copy/share/delete controls are visible, then delete it.
11. Switch to `Actions`, search for `Smoke`, and confirm the smoke action remains executable.
12. Switch back to `Timeline` after running the smoke action and confirm action detail copy is available.
13. Run `Open Order` and confirm the parameterized action form accepts an order id, then open it again and confirm the current process session remembers the recent value.
14. Switch to `Context`, refresh, and confirm the sample App Context is visible.
15. Confirm the disabled placeholder and destructive clear action metadata are visible.
16. Tap `Clear` in the console or `Clear ConsoleDock Entries` in the sample to verify live refresh.

When testing ConsoleDock's own stdout/stderr capture, avoid using `simctl launch --stdout` or `simctl launch --stderr` as the primary validation path because those flags also modify the app process descriptors. Running from Xcode or launching normally through Simulator gives a closer app-integration signal.
