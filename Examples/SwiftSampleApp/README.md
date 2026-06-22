# ConsoleDock Swift Sample App

Minimal UIKit sample app for validating local ConsoleDock package integration.

The sample starts ConsoleDock on launch, enables stdout/stderr capture, shows the UIKit floating `CD` button, and provides buttons that generate:

- Native ConsoleDock info/error/fault entries
- Runtime diagnostics through `ConsoleDock.diagnostics`
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

## Manual Check

For the full shared checklist, see [Sample app walkthrough](../../docs/sample-app-walkthrough.md).

1. Launch the app.
2. Tap `Show Console` or the floating `CD` button.
3. Tap each logging button, including `Log diagnostics`.
4. Confirm entries appear in the console, diagnostics are readable, and `token=...` values are displayed as `<redacted>`.
5. Tap `Clear` in the console or `Clear ConsoleDock Entries` in the sample to verify live refresh.

When testing ConsoleDock's own stdout/stderr capture, avoid using `simctl launch --stdout` or `simctl launch --stderr` as the primary validation path because those flags also modify the app process descriptors. Running from Xcode or launching normally through Simulator gives a closer app-integration signal.
