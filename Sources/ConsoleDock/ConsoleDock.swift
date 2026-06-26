import ConsoleDockCore
import Foundation

/// App-facing Swift facade for starting ConsoleDock and writing native log entries.
public enum ConsoleDock {
    /// Runtime options for the local in-app console.
    public struct Configuration: Equatable {
        /// Maximum number of entries retained in memory before oldest entries are evicted. Must be greater than zero.
        public var maximumEntries: Int
        /// Maximum stored message length after redaction. Must be greater than zero.
        public var maximumMessageLength: Int
        /// Captures stdout writes from the app process when enabled.
        public var captureStandardOutput: Bool
        /// Captures stderr writes from the app process when enabled.
        public var captureStandardError: Bool
        /// Installs the bundled UIKit floating button when UIKit is available.
        public var showsFloatingButton: Bool
        /// Initial corner for the bundled UIKit floating button.
        public var floatingButtonPosition: FloatingButtonPosition
        /// Allows ConsoleDock to start in Release builds only when the app also defines CONSOLEDOCK_ENABLE_RELEASE.
        public var allowsReleaseBuilds: Bool
        /// Optional app-specific redaction hook. The default redactor runs before this closure.
        public var redactor: ((String) -> String)?

        public init(
            maximumEntries: Int = 2_000,
            maximumMessageLength: Int = 8_192,
            captureStandardOutput: Bool = true,
            captureStandardError: Bool = true,
            showsFloatingButton: Bool = true,
            floatingButtonPosition: FloatingButtonPosition = .bottomTrailing,
            allowsReleaseBuilds: Bool = false,
            redactor: ((String) -> String)? = nil
        ) {
            self.maximumEntries = maximumEntries
            self.maximumMessageLength = maximumMessageLength
            self.captureStandardOutput = captureStandardOutput
            self.captureStandardError = captureStandardError
            self.showsFloatingButton = showsFloatingButton
            self.floatingButtonPosition = floatingButtonPosition
            self.allowsReleaseBuilds = allowsReleaseBuilds
            self.redactor = redactor
        }

        /// The debug-safe default configuration.
        public static let `default` = Configuration()

        public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.maximumEntries == rhs.maximumEntries && lhs.maximumMessageLength == rhs.maximumMessageLength
                && lhs.captureStandardOutput == rhs.captureStandardOutput
                && lhs.captureStandardError == rhs.captureStandardError
                && lhs.showsFloatingButton == rhs.showsFloatingButton
                && lhs.floatingButtonPosition == rhs.floatingButtonPosition
                && lhs.allowsReleaseBuilds == rhs.allowsReleaseBuilds
                && (lhs.redactor == nil) == (rhs.redactor == nil)
        }

