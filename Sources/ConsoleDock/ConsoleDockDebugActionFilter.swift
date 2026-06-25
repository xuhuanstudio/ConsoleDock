import Foundation

struct ConsoleDockDebugActionFilter {
    static func filteredActions(
        _ actions: [ConsoleDockDebugAction],
        query: String
    ) -> [ConsoleDockDebugAction] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return actions }

        return actions.filter { action in
            searchableText(for: action).range(
                of: normalizedQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
        }
    }

    private static func searchableText(for action: ConsoleDockDebugAction) -> String {
        [
            action.id,
            action.title,
            action.group,
            action.detail
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}
