import ConsoleDockCore
import Foundation

/// Objective-C-visible style for a local debug action.
@objc(CDKDebugActionStyle)
public enum ConsoleDockDebugActionStyle: Int {
    case normal = 0
    case destructive = 1

    var swiftStyle: ConsoleDock.DebugActionStyle {
        switch self {
        case .normal:
            return .normal
        case .destructive:
            return .destructive
        @unknown default:
            return .normal
        }
    }
}

/// Objective-C-visible choice option for a local parameterized debug action.
@objc(CDKDebugActionChoice)
public final class ConsoleDockDebugActionChoice: NSObject {
    @objc public let identifier: String
    @objc public let title: String

    @objc(initWithIdentifier:title:)
    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }

    @objc(choiceWithIdentifier:title:)
    public static func choice(identifier: String, title: String) -> ConsoleDockDebugActionChoice {
        ConsoleDockDebugActionChoice(identifier: identifier, title: title)
    }

    var swiftChoice: ConsoleDock.DebugActionChoice {
        ConsoleDock.DebugActionChoice(id: identifier, title: title)
    }
}

/// Objective-C-visible parameter definition for a local debug action.
@objc(CDKDebugActionParameter)
public final class ConsoleDockDebugActionParameter: NSObject {
    @objc public let identifier: String
    @objc public let title: String
    @objc public let detail: String?
    @objc public let isRequired: Bool

    private let swiftParameter: ConsoleDock.DebugActionParameter

    private init(
        identifier: String,
        title: String,
        detail: String?,
        isRequired: Bool,
        swiftParameter: ConsoleDock.DebugActionParameter
    ) {
        self.identifier = identifier
        self.title = title
        self.detail = detail
        self.isRequired = isRequired
        self.swiftParameter = swiftParameter
    }

    @objc(stringParameterWithIdentifier:title:detail:isRequired:defaultValue:)
    public static func stringParameter(
        identifier: String,
        title: String,
        detail: String?,
        isRequired: Bool,
        defaultValue: String?
    ) -> ConsoleDockDebugActionParameter {
        ConsoleDockDebugActionParameter(
            identifier: identifier,
            title: title,
            detail: detail,
            isRequired: isRequired,
            swiftParameter: .string(
                id: identifier,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue
            )
        )
    }

    @objc(numberParameterWithIdentifier:title:detail:isRequired:defaultValue:)
    public static func numberParameter(
        identifier: String,
        title: String,
        detail: String?,
        isRequired: Bool,
        defaultValue: NSNumber?
    ) -> ConsoleDockDebugActionParameter {
        ConsoleDockDebugActionParameter(
            identifier: identifier,
            title: title,
            detail: detail,
            isRequired: isRequired,
            swiftParameter: .number(
                id: identifier,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue?.doubleValue
            )
        )
    }

    @objc(boolParameterWithIdentifier:title:detail:isRequired:defaultValue:)
    public static func boolParameter(
        identifier: String,
        title: String,
        detail: String?,
        isRequired: Bool,
        defaultValue: NSNumber?
    ) -> ConsoleDockDebugActionParameter {
        ConsoleDockDebugActionParameter(
            identifier: identifier,
            title: title,
            detail: detail,
            isRequired: isRequired,
            swiftParameter: .bool(
                id: identifier,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue?.boolValue
            )
        )
    }

    @objc(choiceParameterWithIdentifier:title:detail:isRequired:choices:defaultChoiceIdentifier:)
    public static func choiceParameter(
        identifier: String,
        title: String,
        detail: String?,
        isRequired: Bool,
        choices: [ConsoleDockDebugActionChoice],
        defaultChoiceIdentifier: String?
    ) -> ConsoleDockDebugActionParameter {
        ConsoleDockDebugActionParameter(
            identifier: identifier,
            title: title,
            detail: detail,
            isRequired: isRequired,
            swiftParameter: .choice(
                id: identifier,
                title: title,
                choices: choices.map(\.swiftChoice),
                detail: detail,
                isRequired: isRequired,
                defaultChoiceID: defaultChoiceIdentifier
            )
        )
    }