        func makeCoreConfiguration() -> CDKConfiguration {
            let configuration = CDKConfiguration()
            configuration.maximumEntries = UInt(max(0, maximumEntries))
            configuration.maximumMessageLength = UInt(max(0, maximumMessageLength))
            configuration.captureStandardOutput = captureStandardOutput
            configuration.captureStandardError = captureStandardError
            configuration.showsFloatingButton = showsFloatingButton
            configuration.floatingButtonPosition = floatingButtonPosition.corePosition
            configuration.allowsReleaseBuilds = allowsReleaseBuilds
            if let redactor {
                configuration.redactionBlock = { message in
                    redactor(message)
                }
            }
            return configuration
        }
    }

    /// Severity stored with a ConsoleDock entry.
    public enum LogLevel: Equatable {
        case debug
        case info
        case warning
        case error
        case fault
    }

    /// Visual and semantic treatment for a local debug action.
    public enum DebugActionStyle: Equatable {
        case normal
        case destructive
    }

    /// A single choice option for a local parameterized debug action.
    public struct DebugActionChoice: Equatable {
        public let id: String
        public let title: String

        public init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    /// A typed value supplied to a local parameterized debug action.
    public enum DebugActionParameterValue: Equatable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case choice(String)
    }

    /// A parameter definition for a local debug action.
    public struct DebugActionParameter: Equatable {
        public enum Kind: Equatable {
            case string
            case number
            case bool
            case choice([DebugActionChoice])
        }

        public let id: String
        public let title: String
        public let detail: String?
        public let isRequired: Bool
        public let defaultValue: DebugActionParameterValue?
        public let kind: Kind

        public static func string(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: String? = nil
        ) -> DebugActionParameter {
            DebugActionParameter(
                id: id,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue.map(DebugActionParameterValue.string),
                kind: .string
            )
        }

        public static func number(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: Double? = nil
        ) -> DebugActionParameter {
            DebugActionParameter(
                id: id,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue.map(DebugActionParameterValue.number),
                kind: .number
            )
        }

        public static func bool(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: Bool? = nil
        ) -> DebugActionParameter {
            DebugActionParameter(
                id: id,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultValue.map(DebugActionParameterValue.bool),
                kind: .bool
            )
        }

        public static func choice(
            id: String,
            title: String,
            choices: [DebugActionChoice],
            detail: String? = nil,
            isRequired: Bool = false,
            defaultChoiceID: String? = nil
        ) -> DebugActionParameter {
            DebugActionParameter(
                id: id,
                title: title,
                detail: detail,
                isRequired: isRequired,
                defaultValue: defaultChoiceID.map(DebugActionParameterValue.choice),
                kind: .choice(choices)
            )
        }
    }

    /// Normalized parameter values supplied when a local debug action runs.
    public struct DebugActionParameters: Equatable {
        private let storage: [String: DebugActionParameterValue]

        public init(_ values: [String: DebugActionParameterValue] = [:]) {
            storage = values
        }

        public func value(_ id: String) -> DebugActionParameterValue? {
            storage[id]
        }

        public func string(_ id: String) -> String? {
            if case .string(let value)? = storage[id] {
                return value
            }
            return nil
        }

        public func number(_ id: String) -> Double? {
            if case .number(let value)? = storage[id] {
                return value
            }
            return nil
        }

        public func bool(_ id: String) -> Bool? {
            if case .bool(let value)? = storage[id] {
                return value
            }
            return nil
        }

        public func choice(_ id: String) -> String? {
            if case .choice(let value)? = storage[id] {
                return value
            }
            return nil
        }

        var allValues: [String: DebugActionParameterValue] {
            storage
        }
    }

    /// One app-owned context value for local issue reports and the bundled context panel.
    public struct AppContextItem: Equatable {
        public let key: String
        public let value: String

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    /// A section of app-owned context values.
    public struct AppContextSection: Equatable {
        public let title: String
        public let items: [AppContextItem]

        public init(title: String, items: [AppContextItem]) {
            self.title = title
            self.items = items
        }
    }

    /// Initial corner for the bundled UIKit floating button.
    public enum FloatingButtonPosition: Equatable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    /// Where a ConsoleDock entry came from.
    public enum LogSource: Equatable {
        case native
        case stdout
        case stderr
    }

    /// A redacted log entry retained in ConsoleDock's in-memory store.
    public struct LogEntry: Equatable, Identifiable {
        /// Stable identifier assigned when the entry is stored in the current ConsoleDock session.
        public let id: UInt64
        public let timestamp: Date
        public let level: LogLevel
        public let source: LogSource
        public let message: String
        /// Whether this entry was flushed from an incomplete framed line.
        public let partial: Bool
        /// Whether ConsoleDock changed the message while applying default or app-specific redaction.
        public let redacted: Bool
        /// Whether ConsoleDock shortened the message to respect `maximumMessageLength`.
        public let truncated: Bool

        public init(
            id: UInt64 = 0,
            timestamp: Date,
            level: LogLevel,
            source: LogSource,
            message: String,
            partial: Bool = false,
            redacted: Bool = false,
            truncated: Bool = false
        ) {
            self.id = id
            self.timestamp = timestamp
            self.level = level
            self.source = source
            self.message = message
            self.partial = partial
            self.redacted = redacted
            self.truncated = truncated
        }
    }

    /// Lightweight sink for forwarding existing app logger output into ConsoleDock.
    public struct LogForwarder {
        /// Optional single-line category prefix added to forwarded messages.
        public let category: String?
        /// Lowest severity forwarded into ConsoleDock.
        public let minimumLevel: LogLevel

        public init(category: String? = nil, minimumLevel: LogLevel = .debug) {
            self.category = Self.normalizedCategory(category)
            self.minimumLevel = minimumLevel
        }

        /// Forwards a message to ConsoleDock when the level is at or above minimumLevel.
        public func log(level: LogLevel, message: String) {
            guard level.isAtLeast(minimumLevel) else { return }
            ConsoleDock.log(level: level, message: formattedMessage(message))
        }

        /// Forwards a debug message when enabled by minimumLevel.
        public func debug(_ message: String) {
            log(level: .debug, message: message)
        }

        /// Forwards an info message when enabled by minimumLevel.
        public func info(_ message: String) {
            log(level: .info, message: message)
        }

        /// Forwards a warning message when enabled by minimumLevel.
        public func warning(_ message: String) {
            log(level: .warning, message: message)
        }

        /// Forwards an error message when enabled by minimumLevel.
        public func error(_ message: String) {
            log(level: .error, message: message)
        }

        /// Forwards a fault message when enabled by minimumLevel.
        public func fault(_ message: String) {
            log(level: .fault, message: message)
        }

        private func formattedMessage(_ message: String) -> String {
            guard let category else { return message }
            return "[\(category)] \(message)"
        }

        private static func normalizedCategory(_ value: String?) -> String? {
            guard let value else {
                return nil
            }

            let withoutCRLF = value.replacingOccurrences(of: "\r\n", with: " ")
            let withoutLF = withoutCRLF.replacingOccurrences(of: "\n", with: " ")
            let withoutCR = withoutLF.replacingOccurrences(of: "\r", with: " ")
            let trimmed = withoutCR.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    /// Snapshot of ConsoleDock runtime configuration and current in-memory store counts.
    public struct Diagnostics: Equatable {
        /// Whether ConsoleDock is currently running and able to append new entries.
        public let isRunning: Bool
        /// Whether stdout capture is enabled in the effective configuration.
        public let capturesStandardOutput: Bool
        /// Whether stderr capture is enabled in the effective configuration.
        public let capturesStandardError: Bool
        /// Whether the effective configuration requests the bundled UIKit floating button.
        public let showsFloatingButton: Bool
        /// Whether the effective runtime configuration allows Release startup when compiled with CONSOLEDOCK_ENABLE_RELEASE.
        public let allowsReleaseBuilds: Bool
        /// Maximum number of entries retained in memory before oldest entries are evicted.
        public let maximumEntries: Int
        /// Maximum stored message length after redaction.
        public let maximumMessageLength: Int
        /// Current number of entries in the bounded in-memory store.
        public let entryCount: Int
        /// Number of currently stored entries marked redacted.
        public let redactedEntryCount: Int
        /// Number of currently stored entries marked truncated.
        public let truncatedEntryCount: Int
        /// Number of currently stored entries flushed from incomplete lines.
        public let partialEntryCount: Int

        public init(
            isRunning: Bool,
            capturesStandardOutput: Bool,
            capturesStandardError: Bool,
            showsFloatingButton: Bool,
            allowsReleaseBuilds: Bool,
            maximumEntries: Int,
            maximumMessageLength: Int,
            entryCount: Int,
            redactedEntryCount: Int,
            truncatedEntryCount: Int,
            partialEntryCount: Int
        ) {
            self.isRunning = isRunning
            self.capturesStandardOutput = capturesStandardOutput
            self.capturesStandardError = capturesStandardError
            self.showsFloatingButton = showsFloatingButton
            self.allowsReleaseBuilds = allowsReleaseBuilds
            self.maximumEntries = maximumEntries
            self.maximumMessageLength = maximumMessageLength
            self.entryCount = entryCount
            self.redactedEntryCount = redactedEntryCount
            self.truncatedEntryCount = truncatedEntryCount
            self.partialEntryCount = partialEntryCount
        }
    }

    /// Local app and device context for the current ConsoleDock session.
    public struct SessionMetadata: Equatable {
        /// Stable identifier for the current ConsoleDock runtime session.
        public let sessionIdentifier: String
        /// Time when ConsoleDock most recently started successfully, or nil before the first successful start.
        public let startedAt: Date?
        /// Time when this metadata snapshot was generated.
        public let generatedAt: Date
        /// Main bundle identifier, when available.
        public let bundleIdentifier: String?
        /// Main bundle short version string, when available.
        public let appVersion: String?
        /// Main bundle build version string, when available.
        public let appBuild: String?
        /// Current process name.
        public let processName: String
        /// Operating system version string from ProcessInfo.
        public let operatingSystemVersion: String
        /// Device model on UIKit platforms, otherwise unknown.
        public let deviceModel: String
        /// Current locale identifier.
        public let localeIdentifier: String
        /// Current time zone identifier.
        public let timeZoneIdentifier: String

        public init(
            sessionIdentifier: String,
            startedAt: Date?,
            generatedAt: Date,
            bundleIdentifier: String?,
            appVersion: String?,
            appBuild: String?,
            processName: String,
            operatingSystemVersion: String,
            deviceModel: String,
            localeIdentifier: String,
            timeZoneIdentifier: String
        ) {
            self.sessionIdentifier = sessionIdentifier
            self.startedAt = startedAt
            self.generatedAt = generatedAt
            self.bundleIdentifier = bundleIdentifier
            self.appVersion = appVersion
            self.appBuild = appBuild
            self.processName = processName
            self.operatingSystemVersion = operatingSystemVersion
            self.deviceModel = deviceModel
            self.localeIdentifier = localeIdentifier
            self.timeZoneIdentifier = timeZoneIdentifier
        }
    }

    /// Startup result returned by `start(configuration:)`.
    public enum StartResult: Equatable {
        case started
        case alreadyRunning
        case disabled
        case failed(StartFailure)
    }

    /// Error information returned when ConsoleDock fails to start.
    public struct StartFailure: Equatable {
        public let domain: String
        public let code: Int
        public let message: String

        public init(domain: String, code: Int, message: String) {
            self.domain = domain
            self.code = code
            self.message = message
        }

        init(error: NSError) {
            domain = error.domain
            code = error.code
            message = error.localizedDescription
        }

        static let unknown = StartFailure(
            domain: "CDKConsoleDockErrorDomain",
            code: -1,
            message: "ConsoleDock failed to start, but the core did not provide an NSError."
        )
    }

    /// Starts ConsoleDock with local in-memory storage, redaction, optional stdout/stderr capture, and optional UIKit UI.
    @discardableResult
    public static func start(configuration: Configuration = .default) -> StartResult {
        var error: NSError?
        let result = CDKConsoleDock.start(with: configuration.makeCoreConfiguration(), error: &error)
        let startResult = StartResult(coreResult: result, error: error)
        if shouldConfigureUI(startResult: startResult) {
            configureUIIfAvailable(configuration: configuration)
        }
        return startResult
    }

    /// Stops ConsoleDock and tears down capture/UI state.
    public static func stop() {
        CDKConsoleDock.stop()
        teardownUIIfAvailable()
    }

    /// Whether ConsoleDock is currently running.
    public static var isRunning: Bool {
        CDKConsoleDock.isRunning()
    }

    /// Snapshot of the current in-memory entries.
    public static var entries: [LogEntry] {
        CDKConsoleDock.entries().map(LogEntry.init(coreEntry:))
    }

    /// Snapshot of runtime configuration and current in-memory store counts.
    public static var diagnostics: Diagnostics {
        Diagnostics(coreDiagnostics: CDKConsoleDock.diagnostics())
    }

    /// Snapshot of local session and app metadata for issue reports.
    public static var sessionMetadata: SessionMetadata {
        SessionMetadata(coreMetadata: CDKConsoleDock.sessionMetadata())
    }

    /// Snapshot of app-owned local context for issue reports and the bundled context panel.
    public static var appContext: [AppContextSection] {
        ConsoleDockAppContextRegistry.shared.snapshot()
    }

    /// Notification posted after entries are appended, reset, or cleared.
    public static let entriesDidChangeNotification = Notification.Name.CDKConsoleDockEntriesDidChange
    /// Notification posted after diagnostics values may have changed.
    public static let diagnosticsDidChangeNotification = Notification.Name.CDKConsoleDockDiagnosticsDidChange

    /// Clears the in-memory entry store.
    public static func clear() {
        CDKConsoleDock.clearEntries()
    }

    /// Builds a local issue report with session metadata, diagnostics, markers, and all retained entries.
    public static func issueReportText() -> String {
        ConsoleDockIssueReportFormatter.reportText(
            entries: entries,
            metadata: sessionMetadata,
            diagnostics: diagnostics,
            appContext: appContext
        )
    }

    /// Sets an app-owned local context provider for issue reports and the bundled context panel.
    public static func setAppContextProvider(_ provider: @escaping () -> [AppContextSection]) {
        ConsoleDockAppContextRegistry.shared.setProvider(provider)
    }

    /// Clears the app-owned local context provider.
    public static func clearAppContextProvider() {
        ConsoleDockAppContextRegistry.shared.clearProvider()
    }

    /// Shows the bundled UIKit console when ConsoleDock is running and UIKit is available.
    public static func showConsole() {
        guard isRunning else { return }
        showConsoleIfAvailable()
    }

    /// Hides the bundled UIKit console when UIKit is available.
    public static func hideConsole() {
        hideConsoleIfAvailable()
    }

    /// Shows the bundled UIKit floating trigger when ConsoleDock is running and UIKit is available.
    public static func showFloatingButton() {
        guard isRunning else { return }
        showFloatingButtonIfAvailable()
    }

    /// Hides the bundled UIKit floating trigger without stopping ConsoleDock.
    public static func hideFloatingButton() {
        hideFloatingButtonIfAvailable()
    }

    /// Registers a local debug action shown by the bundled UIKit console.
    public static func registerAction(
        id: String,
        title: String,
        group: String? = nil,
        detail: String? = nil,
        requiresConfirmation: Bool = false,
        isEnabled: Bool = true,
        style: DebugActionStyle = .normal,
        handler: @escaping () throws -> Void
    ) {
        ConsoleDockDebugActionRegistry.shared.register(
            id: id,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style,
            handler: handler
        )
    }

    /// Registers a local debug action that asks for local parameters before running.
    public static func registerAction(
        id: String,
        title: String,
        group: String? = nil,
        detail: String? = nil,
        requiresConfirmation: Bool = false,
        isEnabled: Bool = true,
        style: DebugActionStyle = .normal,
        parameters: [DebugActionParameter],
        handler: @escaping (DebugActionParameters) throws -> Void
    ) {
        ConsoleDockDebugActionRegistry.shared.register(
            id: id,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style,
            parameters: parameters,
            handler: handler
        )
    }

    /// Removes a previously registered local debug action.
    public static func unregisterAction(id: String) {
        ConsoleDockDebugActionRegistry.shared.unregister(id: id)
    }

    /// Removes all registered local debug actions.
    public static func removeAllActions() {
        ConsoleDockDebugActionRegistry.shared.removeAll()
    }

    /// Appends a native debug entry.
    public static func debug(_ message: String) {
        CDKConsoleDock.debug(message)
    }

    /// Appends a native entry at a specific level.
    public static func log(level: LogLevel, message: String) {
        CDKConsoleDock.log(with: level.coreLevel, message: message)
    }

    /// Appends a native marker entry for a local test session timeline.
    public static func mark(_ message: String) {
        CDKConsoleDock.mark(message)
    }

    /// Appends a native info entry.
    public static func info(_ message: String) {
        CDKConsoleDock.info(message)
    }

    /// Appends a native warning entry.
    public static func warning(_ message: String) {
        CDKConsoleDock.warning(message)
    }

    /// Appends a native error entry.
    public static func error(_ message: String) {
        CDKConsoleDock.error(message)
    }

    /// Appends a native fault entry.
    public static func fault(_ message: String) {
        CDKConsoleDock.fault(message)
    }
}

extension ConsoleDock {
    static func shouldConfigureUI(startResult: StartResult) -> Bool {
        startResult == .started || startResult == .alreadyRunning
    }
}

extension ConsoleDock {
    fileprivate static func configureUIIfAvailable(configuration: Configuration) {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.configure(
                floatingButtonPosition: configuration.floatingButtonPosition,
                showsFloatingButton: configuration.showsFloatingButton
            )
        #endif
    }

    fileprivate static func teardownUIIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.teardown()
        #endif
    }

    fileprivate static func showConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showConsole()
        #endif
    }

    fileprivate static func hideConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideConsole()
        #endif
    }

    fileprivate static func showFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showFloatingButton()
        #endif
    }

    fileprivate static func hideFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideFloatingButton()
        #endif
    }
}

