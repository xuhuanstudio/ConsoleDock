import Foundation

struct ConsoleDockTimelineEvent: Equatable, Identifiable {
    enum Kind: Equatable {
        case marker
        case action
        case log
    }

    enum Severity: Equatable {
        case neutral
        case success
        case warning
        case error
    }

    let id: String
    let timestamp: Date
    let kind: Kind
    let title: String
    let subtitle: String
    let detail: String?
    let reportText: String
    let severity: Severity
    let logEntry: ConsoleDock.LogEntry?
    let actionExecution: ConsoleDock.DebugActionExecution?
}

enum ConsoleDockTimelineBuilder {
    static func events(
        entries: [ConsoleDock.LogEntry],
        actionExecutions: [ConsoleDock.DebugActionExecution]
    ) -> [ConsoleDockTimelineEvent] {
        var records: [(event: ConsoleDockTimelineEvent, order: Int)] = []

        for entry in entries {
            if isMarker(entry) {
                records.append((markerEvent(entry: entry, order: records.count), records.count))
            } else if isErrorOrFault(entry) {
                records.append((logEvent(entry: entry, order: records.count), records.count))
            }
        }

        for execution in actionExecutions {
            records.append((actionEvent(execution: execution, order: records.count), records.count))
        }

        return records.sorted {
            if $0.event.timestamp == $1.event.timestamp {
                return $0.order < $1.order
            }
            return $0.event.timestamp < $1.event.timestamp
        }.map(\.event)
    }

    static func reportLines(
        entries: [ConsoleDock.LogEntry],
        actionExecutions: [ConsoleDock.DebugActionExecution]
    ) -> [String] {
        events(entries: entries, actionExecutions: actionExecutions).map(\.reportText)
    }

    static func actionDetailText(_ execution: ConsoleDock.DebugActionExecution) -> String {
        var lines = [
            "Action ID: \(execution.actionID)",
            "Title: \(execution.title)",
            "Outcome: \(outcomeLabel(execution.outcome))",
            "Started: \(ConsoleDockSnapshotFormatter.timestampText(execution.startedAt))",
            "Completed: \(ConsoleDockSnapshotFormatter.timestampText(execution.completedAt))"
        ]
        if let group = execution.group {
            lines.append("Group: \(singleLine(group))")
        }
        if let parameterSummary = execution.parameterSummary {
            lines.append("Parameters: \(parameterSummary)")
        }
        if let message = execution.message {
            lines.append("Message: \(singleLine(message))")
        }
        return lines.joined(separator: "\n")
    }

    private static func markerEvent(entry: ConsoleDock.LogEntry, order: Int) -> ConsoleDockTimelineEvent {
        let title = markerMessage(entry.message)
        let subtitle = "[marker] \(sourceLabel(entry.source))"
        return ConsoleDockTimelineEvent(
            id: "marker:\(entry.id):\(order)",
            timestamp: entry.timestamp,
            kind: .marker,
            title: title,
            subtitle: subtitle,
            detail: ConsoleDockSnapshotFormatter.entryText(entry),
            reportText: "[\(ConsoleDockSnapshotFormatter.timestampText(entry.timestamp))] [marker] \(title)",
            severity: .neutral,
            logEntry: entry,
            actionExecution: nil
        )
    }

    private static func logEvent(entry: ConsoleDock.LogEntry, order: Int) -> ConsoleDockTimelineEvent {
        let level = levelLabel(entry.level)
        let title = singleLine(entry.message)
        return ConsoleDockTimelineEvent(
            id: "log:\(entry.id):\(order)",
            timestamp: entry.timestamp,
            kind: .log,
            title: title,
            subtitle: "[log] [\(level)] \(sourceLabel(entry.source))",
            detail: ConsoleDockSnapshotFormatter.entryText(entry),
            reportText: "[\(ConsoleDockSnapshotFormatter.timestampText(entry.timestamp))] [log] [\(level)] \(title)",
            severity: .error,
            logEntry: entry,
            actionExecution: nil
        )
    }

    private static func actionEvent(
        execution: ConsoleDock.DebugActionExecution,
        order: Int
    ) -> ConsoleDockTimelineEvent {
        let outcome = outcomeLabel(execution.outcome)
        let detail = actionDetailSummary(execution)
        return ConsoleDockTimelineEvent(
            id: "action:\(execution.id):\(order)",
            timestamp: execution.startedAt,
            kind: .action,
            title: execution.title,
            subtitle: "[action] [\(outcome)] \(execution.actionID)",
            detail: detail,
            reportText: actionReportText(execution),
            severity: severity(outcome: execution.outcome),
            logEntry: nil,
            actionExecution: execution
        )
    }

    private static func actionReportText(_ execution: ConsoleDock.DebugActionExecution) -> String {
        var parts = [
            "[\(ConsoleDockSnapshotFormatter.timestampText(execution.startedAt))]",
            "[action]",
            "[\(outcomeLabel(execution.outcome))]",
            "\(execution.title) [\(execution.actionID)]"
        ]
        if let group = execution.group {
            parts.append("group=\(singleLine(group))")
        }
        if let parameterSummary = execution.parameterSummary {
            parts.append("params: \(parameterSummary)")
        }
        if let message = execution.message {
            parts.append(singleLine(message))
        }
        return parts.joined(separator: " ")
    }

    private static func actionDetailSummary(_ execution: ConsoleDock.DebugActionExecution) -> String? {
        var parts: [String] = []
        if let group = execution.group {
            parts.append("group=\(singleLine(group))")
        }
        if let parameterSummary = execution.parameterSummary {
            parts.append("params: \(parameterSummary)")
        }
        if let message = execution.message {
            parts.append(singleLine(message))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }

    private static func isMarker(_ entry: ConsoleDock.LogEntry) -> Bool {
        entry.isMarker
    }

    private static func isErrorOrFault(_ entry: ConsoleDock.LogEntry) -> Bool {
        entry.level == .error || entry.level == .fault
    }

    private static func markerMessage(_ message: String) -> String {
        let singleLineMessage = singleLine(message)
        if singleLineMessage.hasPrefix("[marker] ") {
            return String(singleLineMessage.dropFirst("[marker] ".count))
        }
        return singleLineMessage
    }

    private static func outcomeLabel(_ outcome: ConsoleDock.DebugActionExecutionOutcome) -> String {
        switch outcome {
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .skipped:
            return "skipped"
        }
    }

    private static func severity(
        outcome: ConsoleDock.DebugActionExecutionOutcome
    ) -> ConsoleDockTimelineEvent.Severity {
        switch outcome {
        case .completed:
            return .success
        case .failed:
            return .error
        case .skipped:
            return .warning
        }
    }

    private static func levelLabel(_ level: ConsoleDock.LogLevel) -> String {
        switch level {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARN"
        case .error:
            return "ERROR"
        case .fault:
            return "FAULT"
        }
    }

    private static func sourceLabel(_ source: ConsoleDock.LogSource) -> String {
        switch source {
        case .native:
            return "native"
        case .stdout:
            return "stdout"
        case .stderr:
            return "stderr"
        }
    }

    private static func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }
}