    var swiftDebugActionParameter: ConsoleDock.DebugActionParameter {
        swiftParameter
    }
}

/// Objective-C-visible app context item for local issue reports.
@objc(CDKAppContextItem)
public final class ConsoleDockAppContextItem: NSObject {
    @objc public let key: String
    @objc public let value: String

    @objc(initWithKey:value:)
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    @objc(itemWithKey:value:)
    public static func item(key: String, value: String) -> ConsoleDockAppContextItem {
        ConsoleDockAppContextItem(key: key, value: value)
    }

    var swiftItem: ConsoleDock.AppContextItem {
        ConsoleDock.AppContextItem(key: key, value: value)
    }
}

/// Objective-C-visible app context section for local issue reports.
@objc(CDKAppContextSection)
public final class ConsoleDockAppContextSection: NSObject {
    @objc public let title: String
    @objc public let items: [ConsoleDockAppContextItem]

    @objc(initWithTitle:items:)
    public init(title: String, items: [ConsoleDockAppContextItem]) {
        self.title = title
        self.items = items
    }

    @objc(sectionWithTitle:items:)
    public static func section(title: String, items: [ConsoleDockAppContextItem]) -> ConsoleDockAppContextSection {
        ConsoleDockAppContextSection(title: title, items: items)
    }

    var swiftSection: ConsoleDock.AppContextSection {
        ConsoleDock.AppContextSection(title: title, items: items.map(\.swiftItem))
    }
}

/// Objective-C-visible saved local session archive.
@objc(CDKSessionArchive)
public final class ConsoleDockSessionArchive: NSObject {
    @objc public let identifier: String
    @objc public let createdAt: Date
    @objc public let sourceSessionIdentifier: String
    @objc public let sourceSessionStartedAt: Date?
    @objc public let title: String
    @objc public let note: String?
    @objc public let entryCount: Int
    @objc public let reportCharacterCount: Int
    @objc public let isReportTruncated: Bool
    @objc public let reportText: String

    @objc(
        initWithIdentifier:createdAt:sourceSessionIdentifier:sourceSessionStartedAt:title:note:entryCount:
        reportCharacterCount:isReportTruncated:reportText:
    )
    public init(
        identifier: String,
        createdAt: Date,
        sourceSessionIdentifier: String,
        sourceSessionStartedAt: Date?,
        title: String,
        note: String?,
        entryCount: Int,
        reportCharacterCount: Int,
        isReportTruncated: Bool,
        reportText: String
    ) {
        self.identifier = identifier
        self.createdAt = createdAt
        self.sourceSessionIdentifier = sourceSessionIdentifier
        self.sourceSessionStartedAt = sourceSessionStartedAt
        self.title = title
        self.note = note
        self.entryCount = entryCount
        self.reportCharacterCount = reportCharacterCount
        self.isReportTruncated = isReportTruncated
        self.reportText = reportText
    }

    init(archive: ConsoleDock.SessionArchive) {
        identifier = archive.id
        createdAt = archive.createdAt
        sourceSessionIdentifier = archive.sourceSessionIdentifier
        sourceSessionStartedAt = archive.sourceSessionStartedAt
        title = archive.title
        note = archive.note
        entryCount = archive.entryCount
        reportCharacterCount = archive.reportCharacterCount
        isReportTruncated = archive.isReportTruncated
        reportText = archive.reportText
    }
}

/// Objective-C-visible on-demand local support report.
@objc(CDKSupportReport)
public final class ConsoleDockSupportReport: NSObject {
    @objc public let generatedAt: Date
    @objc public let timeRangeDescription: String
    @objc public let includedEntryCount: Int
    @objc public let omittedEntryCount: Int
    @objc public let includedActionExecutionCount: Int
    @objc public let omittedActionExecutionCount: Int
    @objc public let reportCharacterCount: Int
    @objc public let isReportTruncated: Bool
    @objc public let text: String

