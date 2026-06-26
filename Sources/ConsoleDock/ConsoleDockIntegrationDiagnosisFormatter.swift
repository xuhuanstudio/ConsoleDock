import Foundation

struct ConsoleDockIntegrationDiagnosisFormatter {
    struct Snapshot: Equatable {
        let generatedAt: Date
        let metadata: ConsoleDock.SessionMetadata
        let diagnostics: ConsoleDock.Diagnostics
        let entries: [ConsoleDock.LogEntry]
        let debugActions: [ConsoleDockDebugAction]
        let actionExecutions: [ConsoleDock.DebugActionExecution]
        let appContextProviderRegistered: Bool
        let appContext: [ConsoleDock.AppContextSection]
        let archiveState: ArchiveState
    }

    enum ArchiveState: Equatable {
        case available(count: Int)
        case unavailable(message: String)
    }

    struct SourceCounts: Equatable {
        var native = 0
        var stdout = 0
        var stderr = 0
    }

    struct LevelCounts: Equatable {
        var debug = 0
        var info = 0
        var warning = 0
        var error = 0
        var fault = 0
    }

    static func snapshot(
        generatedAt: Date = Date(),
        entries: [ConsoleDock.LogEntry]? = nil,
        metadata: ConsoleDock.SessionMetadata? = nil,
        diagnostics: ConsoleDock.Diagnostics? = nil,
        appContext: [ConsoleDock.AppContextSection]? = nil,
        actionExecutions: [ConsoleDock.DebugActionExecution]? = nil
    ) -> Snapshot {
        Snapshot(
            generatedAt: generatedAt,
            metadata: metadata ?? ConsoleDock.sessionMetadata,
            diagnostics: diagnostics ?? ConsoleDock.diagnostics,
            entries: entries ?? ConsoleDock.entries,
            debugActions: ConsoleDock.debugActions,
            actionExecutions: actionExecutions ?? ConsoleDock.actionExecutionHistory,
            appContextProviderRegistered: ConsoleDockAppContextRegistry.shared.hasProvider(),
            appContext: appContext ?? ConsoleDock.appContext,
            archiveState: archiveState()
        )
    }

    static func diagnosisText(snapshot: Snapshot = snapshot()) -> String {
        var lines = [
            "ConsoleDock Integration Diagnosis",
            "Generated: \(ConsoleDockSnapshotFormatter.timestampText(snapshot.generatedAt))",
            "",
            "Session:",
            "  Session ID: \(snapshot.metadata.sessionIdentifier)",
            "  Started: \(snapshot.metadata.startedAt.map(ConsoleDockSnapshotFormatter.timestampText) ?? "unavailable")",
            "  Bundle ID: \(snapshot.metadata.bundleIdentifier ?? "unavailable")",
            "  Process: \(snapshot.metadata.processName)",
            "",
            "Runtime:",
            "  Running: \(snapshot.diagnostics.isRunning)",
            "  stdout capture: \(enabledLabel(snapshot.diagnostics.capturesStandardOutput))",
            "  stderr capture: \(enabledLabel(snapshot.diagnostics.capturesStandardError))",
            "  Floating Button: \(enabledLabel(snapshot.diagnostics.showsFloatingButton))",
            "  Release Builds: \(snapshot.diagnostics.allowsReleaseBuilds ? "allowed by runtime config" : "disabled by runtime config")",
            "  Limits: entries=\(snapshot.diagnostics.maximumEntries) messageLength=\(snapshot.diagnostics.maximumMessageLength)",
            "",
            "Entries:",
            "  Total: \(snapshot.diagnostics.entryCount)",
            "  Sources: \(sourceCountsText(sourceCounts(snapshot.entries)))",
            "  Levels: \(levelCountsText(levelCounts(snapshot.entries)))",
            "  Flags: redacted=\(snapshot.diagnostics.redactedEntryCount) truncated=\(snapshot.diagnostics.truncatedEntryCount) partial=\(snapshot.diagnostics.partialEntryCount)",
            "",
            "Local Debug Surface:",
            "  Debug Actions: registered=\(snapshot.debugActions.count) executions=\(snapshot.actionExecutions.count)",
            "  App Context: \(appContextStatusText(snapshot))",
            "  Session Archives: \(archiveStateText(snapshot.archiveState))",
            "",
            "Recommendations:"
        ]

        lines.append(contentsOf: recommendations(snapshot).map { "  - \($0)" })
        return lines.joined(separator: "\n")
    }

    static func healthSection(snapshot: Snapshot = snapshot()) -> ConsoleDock.AppContextSection {
        ConsoleDock.AppContextSection(
            title: "ConsoleDock Health",
            items: [
                .init(key: "Running", value: snapshot.diagnostics.isRunning ? "on" : "off"),
                .init(
                    key: "Capture",
                    value:
                        "stdout=\(enabledLabel(snapshot.diagnostics.capturesStandardOutput)) stderr=\(enabledLabel(snapshot.diagnostics.capturesStandardError))"
                ),
                .init(key: "Entry Sources", value: sourceCountsText(sourceCounts(snapshot.entries))),
                .init(key: "Entry Levels", value: levelCountsText(levelCounts(snapshot.entries))),
                .init(
                    key: "Entry Flags",
                    value:
                        "redacted=\(snapshot.diagnostics.redactedEntryCount) truncated=\(snapshot.diagnostics.truncatedEntryCount) partial=\(snapshot.diagnostics.partialEntryCount)"
                ),
                .init(
                    key: "Debug Actions",
                    value: "registered=\(snapshot.debugActions.count) executions=\(snapshot.actionExecutions.count)"
                ),
                .init(key: "App Context", value: appContextStatusText(snapshot)),
                .init(key: "Session Archives", value: archiveStateText(snapshot.archiveState)),
                .init(key: "Recommendations", value: recommendations(snapshot).joined(separator: "\n"))
            ]
        )
    }

