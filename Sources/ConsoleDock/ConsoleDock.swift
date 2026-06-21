import ConsoleDockCore
import Foundation

public enum ConsoleDock {
    public struct Configuration: Equatable {
        public var maximumEntries: Int
        public var captureStandardOutput: Bool
        public var captureStandardError: Bool
        public var showsFloatingButton: Bool
        public var allowsReleaseBuilds: Bool

        public init(
            maximumEntries: Int = 2_000,
            captureStandardOutput: Bool = true,
            captureStandardError: Bool = true,
            showsFloatingButton: Bool = true,
            allowsReleaseBuilds: Bool = false
        ) {
            self.maximumEntries = maximumEntries
            self.captureStandardOutput = captureStandardOutput
            self.captureStandardError = captureStandardError
            self.showsFloatingButton = showsFloatingButton
            self.allowsReleaseBuilds = allowsReleaseBuilds
        }

        public static let `default` = Configuration()

        func makeCoreConfiguration() -> CDKConfiguration {
            let configuration = CDKConfiguration()
            configuration.maximumEntries = UInt(maximumEntries)
            configuration.captureStandardOutput = captureStandardOutput
            configuration.captureStandardError = captureStandardError
            configuration.showsFloatingButton = showsFloatingButton
            configuration.allowsReleaseBuilds = allowsReleaseBuilds
            return configuration
        }
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
        return StartResult(coreResult: result, error: error)
    }

    public static func stop() {
        CDKConsoleDock.stop()
    }

    public static var isRunning: Bool {
        CDKConsoleDock.isRunning()
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