    @objc(
        initWithGeneratedAt:timeRangeDescription:includedEntryCount:omittedEntryCount:
        includedActionExecutionCount:omittedActionExecutionCount:reportCharacterCount:isReportTruncated:text:
    )
    public init(
        generatedAt: Date,
        timeRangeDescription: String,
        includedEntryCount: Int,
        omittedEntryCount: Int,
        includedActionExecutionCount: Int,
        omittedActionExecutionCount: Int,
        reportCharacterCount: Int,
        isReportTruncated: Bool,
        text: String
    ) {
        self.generatedAt = generatedAt
        self.timeRangeDescription = timeRangeDescription
        self.includedEntryCount = includedEntryCount
        self.omittedEntryCount = omittedEntryCount
        self.includedActionExecutionCount = includedActionExecutionCount
        self.omittedActionExecutionCount = omittedActionExecutionCount
        self.reportCharacterCount = reportCharacterCount
        self.isReportTruncated = isReportTruncated
        self.text = text
    }

    init(report: ConsoleDock.SupportReport) {
        generatedAt = report.generatedAt
        timeRangeDescription = report.timeRangeDescription
        includedEntryCount = report.includedEntryCount
        omittedEntryCount = report.omittedEntryCount
        includedActionExecutionCount = report.includedActionExecutionCount
        omittedActionExecutionCount = report.omittedActionExecutionCount
        reportCharacterCount = report.reportCharacterCount
        isReportTruncated = report.isReportTruncated
        text = report.text
    }
}

/// Objective-C-callable facade for using ConsoleDock with the bundled UIKit console.
@objc(CDKConsoleDockUIKit)
public final class ConsoleDockUIKit: NSObject {
    /// Starts ConsoleDock and installs the floating UIKit button when configured.
    @discardableResult
    @objc(startWithConfiguration:error:)
    public static func start(configuration: CDKConfiguration?, error: NSErrorPointer) -> CDKStartResult {
        let result = CDKConsoleDock.start(with: configuration, error: error)
        if shouldConfigureUI(result: result) {
            configureUIIfAvailable(configuration: configuration ?? CDKConfiguration())
        }
        return result
    }

    /// Stops ConsoleDock and tears down the bundled UIKit console.
    @objc(stop)
    public static func stop() {
        CDKConsoleDock.stop()
        teardownUIIfAvailable()
    }

    /// Whether ConsoleDock is currently running.
    @objc(isRunning)
    public static func isRunning() -> Bool {
        CDKConsoleDock.isRunning()
    }

    /// Shows the bundled UIKit console when ConsoleDock is running.
    @objc(showConsole)
    public static func showConsole() {
        guard CDKConsoleDock.isRunning() else { return }
        showConsoleIfAvailable()
    }

    /// Hides the bundled UIKit console.
    @objc(hideConsole)
    public static func hideConsole() {
        hideConsoleIfAvailable()
    }

    /// Shows the bundled UIKit floating trigger when ConsoleDock is running.
    @objc(showFloatingButton)
    public static func showFloatingButton() {
        guard CDKConsoleDock.isRunning() else { return }
        showFloatingButtonIfAvailable()
    }

    /// Hides the bundled UIKit floating trigger without stopping ConsoleDock.
    @objc(hideFloatingButton)
    public static func hideFloatingButton() {
        hideFloatingButtonIfAvailable()
    }

    /// Builds a local issue report with session metadata, diagnostics, markers, and all retained entries.
    @objc(issueReportText)
    public static func issueReportText() -> String {
        ConsoleDock.issueReportText()
    }

