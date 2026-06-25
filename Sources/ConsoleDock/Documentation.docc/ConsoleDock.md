# ``ConsoleDock``

Inspect debug logs inside an iOS app without attaching Xcode.

## Overview

ConsoleDock is a debug and test SDK for iOS apps. It stores redacted log entries in local memory with stable session identifiers and line-processing flags, displays them in a bundled UIKit console, and keeps Release builds disabled by default.

Use ConsoleDock when testers need to inspect useful app logs on a device or Simulator without a live Xcode session. It can capture supported stdout and stderr writes from the app process, and its explicit native logging API is the most reliable way to send messages into the in-app console.

ConsoleDock is not a full replacement for Xcode Console or Apple unified logging. It does not promise complete zero-intrusion capture of Swift `Logger`, `os_log`, system logs, other-process logs, debugger output, LLDB expressions, or sanitizer diagnostics.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:LoggingBoundaries>
- <doc:ExistingLoggerMigration>
- <doc:IntegrationDiagnostics>
- <doc:DebugActions>
- <doc:PrivacyAndReleaseSafety>
- <doc:ObjectiveCIntegration>

### Starting And Stopping

- ``ConsoleDock/Configuration``
- ``ConsoleDock/start(configuration:)``
- ``ConsoleDock/stop()``
- ``ConsoleDock/isRunning``
- ``ConsoleDock/diagnostics``
- ``ConsoleDock/diagnosticsDidChangeNotification``
- ``ConsoleDock/Diagnostics``
- ``ConsoleDock/StartResult``
- ``ConsoleDock/StartFailure``

### Writing Native Entries

- ``ConsoleDock/debug(_:)``
- ``ConsoleDock/info(_:)``
- ``ConsoleDock/warning(_:)``
- ``ConsoleDock/error(_:)``
- ``ConsoleDock/fault(_:)``
- ``ConsoleDock/LogLevel``

### Reading Entries

- ``ConsoleDock/entries``
- ``ConsoleDock/entriesDidChangeNotification``
- ``ConsoleDock/clear()``
- ``ConsoleDock/LogEntry``
- ``ConsoleDock/LogSource``

### Showing The UIKit Console

- ``ConsoleDock/showConsole()``
- ``ConsoleDock/hideConsole()``

### Registering Debug Actions

- ``ConsoleDock/registerAction(id:title:group:detail:requiresConfirmation:handler:)``
- ``ConsoleDock/unregisterAction(id:)``
- ``ConsoleDock/removeAllActions()``
