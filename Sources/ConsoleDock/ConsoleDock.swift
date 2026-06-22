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
            allowsReleaseBuilds: Bool = false,
            redactor: ((String) -> String)? = nil
        ) {
            self.maximumEntries = maximumEntries
            self.maximumMessageLength = maximumMessageLength
            self.captureStandardOutput = captureStandardOutput
            self.captureStandardError = captureStandardError
            self.showsFloatingButton = showsFloatingButton
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
        if shouldInstallUI(startResult: startResult, configuration: configuration) {
            installUIIfAvailable()
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

    /// Notification posted after entries are appended, reset, or cleared.
    public static let entriesDidChangeNotification = Notification.Name.CDKConsoleDockEntriesDidChange
    /// Notification posted after diagnostics values may have changed.
    public static let diagnosticsDidChangeNotification = Notification.Name.CDKConsoleDockDiagnosticsDidChange

    /// Clears the in-memory entry store.
    public static func clear() {
        CDKConsoleDock.clearEntries()
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

    /// Appends a native debug entry.
    public static func debug(_ message: String) {
        CDKConsoleDock.debug(message)
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
    static func shouldInstallUI(startResult: StartResult, configuration: Configuration) -> Bool {
        configuration.showsFloatingButton && (startResult == .started || startResult == .alreadyRunning)
    }
}

extension ConsoleDock {
    fileprivate static func installUIIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.install()
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

extension ConsoleDock.LogLevel {
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