    /// Builds an on-demand local support report for the last number of minutes.
    @objc(supportReportWithLastMinutes:maximumReportCharacterCount:)
    public static func supportReport(
        lastMinutes: Int,
        maximumReportCharacterCount: Int
    ) -> ConsoleDockSupportReport {
        ConsoleDockSupportReport(
            report: ConsoleDock.supportReport(
                options: supportReportOptions(
                    lastMinutes: lastMinutes,
                    maximumReportCharacterCount: maximumReportCharacterCount
                )
            )
        )
    }

    /// Builds an on-demand local support report between two dates.
    @objc(supportReportFromDate:toDate:maximumReportCharacterCount:)
    public static func supportReport(
        from fromDate: Date,
        to toDate: Date,
        maximumReportCharacterCount: Int
    ) -> ConsoleDockSupportReport {
        ConsoleDockSupportReport(
            report: ConsoleDock.supportReport(
                options: supportReportOptions(
                    timeRange: .range(from: fromDate, to: toDate),
                    maximumReportCharacterCount: maximumReportCharacterCount
                )
            )
        )
    }

    /// Builds a temporary local support-report text file for the last number of minutes.
    @objc(makeTemporarySupportReportFileWithLastMinutes:maximumReportCharacterCount:error:)
    public static func makeTemporarySupportReportFile(
        lastMinutes: Int,
        maximumReportCharacterCount: Int,
        error errorPointer: NSErrorPointer
    ) -> URL? {
        do {
            return try ConsoleDock.makeTemporarySupportReportFile(
                options: supportReportOptions(
                    lastMinutes: lastMinutes,
                    maximumReportCharacterCount: maximumReportCharacterCount
                )
            )
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }

    /// Builds a temporary local support-report text file between two dates.
    @objc(makeTemporarySupportReportFileFromDate:toDate:maximumReportCharacterCount:error:)
    public static func makeTemporarySupportReportFile(
        from fromDate: Date,
        to toDate: Date,
        maximumReportCharacterCount: Int,
        error errorPointer: NSErrorPointer
    ) -> URL? {
        do {
            return try ConsoleDock.makeTemporarySupportReportFile(
                options: supportReportOptions(
                    timeRange: .range(from: fromDate, to: toDate),
                    maximumReportCharacterCount: maximumReportCharacterCount
                )
            )
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }

    /// Builds a local integration diagnosis for debugging ConsoleDock setup and capture coverage.
    @objc(integrationDiagnosisText)
    public static func integrationDiagnosisText() -> String {
        ConsoleDock.integrationDiagnosisText()
    }

    /// Saves the current local issue report as a bounded app-local archive.
    @objc(saveSessionArchiveWithNote:error:)
    public static func saveSessionArchive(
        note: String?,
        error errorPointer: NSErrorPointer
    ) -> ConsoleDockSessionArchive? {
        do {
            return ConsoleDockSessionArchive(archive: try ConsoleDock.saveSessionArchive(note: note))
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }

    /// Returns saved local session archives, newest first.
    @objc(sessionArchivesWithError:)
    public static func sessionArchives(error errorPointer: NSErrorPointer) -> [ConsoleDockSessionArchive]? {
        do {
            return try ConsoleDock.sessionArchives().map(ConsoleDockSessionArchive.init(archive:))
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }

    /// Deletes one saved local session archive. Missing archive ids are ignored.
    @objc(deleteSessionArchiveWithIdentifier:error:)
    public static func deleteSessionArchive(
        identifier: String,
        error errorPointer: NSErrorPointer
    ) -> Bool {
        do {
            try ConsoleDock.deleteSessionArchive(id: identifier)
            return true
        } catch {
            errorPointer?.pointee = error as NSError
            return false
        }
    }

    /// Deletes all saved local session archives.
    @objc(clearSessionArchivesWithError:)
    public static func clearSessionArchives(error errorPointer: NSErrorPointer) -> Bool {
        do {
            try ConsoleDock.clearSessionArchives()
            return true
        } catch {
            errorPointer?.pointee = error as NSError
            return false
        }
    }

    /// Sets an app-owned local context provider for issue reports and the bundled context panel.
    @objc(setAppContextProvider:)
    public static func setAppContextProvider(_ provider: @escaping () -> [ConsoleDockAppContextSection]) {
        ConsoleDock.setAppContextProvider {
            provider().map(\.swiftSection)
        }
    }

    /// Clears the app-owned local context provider.
    @objc(clearAppContextProvider)
    public static func clearAppContextProvider() {
        ConsoleDock.clearAppContextProvider()
    }

    /// Registers a local debug action shown by the bundled UIKit console.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        handler: @escaping () -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: true,
            style: .normal
        ) {
            handler()
        }
    }

    /// Registers a local parameterized debug action shown by the bundled UIKit console.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:parameters:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        parameters: [ConsoleDockDebugActionParameter],
        handler: @escaping ([String: Any]) -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: true,
            style: .normal,
            parameters: parameters.map(\.swiftDebugActionParameter)
        ) { values in
            handler(objectiveCParameterValues(values))
        }
    }

