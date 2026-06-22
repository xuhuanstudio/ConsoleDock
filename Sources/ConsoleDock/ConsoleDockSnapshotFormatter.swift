import Foundation

struct ConsoleDockSnapshotFormatter {
    static func snapshotText(
        entries: [ConsoleDock.LogEntry],
        generatedAt: Date = Date(),
        diagnostics: ConsoleDock.Diagnostics? = nil,
        visibleEntryCount: Int? = nil
    ) -> String {
        var lines = [
            "ConsoleDock Log Snapshot",
            "Generated: \(timestampString(generatedAt))"
        ]

        if let diagnostics {
            lines.append("Entries: \(diagnostics.entryCount)")
            lines.append("Visible Entries: \(visibleEntryCount ?? entries.count)")
            lines.append(contentsOf: ConsoleDockDiagnosticsFormatter.snapshotLines(diagnostics: diagnostics))
            lines.append("")
        } else {
            lines.append("Entries: \(entries.count)")
            lines.append("")
        }

        if entries.isEmpty {
            lines.append("(no entries)")
            return lines.joined(separator: "\n")
        }

        lines.append(contentsOf: entries.map(entryText))
        return lines.joined(separator: "\n")
    }

    static func entryText(_ entry: ConsoleDock.LogEntry) -> String {
        "[\(timestampString(entry.timestamp))] [\(sourceLabel(entry.source))] [\(levelLabel(entry.level))] \(singleLine(entry.message))"
    }

    private static func timestampString(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static func singleLine(_ message: String) -> String {
        message
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
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
}
