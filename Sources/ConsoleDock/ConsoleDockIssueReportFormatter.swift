import Foundation

struct ConsoleDockIssueReportFormatter {
    static func reportText(
        entries: [ConsoleDock.LogEntry],
        metadata: ConsoleDock.SessionMetadata,
        diagnostics: ConsoleDock.Diagnostics,
        appContext: [ConsoleDock.AppContextSection] = [],
        actionExecutions: [ConsoleDock.DebugActionExecution] = []
    ) -> String {
        let markers = entries.filter(isMarker)
        let timelineEvents = reproductionTimelineEvents(entries: entries, actionExecutions: actionExecutions)
        var lines = [
            "ConsoleDock Issue Report",
            "Generated: \(ConsoleDockSnapshotFormatter.timestampText(metadata.generatedAt))",
            "",
            "Session:",
            "  Session ID: \(metadata.sessionIdentifier)",
            "  Started: \(metadata.startedAt.map(ConsoleDockSnapshotFormatter.timestampText) ?? "unavailable")",
            "  Bundle ID: \(metadata.bundleIdentifier ?? "unavailable")",
            "  App Version: \(metadata.appVersion ?? "unavailable")",
            "  App Build: \(metadata.appBuild ?? "unavailable")",
            "  Process: \(metadata.processName)",
            "  OS: \(metadata.operatingSystemVersion)",
            "  Device: \(metadata.deviceModel)",
            "  Locale: \(metadata.localeIdentifier)",
            "  Time Zone: \(metadata.timeZoneIdentifier)",
            ""
        ]

        lines.append(contentsOf: ConsoleDockDiagnosticsFormatter.snapshotLines(diagnostics: diagnostics))
        lines.append("")
        lines.append("App Context:")
        if appContext.isEmpty {
            lines.append("  (no app context)")
        } else {
            lines.append(contentsOf: appContextLines(appContext))
        }

        lines.append("")
        lines.append("Reproduction Timeline:")
        if timelineEvents.isEmpty {
            lines.append("  (no timeline events)")
        } else {
            lines.append(contentsOf: timelineEvents.map { "  \($0.text)" })
        }

        lines.append("")
        lines.append("Markers:")
        if markers.isEmpty {
            lines.append("  (no markers)")
        } else {
            lines.append(contentsOf: markers.map { "  \(ConsoleDockSnapshotFormatter.entryText($0))" })
        }

        lines.append("")
        lines.append("Logs:")
        if entries.isEmpty {
            lines.append("  (no entries)")
        } else {
            lines.append(contentsOf: entries.map { "  \(ConsoleDockSnapshotFormatter.entryText($0))" })
        }
        return lines.joined(separator: "\n")
    }

    private static func isMarker(_ entry: ConsoleDock.LogEntry) -> Bool {
        entry.source == .native && entry.message.hasPrefix("[marker]")
    }

    private struct TimelineEvent {
        let timestamp: Date
        let order: Int
        let text: String
    }

    private static func reproductionTimelineEvents(
        entries: [ConsoleDock.LogEntry],
        actionExecutions: [ConsoleDock.DebugActionExecution]
    ) -> [TimelineEvent] {
        var events: [TimelineEvent] = []

        for entry in entries {
            if isMarker(entry) {
                events.append(
                    TimelineEvent(
                        timestamp: entry.timestamp,
                        order: events.count,
                        text: "[\(ConsoleDockSnapshotFormatter.timestampText(entry.timestamp))] [marker] "
                            + markerTimelineMessage(entry.message)
                    )
                )
            } else if entry.level == .error || entry.level == .fault {
                events.append(
                    TimelineEvent(
                        timestamp: entry.timestamp,
                        order: events.count,
                        text: "[\(ConsoleDockSnapshotFormatter.timestampText(entry.timestamp))] [log] "
                            + "[\(levelLabel(entry.level))] \(singleLine(entry.message))"
                    )
                )
            }
        }

        for execution in actionExecutions {
            events.append(
                TimelineEvent(
                    timestamp: execution.startedAt,
                    order: events.count,
                    text: actionTimelineText(execution)
                )
            )
        }

        return events.sorted {
            if $0.timestamp == $1.timestamp {
                return $0.order < $1.order
            }
            return $0.timestamp < $1.timestamp
        }
    }

    private static func actionTimelineText(_ execution: ConsoleDock.DebugActionExecution) -> String {
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

    private static func markerTimelineMessage(_ message: String) -> String {
        let singleLineMessage = singleLine(message)
        if singleLineMessage.hasPrefix("[marker] ") {
            return String(singleLineMessage.dropFirst("[marker] ".count))
        }
        return singleLineMessage
    }

    private static func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }

    private static func appContextLines(_ sections: [ConsoleDock.AppContextSection]) -> [String] {
        var lines: [String] = []
        for section in sections {
            lines.append("  \(section.title):")
            for item in section.items {
                let valueLines = item.value.components(separatedBy: "\n")
                if let firstLine = valueLines.first {
                    lines.append("    \(item.key): \(firstLine)")
                }
                for continuation in valueLines.dropFirst() {
                    lines.append("      \(continuation)")
                }
            }
        }
        return lines
    }
}