    static func issueReportLines(snapshot: Snapshot) -> [String] {
        var lines = [
            "ConsoleDock Health:",
            "  Running: \(snapshot.diagnostics.isRunning)",
            "  Capture: stdout=\(enabledLabel(snapshot.diagnostics.capturesStandardOutput)) stderr=\(enabledLabel(snapshot.diagnostics.capturesStandardError))",
            "  Entry Sources: \(sourceCountsText(sourceCounts(snapshot.entries)))",
            "  Entry Levels: \(levelCountsText(levelCounts(snapshot.entries)))",
            "  Entry Flags: redacted=\(snapshot.diagnostics.redactedEntryCount) truncated=\(snapshot.diagnostics.truncatedEntryCount) partial=\(snapshot.diagnostics.partialEntryCount)",
            "  Debug Actions: registered=\(snapshot.debugActions.count) executions=\(snapshot.actionExecutions.count)",
            "  App Context: \(appContextStatusText(snapshot))",
            "  Session Archives: \(archiveStateText(snapshot.archiveState))",
            "  Recommendations:"
        ]
        lines.append(contentsOf: recommendations(snapshot).map { "    - \($0)" })
        return lines
    }

    static func sourceCounts(_ entries: [ConsoleDock.LogEntry]) -> SourceCounts {
        entries.reduce(into: SourceCounts()) { result, entry in
            switch entry.source {
            case .native:
                result.native += 1
            case .stdout:
                result.stdout += 1
            case .stderr:
                result.stderr += 1
            }
        }
    }

    static func levelCounts(_ entries: [ConsoleDock.LogEntry]) -> LevelCounts {
        entries.reduce(into: LevelCounts()) { result, entry in
            switch entry.level {
            case .debug:
                result.debug += 1
            case .info:
                result.info += 1
            case .warning:
                result.warning += 1
            case .error:
                result.error += 1
            case .fault:
                result.fault += 1
            }
        }
    }

    static func recommendations(_ snapshot: Snapshot) -> [String] {
        let counts = sourceCounts(snapshot.entries)
        var messages: [String] = []

        if !snapshot.diagnostics.isRunning {
            messages.append(
                "ConsoleDock is not running. "
                    + "Call ConsoleDock.start() in a debug/test build and check Release safety."
            )
        }

        if snapshot.diagnostics.entryCount == 0 {
            messages.append(
                "No entries are retained yet. "
                    + "Generate a native log, stdout/stderr write, or app logger forward before checking the panel."
            )
        }

        if counts.native == 0 {
            messages.append(
                "No native entries are retained. "
                    + "Use ConsoleDock.info/error or add a LogForwarder in the app logger sink for reliable in-app logs."
            )
        }

        if !snapshot.diagnostics.capturesStandardOutput {
            messages.append("stdout capture is disabled by configuration.")
        } else if counts.stdout == 0 {
            messages.append(
                "stdout capture is enabled but no stdout entries are retained. "
                    + "Check flushing and direct descriptor writes."
            )
        }

        if !snapshot.diagnostics.capturesStandardError {
            messages.append("stderr capture is disabled by configuration.")
        } else if counts.stderr == 0 {
            messages.append(
                "stderr capture is enabled but no stderr entries are retained. "
                    + "Check flushing and NSLog/descriptor output paths."
            )
        }

        if snapshot.debugActions.isEmpty {
            messages.append(
                "No Debug Actions are registered. "
                    + "Actions are explicit app shortcuts; ConsoleDock does not auto-discover routes."
            )
        }

        if !snapshot.appContextProviderRegistered {
            messages.append(
                "No App Context provider is registered. "
                    + "Add safe local diagnostics when issue reports need app state."
            )
        }

        messages.append(
            "Swift Logger, os_log, and Apple unified logging are not fully captured by ConsoleDock; "
                + "forward important messages explicitly."
        )
        return messages
    }

    private static func archiveState() -> ArchiveState {
        do {
            return .available(count: try ConsoleDock.sessionArchives().count)
        } catch {
            return .unavailable(message: singleLine(String(describing: error)))
        }
    }

    private static func sourceCountsText(_ counts: SourceCounts) -> String {
        "native=\(counts.native) stdout=\(counts.stdout) stderr=\(counts.stderr)"
    }

    private static func levelCountsText(_ counts: LevelCounts) -> String {
        "debug=\(counts.debug) info=\(counts.info) warning=\(counts.warning) error=\(counts.error) fault=\(counts.fault)"
    }

    private static func appContextStatusText(_ snapshot: Snapshot) -> String {
        let itemCount = snapshot.appContext.reduce(0) { count, section in
            count + section.items.count
        }
        return
            "provider=\(snapshot.appContextProviderRegistered ? "registered" : "none") sections=\(snapshot.appContext.count) items=\(itemCount)"
    }

    private static func archiveStateText(_ state: ArchiveState) -> String {
        switch state {
        case .available(let count):
            return "count=\(count)"
        case .unavailable(let message):
            return "unavailable: \(message)"
        }
    }

    private static func enabledLabel(_ value: Bool) -> String {
        value ? "enabled" : "disabled"
    }

    private static func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
