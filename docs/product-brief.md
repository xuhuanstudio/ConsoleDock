# ConsoleDock Product Brief

## Optimized Goal

Build a reusable iOS debug SDK that testers can integrate into an app to view runtime logs directly on device, reducing the need to connect Xcode for basic log inspection.

## Recommended Product Shape

ConsoleDock should be distributed as an SDK/library, not as a copy-pasted source folder.

Distribution policy:

1. Swift Package Manager as the canonical public release channel.
2. Swift Package Index and hosted DocC as discovery and documentation surfaces.
3. CocoaPods and XCFramework are demand-driven compatibility evaluations, not active release targets.

See [Distribution strategy](distribution-strategy.md) for the current channel policy. ConsoleDock should not claim CocoaPods or XCFramework support until those paths are implemented, validated, and documented.

## Capability Tiers

### Base Mode

One-line startup integration:

```swift
import ConsoleDock

ConsoleDock.start()
```

Expected capture:

- Swift `print`
- C `printf`
- writes to stdout/stderr
- many `NSLog` outputs

### Adapter Mode

Integrate with existing logger systems by adding a sink/appender/logger target.

Examples:

- CocoaLumberjack
- SwiftyBeaver
- XCGLogger
- app-specific custom loggers

### Native Mode

Use ConsoleDock's explicit API for the most reliable logs:

```swift
ConsoleDock.info("Login succeeded")
```

ConsoleDock's in-app console reads from ConsoleDock's internal in-memory store. The current implementation does not write to Apple unified logging or read Apple unified logging back from inside the app. If an app also needs Apple unified logging output, that output should remain in the app's existing logger while the same already-formatted message is forwarded to ConsoleDock.

### Debug Actions Mode

Expose app-owned local test shortcuts inside the ConsoleDock panel:

```swift
ConsoleDock.registerAction(id: "open.checkout", title: "Open Checkout") {
    AppRouter.shared.openCheckout()
}
```

Actions can optionally ask for small local parameters such as an order id, environment choice, quantity, or boolean flag before they run. The bundled form can reuse recent values within the current process session, but ConsoleDock should not persist parameter values across app restarts by default.

ConsoleDock only displays and triggers actions that the app registers. It should not discover routes, control app navigation automatically, bypass business permissions, or accept remote commands.

### App Context Mode

Expose app-owned local diagnostics that help interpret logs and issue reports:

```swift
ConsoleDock.setAppContextProvider {
    [
        .init(title: "App", items: [
            .init(key: "Environment", value: "staging")
        ])
    ]
}
```

Context appears in the bundled Context tab and issue reports. It should be read on demand, kept local, and treated as app-authored diagnostic text rather than a privacy filter.

### Test Session Reports Mode

Let testers mark important reproduction steps and share a local issue report from the bundled panel:

```swift
ConsoleDock.mark("Started checkout reproduction")
```

The report should contain session metadata, diagnostics, App Context, a reproduction timeline, a marker index, and currently retained redacted logs. The reproduction timeline should summarize markers, Debug Action executions, and retained error/fault logs before the full log section. It should be generated only through a user-initiated local share action. ConsoleDock should not persist reports by default, upload them, or create remote issues automatically.

### Session Timeline Mode

Show the same current-session triage signals inside the bundled panel before a tester exports a report. The Timeline view should aggregate markers, Debug Action executions, and retained error/fault logs in timestamp order, with detail navigation back to the relevant log or action execution.

Timeline is a local UI summary. It should not become persistent history, telemetry, route discovery, remote commands, or a replacement for the full Logs list.

### Local Session Archive Mode

Let testers explicitly save a bounded issue-report snapshot for later local review:

```swift
try ConsoleDock.saveSessionArchive(note: "Checkout smoke test")
```

Archives should persist already-redacted report text locally until deleted. They should not become raw log persistence, background telemetry, crash-final recovery, remote upload, or a searchable log database.

### Support Report Mode

Let app-owned feedback or support flows request a bounded time-range report on demand:

```swift
let report = ConsoleDock.supportReport(options: .last10Minutes)
```

Support Reports should read from currently retained, already-redacted in-memory/session data. They may cover all retained data, the last 5/10/30/60 minutes, or an explicit date range. The 60-minute preset is useful for longer manual flows, but it must not imply continuous file logging or longer retention than the configured in-memory store.

The bundled UIKit panel may expose an on-demand composer for these same options, summary metadata, preview, copy, and user-initiated sharing. It should remain an entry in the existing export/report flow rather than becoming a separate telemetry or feedback platform.

The host app owns consent, upload, issue creation, cleanup, and privacy review. ConsoleDock should not send network requests, collect analytics, run a background uploader, or create remote tickets.

## Non-Goals

- Do not try to replace Xcode debugger features.
- Do not promise complete capture of Apple unified logging.
- Do not read or expose logs from other processes.
- Do not encourage enabling debug tooling in production builds without safeguards.
- Do not turn Debug Actions into a remote command system or automatic route discovery layer.
- Do not turn issue reports into default persistence, remote upload, or automatic issue creation.
- Do not turn Session Timeline into default persistent history or telemetry.
- Do not turn Local Session Archive into raw log persistence, crash reporting, remote upload, or a logging database.
- Do not turn Support Reports into analytics, telemetry, background upload, remote issue creation, or continuous file logging.
- Do not treat App Context as automatic redaction, route discovery, persistence, or remote telemetry.

## Naming Decision

Chosen name: `ConsoleDock`

Reasoning:

- Modern and platform-neutral without implying Android support directly.
- Avoids Apple/iOS/Xcode trademark-heavy naming.
- Avoids confusion with the existing `iConsole` project.
- Works as a package name and product brand.
