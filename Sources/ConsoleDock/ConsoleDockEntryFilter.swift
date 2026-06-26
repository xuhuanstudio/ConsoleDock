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
        let parsedQuery = Query(query)

        return entries.filter { entry in
            guard sourceScope.contains(entry.source) else {
                return false
            }
            guard levelScope.contains(entry.level) else {
                return false
            }
            return parsedQuery.matches(entry, searchableText: searchableText(for: entry))
        }
    }

    private struct Query {
        private let includedTerms: [String]
        private let excludedTerms: [String]
        private let sourcePredicates: [ConsoleDock.LogSource]
        private let levelPredicates: [ConsoleDock.LogLevel]
        private let flagPredicates: [EntryFlag]

        init(_ rawValue: String) {
            var includedTerms: [String] = []
            var excludedTerms: [String] = []
            var sourcePredicates: [ConsoleDock.LogSource] = []
            var levelPredicates: [ConsoleDock.LogLevel] = []
            var flagPredicates: [EntryFlag] = []

            for token in Self.tokenize(rawValue) {
                let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedToken.isEmpty else { continue }

                let isExcluded = trimmedToken.hasPrefix("-") && trimmedToken.count > 1
                let value = isExcluded ? String(trimmedToken.dropFirst()) : trimmedToken
                guard !value.isEmpty else { continue }

                if isExcluded {
                    excludedTerms.append(value)
                    continue
                }

                if let predicate = Self.sourcePredicate(for: value) {
                    sourcePredicates.append(predicate)
                } else if let predicate = Self.levelPredicate(for: value) {
                    levelPredicates.append(predicate)
                } else if let predicate = Self.flagPredicate(for: value) {
                    flagPredicates.append(predicate)
                } else {
                    includedTerms.append(value)
                }
            }

            self.includedTerms = includedTerms
            self.excludedTerms = excludedTerms
            self.sourcePredicates = sourcePredicates
            self.levelPredicates = levelPredicates
            self.flagPredicates = flagPredicates
        }

        func matches(_ entry: ConsoleDock.LogEntry, searchableText: String) -> Bool {
            for source in sourcePredicates where entry.source != source {
                return false
            }
            for level in levelPredicates where entry.level != level {
                return false
            }
            for flag in flagPredicates where !flag.contains(entry) {
                return false
            }
            for term in includedTerms where !searchableText.localizedCaseInsensitiveContains(term) {
                return false
            }
            for term in excludedTerms where searchableText.localizedCaseInsensitiveContains(term) {
                return false
            }
            return true
        }

        private static func tokenize(_ rawValue: String) -> [String] {
            var tokens: [String] = []
            var current = ""
            var isInsideQuotes = false
            var index = rawValue.startIndex

            while index < rawValue.endIndex {
                let character = rawValue[index]
                if character == "\"" {
                    isInsideQuotes.toggle()
                } else if character.isWhitespace && !isInsideQuotes {
                    appendToken(current, to: &tokens)
                    current = ""
                } else {
                    current.append(character)
                }
                index = rawValue.index(after: index)
            }
            appendToken(current, to: &tokens)
            return tokens
        }

        private static func appendToken(_ rawToken: String, to tokens: inout [String]) {
            let trimmedToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedToken.isEmpty else { return }
            tokens.append(trimmedToken)
        }

        private static func sourcePredicate(for token: String) -> ConsoleDock.LogSource? {
            guard let value = normalizedValue(forKey: "source", in: token) else { return nil }
            switch value {
            case "native":
                return .native
            case "stdout":
                return .stdout
            case "stderr":
                return .stderr
            default:
                return nil
            }
        }

        private static func levelPredicate(for token: String) -> ConsoleDock.LogLevel? {
            guard let value = normalizedValue(forKey: "level", in: token) else { return nil }
            switch value {
            case "debug":
                return .debug
            case "info":
                return .info
            case "warning", "warn":
                return .warning
            case "error":
                return .error
            case "fault":
                return .fault
            default:
                return nil
            }
        }

        private static func flagPredicate(for token: String) -> EntryFlag? {
            guard let value = normalizedValue(forKey: "is", in: token) else { return nil }
            switch value {
            case "partial":
                return .partial
            case "redacted":
                return .redacted
            case "truncated":
                return .truncated
            default:
                return nil
            }
        }

        private static func normalizedValue(forKey key: String, in token: String) -> String? {
            let prefix = "\(key):"
            guard token.lowercased().hasPrefix(prefix), token.count > prefix.count else {
                return nil
            }
            return String(token.dropFirst(prefix.count)).lowercased()
        }
    }

    private enum EntryFlag {
        case partial
        case redacted
        case truncated

        func contains(_ entry: ConsoleDock.LogEntry) -> Bool {
            switch self {
            case .partial:
                return entry.partial
            case .redacted:
                return entry.redacted
            case .truncated:
                return entry.truncated
            }
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