extension ConsoleDock.LogEntry {
    fileprivate init(coreEntry: CDKLogEntry) {
        id = coreEntry.identifier
        timestamp = coreEntry.timestamp
        level = ConsoleDock.LogLevel(coreLevel: coreEntry.level)
        source = ConsoleDock.LogSource(coreSource: coreEntry.source)
        message = coreEntry.message
        partial = coreEntry.isPartial
        redacted = coreEntry.redacted
        truncated = coreEntry.truncated
    }
}

extension ConsoleDock.Diagnostics {
    fileprivate init(coreDiagnostics: CDKDiagnostics) {
        isRunning = coreDiagnostics.isRunning
        capturesStandardOutput = coreDiagnostics.captureStandardOutput
        capturesStandardError = coreDiagnostics.captureStandardError
        showsFloatingButton = coreDiagnostics.showsFloatingButton
        allowsReleaseBuilds = coreDiagnostics.allowsReleaseBuilds
        maximumEntries = Int(coreDiagnostics.maximumEntries)
        maximumMessageLength = Int(coreDiagnostics.maximumMessageLength)
        entryCount = Int(coreDiagnostics.entryCount)
        redactedEntryCount = Int(coreDiagnostics.redactedEntryCount)
        truncatedEntryCount = Int(coreDiagnostics.truncatedEntryCount)
        partialEntryCount = Int(coreDiagnostics.partialEntryCount)
    }
}

