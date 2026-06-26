import Foundation

struct ConsoleDockDebugAction: Equatable, Identifiable {
    let id: String
    let title: String
    let group: String?
    let detail: String?
    let requiresConfirmation: Bool
    let isEnabled: Bool
    let style: ConsoleDock.DebugActionStyle
    let parameters: [ConsoleDock.DebugActionParameter]

    init(
        id: String,
        title: String,
        group: String? = nil,
        detail: String? = nil,
        requiresConfirmation: Bool = false,
        isEnabled: Bool = true,
        style: ConsoleDock.DebugActionStyle = .normal,
        parameters: [ConsoleDock.DebugActionParameter] = []
    ) {
        self.id = id
        self.title = title
        self.group = group
        self.detail = detail
        self.requiresConfirmation = requiresConfirmation
        self.isEnabled = isEnabled
        self.style = style
        self.parameters = parameters
    }
}

extension Notification.Name {
    static let consoleDockDebugActionsDidChange = Notification.Name("ConsoleDockDebugActionsDidChangeNotification")
}

final class ConsoleDockDebugActionRegistry {
    typealias Handler = (ConsoleDock.DebugActionParameters) throws -> Void

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
        handler: @escaping () throws -> Void
    ) {
        register(
            id: id,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style,
            parameters: []
        ) { _ in
            try handler()
        }
    }

    func register(
        id: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        isEnabled: Bool,
        style: ConsoleDock.DebugActionStyle,
        parameters: [ConsoleDock.DebugActionParameter],
        handler: @escaping Handler
    ) {
        guard let normalizedID = normalizedRequired(id),
            let normalizedTitle = normalizedRequired(title)
        else {
            return
        }

        let normalizedParameters = normalizedParameters(parameters)
        let action = ConsoleDockDebugAction(
            id: normalizedID,
            title: normalizedTitle,
            group: normalizedSingleLineOptional(group),
            detail: normalizedOptional(detail),
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style,
            parameters: normalizedParameters
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

    func perform(id: String, parameterValues: [String: ConsoleDock.DebugActionParameterValue]? = nil) {
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

        let resolution = resolvedParameters(for: record.action, suppliedValues: parameterValues)
        if !resolution.missingRequiredParameterIDs.isEmpty {
            let missingText = resolution.missingRequiredParameterIDs.joined(separator: ", ")
            ConsoleDock.info(
                "Debug action skipped: \(record.action.title) [\(record.action.id)] missing required parameters: \(missingText)"
            )
            return
        }

        let run = {
            ConsoleDock.info("Debug action started: \(record.action.title) [\(record.action.id)]")
            do {
                try record.handler(resolution.parameters)
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

    private func normalizedParameters(
        _ parameters: [ConsoleDock.DebugActionParameter]
    ) -> [ConsoleDock.DebugActionParameter] {
        var result: [ConsoleDock.DebugActionParameter] = []
        var seenIDs = Set<String>()
        for parameter in parameters {
            guard let id = normalizedRequired(parameter.id),
                let title = normalizedRequired(parameter.title),
                !seenIDs.contains(id),
                let kind = normalizedKind(parameter.kind),
                let defaultValue = normalizedDefaultValue(parameter.defaultValue, kind: kind)
            else {
                continue
            }

            seenIDs.insert(id)
            result.append(
                ConsoleDock.DebugActionParameter(
                    id: id,
                    title: title,
                    detail: normalizedOptional(parameter.detail),
                    isRequired: parameter.isRequired,
                    defaultValue: defaultValue,
                    kind: kind
                )
            )
        }
        return result
    }

    private func normalizedKind(
        _ kind: ConsoleDock.DebugActionParameter.Kind
    ) -> ConsoleDock.DebugActionParameter.Kind? {
        switch kind {
        case .string, .number, .bool:
            return kind
        case .choice(let choices):
            var normalizedChoices: [ConsoleDock.DebugActionChoice] = []
            var seenIDs = Set<String>()
            for choice in choices {
                guard let id = normalizedRequired(choice.id),
                    let title = normalizedRequired(choice.title),
                    !seenIDs.contains(id)
                else {
                    continue
                }
                seenIDs.insert(id)
                normalizedChoices.append(ConsoleDock.DebugActionChoice(id: id, title: title))
            }
            return normalizedChoices.isEmpty ? nil : .choice(normalizedChoices)
        }
    }

    private func normalizedDefaultValue(
        _ value: ConsoleDock.DebugActionParameterValue?,
        kind: ConsoleDock.DebugActionParameter.Kind
    ) -> ConsoleDock.DebugActionParameterValue?? {
        guard let value else { return .some(nil) }
        return normalizedValue(value, kind: kind).map(Optional.some) ?? nil
    }

    private func resolvedParameters(
        for action: ConsoleDockDebugAction,
        suppliedValues: [String: ConsoleDock.DebugActionParameterValue]?
    ) -> (parameters: ConsoleDock.DebugActionParameters, missingRequiredParameterIDs: [String]) {
        var values: [String: ConsoleDock.DebugActionParameterValue] = [:]
        var missingRequiredIDs: [String] = []

        for parameter in action.parameters {
            let suppliedValue = suppliedValues?[parameter.id]
            let rawValue = suppliedValue ?? parameter.defaultValue
            guard let rawValue else {
                if parameter.isRequired {
                    missingRequiredIDs.append(parameter.id)
                }
                continue
            }

            guard let normalizedValue = normalizedValue(rawValue, kind: parameter.kind) else {
                if parameter.isRequired {
                    missingRequiredIDs.append(parameter.id)
                }
                continue
            }
            values[parameter.id] = normalizedValue
        }

        return (ConsoleDock.DebugActionParameters(values), missingRequiredIDs)
    }

    private func normalizedValue(
        _ value: ConsoleDock.DebugActionParameterValue,
        kind: ConsoleDock.DebugActionParameter.Kind
    ) -> ConsoleDock.DebugActionParameterValue? {
        switch (kind, value) {
        case (.string, .string(let text)):
            guard let normalized = normalizedRequired(text) else { return nil }
            return .string(normalized)
        case (.number, .number(let number)):
            guard number.isFinite else { return nil }
            return .number(number)
        case (.bool, .bool(let flag)):
            return .bool(flag)
        case (.choice(let choices), .choice(let choiceID)):
            guard let normalizedID = normalizedRequired(choiceID),
                choices.contains(where: { $0.id == normalizedID })
            else {
                return nil
            }
            return .choice(normalizedID)
        default:
            return nil
        }
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

    static func performDebugAction(
        id: String,
        parameterValues: [String: ConsoleDock.DebugActionParameterValue]? = nil
    ) {
        ConsoleDockDebugActionRegistry.shared.perform(id: id, parameterValues: parameterValues)
    }
}
