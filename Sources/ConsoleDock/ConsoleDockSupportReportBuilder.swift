import Foundation

struct ConsoleDockSupportReportBuilder {
    static func makeReport(
        options rawOptions: ConsoleDock.SupportReportOptions,
        entries entriesSnapshot: [ConsoleDock.LogEntry],
        metadata metadataSnapshot: ConsoleDock.SessionMetadata,
        diagnostics diagnosticsSnapshot: ConsoleDock.Diagnostics,
        appContext appContextSnapshot: [ConsoleDock.AppContextSection],
        actionExecutions actionExecutionsSnapshot: [ConsoleDock.DebugActionExecution]
    ) -> ConsoleDock.SupportReport {
        let options = rawOptions.normalized()
        let range = ResolvedTimeRange(timeRange: options.timeRange, generatedAt: metadataSnapshot.generatedAt)
        let includedEntries = entriesSnapshot.filter { range.contains($0.timestamp) }
        let includedActionExecutions = actionExecutionsSnapshot.filter { range.contains($0.startedAt) }
        let appContext = options.includesAppContext ? appContextSnapshot : []
        let integrationHealthLines = integrationHealthLines(
            entries: includedEntries,
            metadata: metadataSnapshot,
            diagnostics: diagnosticsSnapshot,
            appContext: appContext,
            actionExecutions: includedActionExecutions,
            includesIntegrationHealth: options.includesIntegrationHealth
        )
        let baseText = reportText(
            entries: includedEntries,
            metadata: metadataSnapshot,
            diagnostics: diagnosticsSnapshot,
            appContext: appContext,
            actionExecutions: includedActionExecutions,
            integrationHealthLines: integrationHealthLines,
            timeRangeDescription: range.description,
            retainedEntryCount: entriesSnapshot.count,
            retainedActionExecutionCount: actionExecutionsSnapshot.count,
            maximumReportCharacterCount: options.maximumReportCharacterCount,
            isReportTruncated: false,
            originalReportCharacterCount: nil
        )
        let reportCharacterCount = baseText.count
        let isTruncated = reportCharacterCount > options.maximumReportCharacterCount
        let finalText: String
        if isTruncated {
            let textWithTruncationHeader = reportText(
                entries: includedEntries,
                metadata: metadataSnapshot,
                diagnostics: diagnosticsSnapshot,
                appContext: appContext,
                actionExecutions: includedActionExecutions,
                integrationHealthLines: integrationHealthLines,
                timeRangeDescription: range.description,
                retainedEntryCount: entriesSnapshot.count,
                retainedActionExecutionCount: actionExecutionsSnapshot.count,
                maximumReportCharacterCount: options.maximumReportCharacterCount,
                isReportTruncated: true,
                originalReportCharacterCount: reportCharacterCount
            )
            finalText = truncatedReportText(
                textWithTruncationHeader,
                maximumCharacterCount: options.maximumReportCharacterCount
            )
        } else {
            finalText = baseText
        }

        return ConsoleDock.SupportReport(
            generatedAt: metadataSnapshot.generatedAt,
            timeRangeDescription: range.description,
            includedEntryCount: includedEntries.count,
            omittedEntryCount: max(0, entriesSnapshot.count - includedEntries.count),
            includedActionExecutionCount: includedActionExecutions.count,
            omittedActionExecutionCount: max(0, actionExecutionsSnapshot.count - includedActionExecutions.count),
            reportCharacterCount: reportCharacterCount,
            isReportTruncated: isTruncated,
            text: finalText
        )
    }

    private static func integrationHealthLines(
        entries: [ConsoleDock.LogEntry],
        metadata: ConsoleDock.SessionMetadata,
        diagnostics: ConsoleDock.Diagnostics,
        appContext: [ConsoleDock.AppContextSection],
        actionExecutions: [ConsoleDock.DebugActionExecution],
        includesIntegrationHealth: Bool
    ) -> [String] {
        guard includesIntegrationHealth else { return [] }
        let snapshot = ConsoleDockIntegrationDiagnosisFormatter.snapshot(
            entries: entries,
            metadata: metadata,
            diagnostics: diagnostics,
            appContext: appContext,
            actionExecutions: actionExecutions
        )
        return ConsoleDockIntegrationDiagnosisFormatter.issueReportLines(snapshot: snapshot)
    }

    private static func reportText(
        entries: [ConsoleDock.LogEntry],
        metadata: ConsoleDock.SessionMetadata,
        diagnostics: ConsoleDock.Diagnostics,
        appContext: [ConsoleDock.AppContextSection],
        actionExecutions: [ConsoleDock.DebugActionExecution],
        integrationHealthLines: [String],
        timeRangeDescription: String,
        retainedEntryCount: Int,
        retainedActionExecutionCount: Int,
        maximumReportCharacterCount: Int,
        isReportTruncated: Bool,
        originalReportCharacterCount: Int?
    ) -> String {
        var headerLines = [
            "Support Bundle:",
            "  Time Range: \(timeRangeDescription)",
            "  Included Entries: \(entries.count) of \(retainedEntryCount) retained",
            "  Omitted Entries: \(max(0, retainedEntryCount - entries.count))",
            "  Included Action Executions: \(actionExecutions.count) of \(retainedActionExecutionCount) recorded",
            "  Omitted Action Executions: \(max(0, retainedActionExecutionCount - actionExecutions.count))",
            "  Size Limit: \(maximumReportCharacterCount) characters",
            "  Truncated: \(isReportTruncated ? "true" : "false")"
        ]
        if let originalReportCharacterCount {
            headerLines.append("  Original Length: \(originalReportCharacterCount) characters")
        }
        headerLines.append("  Storage: generated on demand; no continuous log file or automatic upload")
        headerLines.append("  Scope: current bounded in-memory/session data only")

        return ConsoleDockIssueReportFormatter.reportText(
            title: "ConsoleDock Support Report",
            entries: entries,
            metadata: metadata,
            diagnostics: diagnostics,
            appContext: appContext,
            actionExecutions: actionExecutions,
            headerLines: headerLines,
            integrationHealthLines: integrationHealthLines
        )
    }

    private static func truncatedReportText(_ text: String, maximumCharacterCount: Int) -> String {
        guard text.count > maximumCharacterCount else {
            return text
        }

        let notice =
            "\n\n[ConsoleDock support report truncated at \(maximumCharacterCount) characters. Increase the report limit or narrow the time range when more detail is required.]"
        let prefixCount = max(0, maximumCharacterCount - notice.count)
        return String(text.prefix(prefixCount)) + notice
    }
}

private struct ResolvedTimeRange {
    let start: Date?
    let end: Date?
    let description: String

    init(timeRange: ConsoleDock.SupportReportTimeRange, generatedAt: Date) {
        switch timeRange {
        case .allRetained:
            start = nil
            end = nil
            description = "all retained entries"
        case .last(minutes: let rawMinutes):
            let minutes = max(1, rawMinutes)
            start = generatedAt.addingTimeInterval(-TimeInterval(minutes * 60))
            end = generatedAt
            description = "last \(minutes) minute\(minutes == 1 ? "" : "s")"
        case .range(let from, let to):
            start = min(from, to)
            end = max(from, to)
            description =
                "\(ConsoleDockSnapshotFormatter.timestampText(min(from, to))) to \(ConsoleDockSnapshotFormatter.timestampText(max(from, to)))"
        }
    }

    func contains(_ date: Date) -> Bool {
        if let start, date < start {
            return false
        }
        if let end, date > end {
            return false
        }
        return true
    }
}
