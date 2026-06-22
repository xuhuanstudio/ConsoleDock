import ConsoleDockCore
import Foundation

public enum ConsoleDock {
    public struct Configuration: Equatable {
        public var maximumEntries: Int
        public var maximumMessageLength: Int
        public var captureStandardOutput: Bool
        public var captureStandardError: Bool
        public var showsFloatingButton: Bool
        public var allowsReleaseBuilds: Bool
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

    public enum LogLevel: Equatable {
        case debug
        case info
        case warning
        case error
        case fault
    }

    public enum LogSource: Equatable {
        case native
        case stdout
        case stderr
    }

    public struct LogEntry: Equatable {
        public let timestamp: Date
        public let level: LogLevel
        public let source: LogSource
        public let message: String
    }

    public enum StartResult: Equatable {
        case started
        case alreadyRunning
        case disabled
        case failed(StartFailure)
    }

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

    public static func stop() {
        CDKConsoleDock.stop()
        teardownUIIfAvailable()
    }

    public static var isRunning: Bool {
        CDKConsoleDock.isRunning()
    }

    public static var entries: [LogEntry] {
        CDKConsoleDock.entries().map(LogEntry.init(coreEntry:))
    }

    public static let entriesDidChangeNotification = Notification.Name.CDKConsoleDockEntriesDidChange

    public static func clear() {
        CDKConsoleDock.clearEntries()
    }

    public static func showConsole() {
        guard isRunning else { return }
        showConsoleIfAvailable()
    }

    public static func hideConsole() {
        hideConsoleIfAvailable()
    }

    public static func debug(_ message: String) {
        CDKConsoleDock.debug(message)
    }

    public static func info(_ message: String) {
        CDKConsoleDock.info(message)
    }

    public static func warning(_ message: String) {
        CDKConsoleDock.warning(message)
    }

    public static func error(_ message: String) {
        CDKConsoleDock.error(message)
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
