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
    private var executions: [ConsoleDock.DebugActionExecution] = []
    private var recentParameterValues: [String: [String: ConsoleDock.DebugActionParameterValue]] = [:]
    private var nextExecutionID: UInt64 = 1

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
        let changed = !records.isEmpty || !executions.isEmpty || !recentParameterValues.isEmpty
        records.removeAll()
        executions.removeAll()
        recentParameterValues.removeAll()
        nextExecutionID = 1
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

    func executionHistory() -> [ConsoleDock.DebugActionExecution] {
        lock.lock()
        let snapshot = executions
        lock.unlock()
        return snapshot
    }

    func clearExecutionHistory() {
        lock.lock()
        executions.removeAll()
        nextExecutionID = 1
        lock.unlock()
    }

    func resetSessionState() {
        lock.lock()
        executions.removeAll()
        recentParameterValues.removeAll()
        nextExecutionID = 1
        lock.unlock()
    }

    func recentParameters(actionID: String) -> [String: ConsoleDock.DebugActionParameterValue] {
        guard let normalizedID = normalizedRequired(actionID) else { return [:] }

        lock.lock()
        let values = recentParameterValues[normalizedID] ?? [:]
        lock.unlock()
        return values
    }

    func storeRecentParameters(actionID: String, values: [String: ConsoleDock.DebugActionParameterValue]) {
        guard let normalizedID = normalizedRequired(actionID) else { return }

        lock.lock()
        if values.isEmpty {
            recentParameterValues.removeValue(forKey: normalizedID)
        } else {
            recentParameterValues[normalizedID] = values
        }
        lock.unlock()
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
            let now = Date()
            appendExecution(
                action: record.action,
                startedAt: now,
                completedAt: now,
                outcome: .skipped,
                parameterSummary: nil,
                message: "disabled"
            )
            return
        }

        let resolution = resolvedParameters(for: record.action, suppliedValues: parameterValues)
        let parameterSummary = parameterSummary(for: record.action, parameters: resolution.parameters)
        if !resolution.missingRequiredParameterIDs.isEmpty {
            let missingText = resolution.missingRequiredParameterIDs.joined(separator: ", ")
            ConsoleDock.info(
                "Debug action skipped: \(record.action.title) [\(record.action.id)] missing required parameters: \(missingText)"
            )
            let now = Date()
            appendExecution(
                action: record.action,
                startedAt: now,
                completedAt: now,
                outcome: .skipped,
                parameterSummary: parameterSummary,
                message: "missing required parameters: \(missingText)"
            )
            return
        }

        let run = {
            let startedAt = Date()
            ConsoleDock.info("Debug action started: \(record.action.title) [\(record.action.id)]")
            do {
                try record.handler(resolution.parameters)
                ConsoleDock.info("Debug action completed: \(record.action.title) [\(record.action.id)]")
                self.appendExecution(
                    action: record.action,
                    startedAt: startedAt,
                    completedAt: Date(),
                    outcome: .completed,
                    parameterSummary: parameterSummary,
                    message: nil
                )
            } catch {
                let message = "error=\(error)"
                ConsoleDock.error(
                    "Debug action failed: \(record.action.title) [\(record.action.id)] \(message)"
                )
                self.appendExecution(
                    action: record.action,
                    startedAt: startedAt,
                    completedAt: Date(),
                    outcome: .failed,
                    parameterSummary: parameterSummary,
                    message: message
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

    private func appendExecution(
        action: ConsoleDockDebugAction,
        startedAt: Date,
        completedAt: Date,
        outcome: ConsoleDock.DebugActionExecutionOutcome,
        parameterSummary: String?,
        message: String?
    ) {
        lock.lock()
        let execution = ConsoleDock.DebugActionExecution(
            id: nextExecutionID,
            actionID: action.id,
            title: action.title,
            group: action.group,
            startedAt: startedAt,
            completedAt: completedAt,
            outcome: outcome,
            parameterSummary: parameterSummary,
            message: message.map(singleLine)
        )
        nextExecutionID += 1
        executions.append(execution)
        lock.unlock()
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

    private func parameterSummary(
        for action: ConsoleDockDebugAction,
        parameters: ConsoleDock.DebugActionParameters
    ) -> String? {
        var parts: [String] = []
        let values = parameters.allValues
        for parameter in action.parameters {
            guard let value = values[parameter.id] else { continue }
            parts.append("\(parameter.id)=\(parameterValueText(value))")
        }
        guard !parts.isEmpty else { return nil }
        return truncated(singleLine(parts.joined(separator: ", ")), maximumLength: 240)
    }

    private func parameterValueText(_ value: ConsoleDock.DebugActionParameterValue) -> String {
        switch value {
        case .string(let text):
            return "\"\(truncated(singleLine(text), maximumLength: 48))\""
        case .number(let number):
            if number.rounded() == number, number >= Double(Int64.min), number <= Double(Int64.max) {
                return String(Int64(number))
            }
            return truncated(String(number), maximumLength: 32)
        case .bool(let flag):
            return flag ? "true" : "false"
        case .choice(let choiceID):
            return truncated(singleLine(choiceID), maximumLength: 48)
        }
    }

    private func truncated(_ value: String, maximumLength: Int) -> String {
        guard value.count > maximumLength else { return value }
        let endIndex = value.index(value.startIndex, offsetBy: maximumLength)
        return String(value[..<endIndex]) + "..."
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

    static func recentDebugActionParameterValues(
        actionID: String
    ) -> [String: ConsoleDock.DebugActionParameterValue] {
        ConsoleDockDebugActionRegistry.shared.recentParameters(actionID: actionID)
    }

    static func storeRecentDebugActionParameterValues(
        actionID: String,
        parameterValues: [String: ConsoleDock.DebugActionParameterValue]
    ) {
        ConsoleDockDebugActionRegistry.shared.storeRecentParameters(actionID: actionID, values: parameterValues)
    }
}
