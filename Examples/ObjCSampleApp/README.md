# ConsoleDock Objective-C Sample App

Minimal UIKit sample app for validating Objective-C integration.

The sample imports both package products:

- `ConsoleDock`: exposes `CDKConsoleDockUIKit` for starting/stopping ConsoleDock with the bundled UIKit floating console.
- `ConsoleDockCore`: exposes `CDKConsoleDock`, `CDKConfiguration`, entries, notifications, and native logging APIs.

The app starts ConsoleDock on launch, enables stdout/stderr capture, shows the floating `CD` button, and provides buttons that generate:

- Native `CDKConsoleDock` info/error/fault entries
- Runtime diagnostics through `CDKDiagnostics`
- App-specific logger sink forwarding
- C `printf` stdout
- C `fprintf(stderr)` stderr
- Direct `write(STDOUT_FILENO, ...)`
- Direct `write(STDERR_FILENO, ...)`
- `NSLog`

Messages intentionally include `token=...` values so the console can show the core redaction path in action.

## Build

From the package root:

```sh
xcodebuild -project Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj \
  -scheme ObjCSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Run

Open `Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj` in Xcode and run the `ObjCSampleApp` scheme on an iOS Simulator.

The project uses a local Swift package reference to the repository root, so changes to `Sources/` are picked up by the sample without publishing a package release.

## Automated Smoke Check

From the package root:

```sh
scripts/validate-objc-sample-ui-smoke.sh
```

The script chooses an available iPhone simulator unless `CONSOLEDOCK_UI_SMOKE_DESTINATION` is set. It launches the app with `--consoledock-ui-smoke` so the test focuses on a native `CDKConsoleDock` entry, redaction, the bundled panel, selected-row tap, pause/resume, clear refresh, and close behavior without stdout/stderr capture descriptor noise.

## Manual Check

For the full shared checklist, see [Sample app walkthrough](../../docs/sample-app-walkthrough.md).

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap each logging button, including `Log diagnostics` and `App logger sink`.
4. Confirm entries appear in the console, diagnostics are readable, and `token=...` values are displayed as `<redacted>`.
5. Tap `Clear` in the console or `Clear ConsoleDock Entries` in the sample to verify live refresh.

When testing ConsoleDock's own stdout/stderr capture, avoid using `simctl launch --stdout` or `simctl launch --stderr` as the primary validation path because those flags also modify the app process descriptors. Running from Xcode or launching normally through Simulator gives a closer app-integration signal.
