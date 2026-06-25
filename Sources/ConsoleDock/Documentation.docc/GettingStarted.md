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

## Read Or Clear Entries

Use ``ConsoleDock/entries`` for a snapshot, ``ConsoleDock/diagnostics`` for runtime state and store counts, and ``ConsoleDock/clear()`` to clear the local in-memory store.

```swift
let snapshot = ConsoleDock.entries
let diagnostics = ConsoleDock.diagnostics
ConsoleDock.clear()
```

Use ``ConsoleDock/entriesDidChangeNotification`` when building a custom debug surface that displays entries. Use ``ConsoleDock/diagnosticsDidChangeNotification`` when the surface also displays running state, capture configuration, or store counts. Notification handlers should dispatch to the main queue before touching UIKit.

Diagnostics report ConsoleDock's local runtime state only. They do not imply complete capture of Swift `Logger`, `os_log`, Apple unified logging, other-process logs, or debugger-only output.

## Add Debug Actions

Use Debug Actions when testers need an explicit local shortcut for a screen or scenario that is hard to reach through normal UI.

```swift
ConsoleDock.registerAction(
    id: "debug.simulate-payment-error",
    title: "Simulate Payment Error",
    group: "Scenario",
    detail: "Writes a payment error entry for testing."
) {
    ConsoleDock.error("Simulated payment failure")
}
```

The host app owns the behavior. ConsoleDock does not automatically discover pages, control routing, bypass app permissions, or receive remote commands. See <doc:DebugActions>.
