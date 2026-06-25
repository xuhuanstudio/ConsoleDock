# Test Session Reports

Mark important reproduction steps and share a local issue report from the bundled console.

## Overview

Test Session Reports help a tester turn an on-device debugging session into a useful issue report without connecting Xcode.

ConsoleDock does this with three local pieces:

- ``ConsoleDock/sessionMetadata`` returns app, process, OS, device, locale, time zone, session, and generation context.
- ``ConsoleDock/mark(_:)`` writes a native info entry with a stable `[marker]` prefix.
- The bundled UIKit console offers `Mark` and `Share Issue Report` actions.

Issue reports are generated locally through the system share sheet. They include session metadata, diagnostics, a marker index, and all currently retained redacted logs. ConsoleDock does not persist reports by default, upload them, or create remote issues automatically.

## Add Markers

Use markers when a tester or debug action reaches an important step in a reproduction.

```swift
ConsoleDock.mark("Opened checkout")
ConsoleDock.mark("Submitted payment form")
```

Markers are normal native info entries. They pass through the same redaction, truncation, detail, search, copy, and share behavior as other entries.

## Read Session Metadata

Use metadata when a custom debug surface or app-specific export needs context for the current local session.

```swift
let metadata = ConsoleDock.sessionMetadata
print(metadata.sessionIdentifier)
print(metadata.appVersion ?? "unknown")
```

The metadata snapshot is local process context. It is not a persistent user identity and should not be treated as a privacy review substitute for exported logs.

## Share From The Bundled Console

Open the ConsoleDock panel, tap the share button, and choose `Share Issue Report`.

The report shares all currently retained entries, not only the visible filtered list, so a tester does not accidentally omit surrounding context. `Share Visible Logs` and `Share All Logs` remain available for smaller snapshots.
