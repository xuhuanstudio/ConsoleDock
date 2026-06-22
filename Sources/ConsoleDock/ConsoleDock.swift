import ConsoleDockCore
import Foundation

/// App-facing Swift facade for starting ConsoleDock and writing native log entries.
public enum ConsoleDock {
    /// Runtime options for the local in-app console.
    public struct Configuration: Equatable {
        /// Maximum number of entries retained in memory before oldest entries are evicted.
        public var maximumEntries: Int
        /// Maximum stored message length after redaction.
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
            lhs.maximumEntries == rhs.maximumEntries &&
                lhs.maximumMessageLength == rhs.maximumMessageLength &&
                lhs.captureStandardOutput == rhs.captureStandardOutput &&
                lhs.captureStandardError == rhs.captureStandardError &&
                lhs.showsFloatingButton == rhs.showsFloatingButton &&
                lhs.allowsReleaseBuilds == rhs.allowsReleaseBuilds &&
                (lhs.redactor == nil) == (rhs.redactor == nil)
        }

        func makeCoreConfiguration() -> CDKConfiguration {
            let configuration = CDKConfiguration()
            configuration.maximumEntries = UInt(maximumEntries)
            configuration.maximumMessageLength = UInt(maximumMessageLength)
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
    public struct LogEntry: Equatable {
        public let timestamp: Date
        public let level: LogLevel
        public let source: LogSource
        public let message: String
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
        if case .started = startResult, configuration.showsFloatingButton {
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

    /// Notification posted after entries are appended, reset, or cleared.
    public static let entriesDidChangeNotification = Notification.Name.CDKConsoleDockEntriesDidChange

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

private extension ConsoleDock {
    static func installUIIfAvailable() {
        #if canImport(UIKit)
        ConsoleDockUIController.shared.install()
        #endif
    }

    static func teardownUIIfAvailable() {
        #if canImport(UIKit)
        ConsoleDockUIController.shared.teardown()
        #endif
    }

    static func showConsoleIfAvailable() {
        #if canImport(UIKit)
        ConsoleDockUIController.shared.showConsole()
        #endif
    }

    static func hideConsoleIfAvailable() {
        #if canImport(UIKit)
        ConsoleDockUIController.shared.hideConsole()
        #endif
    }
}

private extension ConsoleDock.LogEntry {
    init(coreEntry: CDKLogEntry) {
        timestamp = coreEntry.timestamp
        level = ConsoleDock.LogLevel(coreLevel: coreEntry.level)
        source = ConsoleDock.LogSource(coreSource: coreEntry.source)
        message = coreEntry.message
    }
}

private extension ConsoleDock.LogLevel {
    init(coreLevel: CDKLogLevel) {
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

private extension ConsoleDock.LogSource {
    init(coreSource: CDKLogSource) {
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

private extension ConsoleDock.StartResult {
    init(coreResult: CDKStartResult, error: NSError?) {
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
