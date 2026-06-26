import Foundation

final class ConsoleDockAppContextRegistry {
    typealias Provider = () -> [ConsoleDock.AppContextSection]

    static let shared = ConsoleDockAppContextRegistry()

    private let lock = NSLock()
    private var provider: Provider?
    private let maximumValueLength = 2_048

    func setProvider(_ provider: @escaping Provider) {
        lock.lock()
        self.provider = provider
        lock.unlock()
    }

    func clearProvider() {
        lock.lock()
        provider = nil
        lock.unlock()
    }

    func hasProvider() -> Bool {
        lock.lock()
        let result = provider != nil
        lock.unlock()
        return result
    }

    func snapshot() -> [ConsoleDock.AppContextSection] {
        lock.lock()
        let provider = self.provider
        lock.unlock()

        guard let provider else { return [] }

        let rawSections: [ConsoleDock.AppContextSection]
        if Thread.isMainThread {
            rawSections = provider()
        } else {
            rawSections = DispatchQueue.main.sync(execute: provider)
        }
        return normalizedSections(rawSections)
    }

    private func normalizedSections(_ sections: [ConsoleDock.AppContextSection]) -> [ConsoleDock.AppContextSection] {
        sections.compactMap { section in
            guard let title = normalizedRequiredSingleLine(section.title) else { return nil }
            let items = normalizedItems(section.items)
            guard !items.isEmpty else { return nil }
            return ConsoleDock.AppContextSection(title: title, items: items)
        }
    }

    private func normalizedItems(_ items: [ConsoleDock.AppContextItem]) -> [ConsoleDock.AppContextItem] {
        var result: [ConsoleDock.AppContextItem] = []
        var seenKeys = Set<String>()
        for item in items {
            guard let key = normalizedRequiredSingleLine(item.key),
                !seenKeys.contains(key),
                let value = normalizedRequiredValue(item.value)
            else {
                continue
            }
            seenKeys.insert(key)
            result.append(ConsoleDock.AppContextItem(key: key, value: value))
        }
        return result
    }

    private func normalizedRequiredSingleLine(_ value: String) -> String? {
        let normalized =
            value
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private func normalizedRequiredValue(_ value: String) -> String? {
        let normalized =
            value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        if normalized.count <= maximumValueLength {
            return normalized
        }
        return String(normalized.prefix(maximumValueLength))
    }
}