extension ConsoleDock.SessionMetadata {
    fileprivate init(coreMetadata: CDKSessionMetadata) {
        sessionIdentifier = coreMetadata.sessionIdentifier
        startedAt = coreMetadata.startedAt
        generatedAt = coreMetadata.generatedAt
        bundleIdentifier = coreMetadata.bundleIdentifier
        appVersion = coreMetadata.appVersion
        appBuild = coreMetadata.appBuild
        processName = coreMetadata.processName
        operatingSystemVersion = coreMetadata.operatingSystemVersion
        deviceModel = coreMetadata.deviceModel
        localeIdentifier = coreMetadata.localeIdentifier
        timeZoneIdentifier = coreMetadata.timeZoneIdentifier
    }
}

extension ConsoleDock.LogLevel {
    fileprivate var rank: Int {
        switch self {
        case .debug:
            return 0
        case .info:
            return 1
        case .warning:
            return 2
        case .error:
            return 3
        case .fault:
            return 4
        }
    }

    fileprivate func isAtLeast(_ minimumLevel: ConsoleDock.LogLevel) -> Bool {
        rank >= minimumLevel.rank
    }

    fileprivate var coreLevel: CDKLogLevel {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }

    fileprivate init(coreLevel: CDKLogLevel) {
        switch coreLevel {
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .warning:
            self = .warning
        case .error:
            self = .error
        case .fault:
            self = .fault
        @unknown default:
            self = .debug
        }
    }
}

