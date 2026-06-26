# Getting Started

Start ConsoleDock in a Debug build and write logs through the explicit API or supported stdout/stderr paths.

## Add The Package

Add ConsoleDock as a Swift Package dependency, then depend on the `ConsoleDock` product for Swift API access and the bundled UIKit console.

For Objective-C-compatible core APIs without the Swift facade, depend on `ConsoleDockCore`.

## Start ConsoleDock

Call ``ConsoleDock/start(configuration:)`` during debug startup, before generating logs you expect ConsoleDock to capture.

```swift
import ConsoleDock

@discardableResult
func startDebugConsole() -> ConsoleDock.StartResult {
    ConsoleDock.start()
}
```

The default configuration:

- captures supported stdout and stderr writes from the current app process;
- installs the floating UIKit `CD` button when UIKit is available;
- starts the floating button at bottom trailing unless configured otherwise;
- redacts obvious secrets before storage;
- truncates very long messages;
- stores entries in local memory only;
- returns `.disabled` in Release builds unless the explicit Release opt-in gate is enabled.

## Write Native Entries

The explicit API is the most reliable way to get app-authored logs into the panel.

```swift
ConsoleDock.info("Login succeeded")
ConsoleDock.warning("Retrying request")
ConsoleDock.error("Request failed")
ConsoleDock.fault("Invariant failed")
```

## Forward An Existing Logger

When an app already has a central logger, add ConsoleDock as one destination inside that logger instead of changing every call site.

```swift
enum AppLog {
    private static let consoleDock = ConsoleDock.LogForwarder(category: "AppLog")

    static func info(_ message: String) {
        print("[info] \(message)")
        consoleDock.info(message)
    }
}
```

This is an explicit app-owned forward. It does not make ConsoleDock read Swift `Logger`, `os_log`, or Apple unified logging back from the system.

## Customize Redaction

ConsoleDock runs its default redactor first. Add a custom redactor for app-specific fields.

```swift
let configuration = ConsoleDock.Configuration(redactor: { message in
    message.replacingOccurrences(
        of: "tenant_id=internal",
        with: "tenant_id=<redacted>"
    )
})

ConsoleDock.start(configuration: configuration)
```

## Configure The Floating Trigger

When the default button position covers app controls, choose another starting corner.

```swift
let configuration = ConsoleDock.Configuration(
    floatingButtonPosition: .bottomLeading
)

ConsoleDock.start(configuration: configuration)
```

Apps can also hide or show the bundled trigger at runtime without stopping logging.

```swift
ConsoleDock.hideFloatingButton()
ConsoleDock.showFloatingButton()
```

Use ``ConsoleDock/showConsole()`` when the app provides its own debug entry point. See <doc:DailyDebugUsability>.

## Read Or Clear Entries

Use ``ConsoleDock/entries`` for a snapshot, ``ConsoleDock/diagnostics`` for runtime state and store counts, and ``ConsoleDock/clear()`` to clear the local in-memory store.

```swift
let snapshot = ConsoleDock.entries
let diagnostics = ConsoleDock.diagnostics
ConsoleDock.clear()
```

Use ``ConsoleDock/entriesDidChangeNotification`` when building a custom debug surface that displays entries. Use ``ConsoleDock/diagnosticsDidChangeNotification`` when the surface also displays running state, capture configuration, or store counts. Notification handlers should dispatch to the main queue before touching UIKit.

Diagnostics report ConsoleDock's local runtime state only. They do not imply complete capture of Swift `Logger`, `os_log`, Apple unified logging, other-process logs, or debugger-only output.

Use ``ConsoleDock/integrationDiagnosisText()`` when expected logs or debug surface data do not appear. The generated local text summarizes running state, capture configuration, source and level counts, Debug Actions, App Context, Local Session Archives, and setup recommendations.

## Add Debug Actions

Use Debug Actions when testers need an explicit local shortcut for a screen or scenario that is hard to reach through normal UI.

```swift
ConsoleDock.registerAction(
    id: "debug.simulate-payment-error",
    title: "Simulate Payment Error",
    group: "Scenario",
    detail: "Writes a payment error entry for testing.",
    isEnabled: true,
    style: .normal
) {
    ConsoleDock.error("Simulated payment failure")
}
```

The host app owns the behavior. ConsoleDock does not automatically discover pages, control routing, bypass app permissions, or receive remote commands. See <doc:DebugActions>.

When a local shortcut needs tester input, register a parameterized Debug Action:

```swift
ConsoleDock.registerAction(
    id: "open.order",
    title: "Open Order",
    parameters: [
        .string(id: "orderId", title: "Order ID", isRequired: true)
    ]
) { values in
    AppRouter.shared.openOrder(id: values.string("orderId") ?? "")
}
```

ConsoleDock collects parameters locally in the bundled Actions tab and does not persist the submitted values.

## Mark A Test Session

Use ``ConsoleDock/mark(_:)`` to add a reproduction timeline entry from app code or a Debug Action.

```swift
ConsoleDock.mark("Opened checkout")
```

The bundled UIKit console also exposes a `Mark` action, a `Timeline` tab, plus `Share Issue Report` and `Copy Issue Report` options. Issue reports are local, user-initiated plain-text exports containing session metadata, diagnostics, app context, a reproduction timeline, markers, and currently retained redacted logs. ConsoleDock does not upload them or create remote issues automatically. See <doc:TestSessionReports> and <doc:SessionTimeline>.

Use Local Session Archive when a tester needs to reopen the current issue report after an app restart:

```swift
let archive = try ConsoleDock.saveSessionArchive(note: "Checkout smoke test")
let archives = try ConsoleDock.sessionArchives()
try ConsoleDock.deleteSessionArchive(id: archive.id)
```

Archives are explicit, bounded local report snapshots, not automatic raw-log persistence. See <doc:LocalSessionArchive>.

Use Support Reports when an app-owned feedback or support flow needs a bounded report for a time window:

```swift
let report = ConsoleDock.supportReport(options: .last10Minutes)
let fileURL = try ConsoleDock.makeTemporarySupportReportFile(options: .last60Minutes)
```

Support Reports are generated on demand from currently retained, already-redacted data. They are not analytics, background logging, or automatic upload. See <doc:SupportReports>.

Use App Context for app-owned values that help explain a local report:

```swift
ConsoleDock.setAppContextProvider {
    [
        .init(title: "App", items: [
            .init(key: "Environment", value: "staging")
        ])
    ]
}
```

The same snapshot appears in the bundled `Context` tab. See <doc:AppContext>.
