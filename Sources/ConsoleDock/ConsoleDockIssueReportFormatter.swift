import Foundation

struct ConsoleDockIssueReportFormatter {
    static func reportText(
        entries: [ConsoleDock.LogEntry],
        metadata: ConsoleDock.SessionMetadata,
        diagnostics: ConsoleDock.Diagnostics,
        appContext: [ConsoleDock.AppContextSection] = []
    ) -> String {
        let markers = entries.filter(isMarker)
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