extension ConsoleDock.FloatingButtonPosition {
    fileprivate var corePosition: CDKFloatingButtonPosition {
        switch self {
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }

    init(corePosition: CDKFloatingButtonPosition) {
        switch corePosition {
        case .topLeading:
            self = .topLeading
        case .topTrailing:
            self = .topTrailing
        case .bottomLeading:
            self = .bottomLeading
        case .bottomTrailing:
            self = .bottomTrailing
        @unknown default:
            self = .bottomTrailing
        }
    }
}

extension ConsoleDock.LogSource {
    fileprivate init(coreSource: CDKLogSource) {
        switch coreSource {
        case .native:
            self = .native
        case .stdout:
            self = .stdout
        case .stderr:
            self = .stderr
        @unknown default:
            self = .native
        }
    }
}

extension ConsoleDock.StartResult {
    fileprivate init(coreResult: CDKStartResult, error: NSError?) {
        switch coreResult {
        case .started:
            self = .started
        case .alreadyRunning:
            self = .alreadyRunning
        case .disabled:
            self = .disabled
        case .failed:
            self = .failed(error.map(ConsoleDock.StartFailure.init(error:)) ?? .unknown)
        @unknown default:
            self = .failed(error.map(ConsoleDock.StartFailure.init(error:)) ?? .unknown)
        }
    }
}
