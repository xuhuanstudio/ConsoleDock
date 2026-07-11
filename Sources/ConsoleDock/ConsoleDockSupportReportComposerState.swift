import Foundation

struct ConsoleDockSupportReportComposerState: Equatable {
    enum TimeRangePreset: Int, CaseIterable, Equatable {
        case last5Minutes
        case last10Minutes
        case last30Minutes
        case last60Minutes
        case allRetained

        var segmentTitle: String {
            switch self {
            case .last5Minutes:
                return "5m"
            case .last10Minutes:
                return "10m"
            case .last30Minutes:
                return "30m"
            case .last60Minutes:
                return "60m"
            case .allRetained:
                return "All"
            }
        }

        var timeRange: ConsoleDock.SupportReportTimeRange {
            switch self {
            case .last5Minutes:
                return .last(minutes: 5)
            case .last10Minutes:
                return .last(minutes: 10)
            case .last30Minutes:
                return .last(minutes: 30)
            case .last60Minutes:
                return .last(minutes: 60)
            case .allRetained:
                return .allRetained
            }
        }
    }

    enum TimeRangeSelection: Equatable {
        case preset(TimeRangePreset)
        case custom(from: Date, to: Date)
    }

    var timeRangeSelection: TimeRangeSelection
    var includesAppContext: Bool
    var includesIntegrationHealth: Bool
    var maximumReportCharacterCount: Int

    init(
        timeRangeSelection: TimeRangeSelection = .preset(.last10Minutes),
        includesAppContext: Bool = true,
        includesIntegrationHealth: Bool = true,
        maximumReportCharacterCount: Int = ConsoleDock.SupportReportOptions.defaultMaximumReportCharacterCount
    ) {
        self.timeRangeSelection = timeRangeSelection
        self.includesAppContext = includesAppContext
        self.includesIntegrationHealth = includesIntegrationHealth
        self.maximumReportCharacterCount = maximumReportCharacterCount
    }

    var selectedPreset: TimeRangePreset? {
        guard case .preset(let preset) = timeRangeSelection else { return nil }
        return preset
    }

    var customRange: (from: Date, to: Date)? {
        guard case .custom(let from, let to) = timeRangeSelection else { return nil }
        return (from, to)
    }

    var options: ConsoleDock.SupportReportOptions {
        let timeRange: ConsoleDock.SupportReportTimeRange
        switch timeRangeSelection {
        case .preset(let preset):
            timeRange = preset.timeRange
        case .custom(let from, let to):
            timeRange = .range(from: from, to: to)
        }
        return ConsoleDock.SupportReportOptions(
            timeRange: timeRange,
            maximumReportCharacterCount: maximumReportCharacterCount,
            includesAppContext: includesAppContext,
            includesIntegrationHealth: includesIntegrationHealth
        )
    }

    mutating func selectPreset(_ preset: TimeRangePreset) {
        timeRangeSelection = .preset(preset)
    }

    mutating func selectCustomRange(from: Date, to: Date) {
        timeRangeSelection = .custom(from: min(from, to), to: max(from, to))
    }

    func summaryText(for report: ConsoleDock.SupportReport) -> String {
        let sizeDescription: String
        if report.isReportTruncated {
            sizeDescription = "\(report.text.count) shown of \(report.reportCharacterCount) generated characters"
        } else {
            sizeDescription = "\(report.reportCharacterCount) characters"
        }
        return [
            "Range: \(report.timeRangeDescription)",
            "Logs: \(report.includedEntryCount) included, \(report.omittedEntryCount) omitted",
            "Actions: \(report.includedActionExecutionCount) included, \(report.omittedActionExecutionCount) omitted",
            "Size: \(sizeDescription) (limit \(maximumReportCharacterCount))",
            "Status: \(report.isReportTruncated ? "truncated" : "complete")",
            "Scope: current bounded session"
        ].joined(separator: "\n")
    }
}