    /// Registers a local debug action with explicit enabled state and UI style.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:isEnabled:style:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        isEnabled: Bool,
        style: ConsoleDockDebugActionStyle,
        handler: @escaping () -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style.swiftStyle
        ) {
            handler()
        }
    }

    /// Registers a local parameterized debug action with explicit enabled state and UI style.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:isEnabled:style:parameters:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        isEnabled: Bool,
        style: ConsoleDockDebugActionStyle,
        parameters: [ConsoleDockDebugActionParameter],
        handler: @escaping ([String: Any]) -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style.swiftStyle,
            parameters: parameters.map(\.swiftDebugActionParameter)
        ) { values in
            handler(objectiveCParameterValues(values))
        }
    }

    /// Removes a previously registered local debug action.
    @objc(unregisterActionWithIdentifier:)
    public static func unregisterAction(identifier: String) {
        ConsoleDock.unregisterAction(id: identifier)
    }

    /// Removes all registered local debug actions.
    @objc(removeAllActions)
    public static func removeAllActions() {
        ConsoleDock.removeAllActions()
    }

    private static func objectiveCParameterValues(_ values: ConsoleDock.DebugActionParameters) -> [String: Any] {
        values.allValues.mapValues { value in
            switch value {
            case .string(let text):
                return text
            case .number(let number):
                return NSNumber(value: number)
            case .bool(let flag):
                return NSNumber(value: flag)
            case .choice(let choiceID):
                return choiceID
            }
        }
    }

    private static func supportReportOptions(
        lastMinutes: Int,
        maximumReportCharacterCount: Int
    ) -> ConsoleDock.SupportReportOptions {
        supportReportOptions(
            timeRange: .last(minutes: lastMinutes),
            maximumReportCharacterCount: maximumReportCharacterCount
        )
    }

    private static func supportReportOptions(
        timeRange: ConsoleDock.SupportReportTimeRange,
        maximumReportCharacterCount: Int
    ) -> ConsoleDock.SupportReportOptions {
        ConsoleDock.SupportReportOptions(
            timeRange: timeRange,
            maximumReportCharacterCount: maximumReportCharacterCount > 0
                ? maximumReportCharacterCount
                : ConsoleDock.SupportReportOptions.defaultMaximumReportCharacterCount
        )
    }

    private static func shouldConfigureUI(result: CDKStartResult) -> Bool {
        result == .started || result == .alreadyRunning
    }

    private static func configureUIIfAvailable(configuration: CDKConfiguration) {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.configure(
                floatingButtonPosition: ConsoleDock.FloatingButtonPosition(
                    corePosition: configuration.floatingButtonPosition
                ),
                showsFloatingButton: configuration.showsFloatingButton
            )
        #endif
    }

    private static func teardownUIIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.teardown()
        #endif
    }

    private static func showConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showConsole()
        #endif
    }

    private static func hideConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideConsole()
        #endif
    }

    private static func showFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showFloatingButton()
        #endif
    }

    private static func hideFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideFloatingButton()
        #endif
    }
}
