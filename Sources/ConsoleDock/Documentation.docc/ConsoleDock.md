# ``ConsoleDock``

Inspect debug logs inside an iOS app without attaching Xcode.

## Overview

ConsoleDock is a debug and test SDK for iOS apps. It stores redacted log entries in local memory with stable session identifiers and line-processing flags, displays them in a bundled UIKit console, and keeps Release builds disabled by default.

Use ConsoleDock when testers need to inspect useful app logs on a device or Simulator without a live Xcode session. It can capture supported stdout and stderr writes from the app process, and its explicit native logging API is the most reliable way to send messages into the in-app console.

For existing app loggers, add ``ConsoleDock/LogForwarder`` in the logger's sink or appender so old call sites keep their current `AppLog` API while ConsoleDock receives the same app-authored messages.

ConsoleDock is not a full replacement for Xcode Console or Apple unified logging. It does not promise complete zero-intrusion capture of Swift `Logger`, `os_log`, system logs, other-process logs, debugger output, LLDB expressions, or sanitizer diagnostics.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:LoggingBoundaries>
- <doc:ExistingLoggerMigration>
- <doc:IntegrationDiagnostics>
- <doc:DebugActions>
- <doc:AppContext>
- <doc:TestSessionReports>
- <doc:SessionTimeline>
- <doc:LocalSessionArchive>
- <doc:SupportReports>
- <doc:DailyDebugUsability>
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
- ``ConsoleDock/LogForwarder``

### Reading Entries

- ``ConsoleDock/entries``
- ``ConsoleDock/entriesDidChangeNotification``
- ``ConsoleDock/clear()``
- ``ConsoleDock/issueReportText()``
- ``ConsoleDock/supportReport(options:)``
- ``ConsoleDock/makeTemporarySupportReportFile(options:)``
- ``ConsoleDock/integrationDiagnosisText()``
- ``ConsoleDock/saveSessionArchive(note:)``
- ``ConsoleDock/sessionArchives()``
- ``ConsoleDock/deleteSessionArchive(id:)``
- ``ConsoleDock/clearSessionArchives()``
- ``ConsoleDock/SessionArchive``
- ``ConsoleDock/SupportReport``
- ``ConsoleDock/SupportReportOptions``
- ``ConsoleDock/SupportReportTimeRange``
- ``ConsoleDock/LogEntry``
- ``ConsoleDock/LogSource``

### Test Session Reports

- ``ConsoleDock/sessionMetadata``
- ``ConsoleDock/SessionMetadata``
- ``ConsoleDock/mark(_:)``
- ``ConsoleDock/appContext``
- ``ConsoleDock/AppContextSection``
- ``ConsoleDock/AppContextItem``
- ``ConsoleDock/setAppContextProvider(_:)``
- ``ConsoleDock/clearAppContextProvider()``
- ``ConsoleDock/actionExecutionHistory``
- ``ConsoleDock/DebugActionExecution``
- ``ConsoleDock/DebugActionExecutionOutcome``
- ``ConsoleDock/clearActionExecutionHistory()``

### Showing The UIKit Console

- ``ConsoleDock/showConsole()``
- ``ConsoleDock/hideConsole()``
- ``ConsoleDock/showFloatingButton()``
- ``ConsoleDock/hideFloatingButton()``
- ``ConsoleDock/FloatingButtonPosition``

### Registering Debug Actions

- ``ConsoleDock/registerAction(id:title:group:detail:requiresConfirmation:isEnabled:style:handler:)``
- ``ConsoleDock/registerAction(id:title:group:detail:requiresConfirmation:isEnabled:style:parameters:handler:)``
- ``ConsoleDock/unregisterAction(id:)``
- ``ConsoleDock/removeAllActions()``
- ``ConsoleDock/DebugActionStyle``
- ``ConsoleDock/DebugActionExecution``
- ``ConsoleDock/DebugActionExecutionOutcome``
- ``ConsoleDock/DebugActionChoice``
- ``ConsoleDock/DebugActionParameter``
- ``ConsoleDock/DebugActionParameterValue``
- ``ConsoleDock/DebugActionParameters``
