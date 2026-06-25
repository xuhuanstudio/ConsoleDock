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
            if let visibleEntryCount {
                lines.append("Visible Entries: \(visibleEntryCount)")
            }
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
        let metadata = entryFlagText(entry).map { " [\($0)]" } ?? ""
        let prefix =
            "[\(timestampText(entry.timestamp))] [\(sourceLabel(entry.source))] [\(levelLabel(entry.level))]"
        return "\(prefix)\(metadata) \(singleLine(entry.message))"
    }

    static func entryDetailText(_ entry: ConsoleDock.LogEntry) -> String {
        metadataLines(entry).joined(separator: "\n") + "\n\n" + entry.message
    }

    static func metadataText(_ entry: ConsoleDock.LogEntry) -> String {
        metadataLines(entry).joined(separator: "\n")
    }

    static func timestampText(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    private static func timestampString(_ date: Date) -> String {
        timestampText(date)
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

    private static func metadataLines(_ entry: ConsoleDock.LogEntry) -> [String] {
        [
            "Time: \(timestampText(entry.timestamp))",
            "Source: \(sourceLabel(entry.source))",
            "Level: \(levelLabel(entry.level))",
            "Partial: \(entry.partial)",
            "Redacted: \(entry.redacted)",
            "Truncated: \(entry.truncated)"
        ]
    }

    private static func entryFlagText(_ entry: ConsoleDock.LogEntry) -> String? {
        var flags: [String] = []
        if entry.partial {
            flags.append("partial")
        }
        if entry.redacted {
            flags.append("redacted")
        }
        if entry.truncated {
            flags.append("truncated")
        }
        return flags.isEmpty ? nil : flags.joined(separator: " ")
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
