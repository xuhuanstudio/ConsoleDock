import Foundation

struct ConsoleDockDebugAction: Equatable, Identifiable {
    let id: String
    let title: String
    let group: String?
    let detail: String?
    let requiresConfirmation: Bool
    let isEnabled: Bool
    let style: ConsoleDock.DebugActionStyle

    init(
        id: String,
        title: String,
        group: String? = nil,
        detail: String? = nil,
        requiresConfirmation: Bool = false,
        isEnabled: Bool = true,
        style: ConsoleDock.DebugActionStyle = .normal
    ) {
        self.id = id
        self.title = title
        self.group = group
        self.detail = detail
        self.requiresConfirmation = requiresConfirmation
        self.isEnabled = isEnabled
        self.style = style
    }
}

extension Notification.Name {
    static let consoleDockDebugActionsDidChange = Notification.Name("ConsoleDockDebugActionsDidChangeNotification")
}

final class ConsoleDockDebugActionRegistry {
    typealias Handler = () throws -> Void

    static let shared = ConsoleDockDebugActionRegistry()

    private struct Record {
        let action: ConsoleDockDebugAction
        let handler: Handler
    }

    private let lock = NSLock()
    private let notificationCenter: NotificationCenter
    private var records: [Record] = []

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func register(
        id: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        isEnabled: Bool,
        style: ConsoleDock.DebugActionStyle,
        handler: @escaping Handler
    ) {
        guard let normalizedID = normalizedRequired(id),
            let normalizedTitle = normalizedRequired(title)
        else {
            return
        }

        let action = ConsoleDockDebugAction(
            id: normalizedID,
            title: normalizedTitle,
            group: normalizedSingleLineOptional(group),
            detail: normalizedOptional(detail),
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style
        )
        let record = Record(action: action, handler: handler)

        lock.lock()
        if let index = records.firstIndex(where: { $0.action.id == normalizedID }) {
            records[index] = record
        } else {
            records.append(record)
        }
        lock.unlock()

        postActionsChanged()
    }

    func unregister(id: String) {
        guard let normalizedID = normalizedRequired(id) else { return }

        lock.lock()
        let originalCount = records.count
        records.removeAll { $0.action.id == normalizedID }
        let changed = records.count != originalCount
        lock.unlock()

        if changed {
            postActionsChanged()
        }
    }

    func removeAll() {
        lock.lock()
        let changed = !records.isEmpty
        records.removeAll()
        lock.unlock()

        if changed {
            postActionsChanged()
        }
    }

    func actions() -> [ConsoleDockDebugAction] {
        lock.lock()
        let snapshot = records.map(\.action)
        lock.unlock()
        return snapshot
    }

    func perform(id: String) {
        guard let normalizedID = normalizedRequired(id),
            let record = record(for: normalizedID)
        else {
            ConsoleDock.error("Debug action failed: missing action id=\(singleLine(id))")
            return
        }

        guard record.action.isEnabled else {
            ConsoleDock.info("Debug action skipped: \(record.action.title) [\(record.action.id)] disabled")
            return
        }

        let run = {
            ConsoleDock.info("Debug action started: \(record.action.title) [\(record.action.id)]")
            do {
                try record.handler()
                ConsoleDock.info("Debug action completed: \(record.action.title) [\(record.action.id)]")
            } catch {
                ConsoleDock.error(
                    "Debug action failed: \(record.action.title) [\(record.action.id)] error=\(error)"
                )
            }
        }

        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }

    private func record(for id: String) -> Record? {
        lock.lock()
        let record = records.first { $0.action.id == id }
        lock.unlock()
        return record
    }

    private func postActionsChanged() {
        notificationCenter.post(name: .consoleDockDebugActionsDidChange, object: self)
    }

    private func normalizedOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func normalizedSingleLineOptional(_ value: String?) -> String? {
        guard let trimmed = normalizedOptional(value) else { return nil }
        return singleLine(trimmed)
    }

    private func normalizedRequired(_ value: String) -> String? {
        let normalized = singleLine(value.trimmingCharacters(in: .whitespacesAndNewlines))
        return normalized.isEmpty ? nil : normalized
    }

    private func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}

extension ConsoleDock {
    static var debugActions: [ConsoleDockDebugAction] {
        ConsoleDockDebugActionRegistry.shared.actions()
    }

    static func performDebugAction(id: String) {
        ConsoleDockDebugActionRegistry.shared.perform(id: id)
    }
}
