# Test Session Reports

Mark important reproduction steps and share a local issue report from the bundled console.

## Overview

Test Session Reports help a tester turn an on-device debugging session into a useful issue report without connecting Xcode.

ConsoleDock does this with three local pieces:

- ``ConsoleDock/sessionMetadata`` returns app, process, OS, device, locale, time zone, session, and generation context.
- ``ConsoleDock/mark(_:)`` writes a native info entry with a stable `[marker]` prefix.
- ``ConsoleDock/appContext`` returns app-provided local context when the host app registers a provider.
- ``ConsoleDock/actionExecutionHistory`` returns local Debug Action outcomes for the current process session.
- The bundled UIKit console offers `Mark`, `Timeline`, `Share Issue Report`, `Copy Issue Report`, and explicit Local Session Archive actions.

Issue reports are generated locally through the system share sheet, copied locally through the pasteboard action, saved explicitly as a bounded Local Session Archive, or read as text through ``ConsoleDock/issueReportText()``. They include session metadata, diagnostics, app context, a reproduction timeline, a marker index, and all currently retained redacted logs. ConsoleDock does not persist reports by default, upload them, or create remote issues automatically.

## Add Markers

Use markers when a tester or debug action reaches an important step in a reproduction.

```swift
ConsoleDock.mark("Opened checkout")
ConsoleDock.mark("Submitted payment form")
```

Markers are normal native info entries. They pass through the same redaction, truncation, detail, search, copy, and share behavior as other entries.

## Review The Reproduction Timeline

The bundled `Timeline` tab and the issue report's reproduction timeline combine three local sources in timestamp order:

- marker entries created through ``ConsoleDock/mark(_:)`` or the bundled `Mark` action;
- Debug Action executions from ``ConsoleDock/actionExecutionHistory``;
- retained error and fault log entries.

The full `Logs` section still includes all currently retained redacted entries. Timeline rows are a summary meant to help a tester or developer scan the likely reproduction sequence first. See <doc:SessionTimeline> for the bundled Timeline view.

## Read Session Metadata

Use metadata when a custom debug surface or app-specific export needs context for the current local session.

```swift
let metadata = ConsoleDock.sessionMetadata
print(metadata.sessionIdentifier)
print(metadata.appVersion ?? "unknown")
```

The metadata snapshot is local process context. It is not a persistent user identity and should not be treated as a privacy review substitute for exported logs.

## Add App Context

Register App Context when a useful issue report needs app-owned values that are not logs.

```swift
ConsoleDock.setAppContextProvider {
    [
        .init(title: "App", items: [
            .init(key: "Environment", value: "staging"),
            .init(key: "Current Screen", value: "Checkout")
        ])
    ]
}
```

The bundled `Context` tab reads the same provider. See <doc:AppContext> for details and Objective-C usage.

## Share From The Bundled Console

Open the ConsoleDock panel, tap the share button, and choose `Share Issue Report` or `Copy Issue Report`.

The report shares all currently retained entries, not only the visible filtered list, so a tester does not accidentally omit surrounding context. `Share Issue Report` creates a temporary local `.txt` item for the user-initiated system share sheet. `Copy Issue Report` copies the same report text to the pasteboard. `Share Visible Logs` and `Share All Logs` remain available for smaller snapshots.

## Save A Local Archive

Use Local Session Archive when a tester needs to keep a bounded report snapshot across an app restart.

```swift
let archive = try ConsoleDock.saveSessionArchive(note: "Checkout smoke test")
let archives = try ConsoleDock.sessionArchives()
try ConsoleDock.deleteSessionArchive(id: archive.id)
```

The bundled Logs share menu also provides `Save Session Archive` and `Saved Session Archives`. Saved archives contain already-redacted issue-report text, persist locally until deleted, and do not upload or create remote issues. See <doc:LocalSessionArchive>.
