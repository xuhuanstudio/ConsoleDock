import Foundation

struct ConsoleDockEntryFilter {
    enum SourceScope: Int, CaseIterable {
        case all
        case native
        case stdout
        case stderr

        var title: String {
            switch self {
            case .all:
                return "All"
            case .native:
                return "native"
            case .stdout:
                return "stdout"
            case .stderr:
                return "stderr"
            }
        }

        func contains(_ source: ConsoleDock.LogSource) -> Bool {
            switch (self, source) {
            case (.all, _),
                 (.native, .native),
                 (.stdout, .stdout),
                 (.stderr, .stderr):
                return true
            default:
                return false
            }
        }
    }

    enum LevelScope: Int, CaseIterable {
        case all
        case debug
        case info
        case warning
        case error
        case fault

        var title: String {
            switch self {
            case .all:
                return "All"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .warning:
                return "Warn"
            case .error:
                return "Error"
            case .fault:
                return "Fault"
            }
        }

        func contains(_ level: ConsoleDock.LogLevel) -> Bool {
            switch (self, level) {
            case (.all, _),
                 (.debug, .debug),
                 (.info, .info),
                 (.warning, .warning),
                 (.error, .error),
                 (.fault, .fault):
                return true
            default:
                return false
            }
        }
    }

    static func filteredEntries(
        _ entries: [ConsoleDock.LogEntry],
        query: String,
        sourceScope: SourceScope = .all,
        levelScope: LevelScope = .all
    ) -> [ConsoleDock.LogEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return entries.filter { entry in
            guard sourceScope.contains(entry.source) else {
                return false
            }
            guard levelScope.contains(entry.level) else {
                return false
            }
            guard !trimmedQuery.isEmpty else {
                return true
            }
            return searchableText(for: entry).localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private static func searchableText(for entry: ConsoleDock.LogEntry) -> String {
        "\(entry.message)\n\(sourceTitle(entry.source))\n\(levelTitle(entry.level))"
    }

    private static func levelTitle(_ level: ConsoleDock.LogLevel) -> String {
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

    private static func sourceTitle(_ source: ConsoleDock.LogSource) -> String {
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
