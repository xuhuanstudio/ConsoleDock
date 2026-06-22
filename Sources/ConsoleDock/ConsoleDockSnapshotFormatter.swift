import Foundation

struct ConsoleDockSnapshotFormatter {
    static func snapshotText(
        entries: [ConsoleDock.LogEntry],
        generatedAt: Date = Date()
    ) -> String {
        var lines = [
            "ConsoleDock Log Snapshot",
            "Generated: \(timestampString(generatedAt))",
            "Entries: \(entries.count)",
            ""
        ]

        if entries.isEmpty {
            lines.append("(no entries)")
            return lines.joined(separator: "\n")
        }

        lines.append(contentsOf: entries.map(formatEntry))
        return lines.joined(separator: "\n")
    }

    private static func formatEntry(_ entry: ConsoleDock.LogEntry) -> String {
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
