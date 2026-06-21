@testable import ConsoleDock
import XCTest

final class ConsoleDockTests: XCTestCase {
    override func tearDown() {
        ConsoleDock.clear()
        ConsoleDock.stop()
        super.tearDown()
    }

    func testSwiftFacadeStartStopLifecycle() {
        XCTAssertEqual(ConsoleDock.start(), .started)
        XCTAssertTrue(ConsoleDock.isRunning)

        ConsoleDock.stop()

        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testSwiftFacadeRepeatedStartAndStop() {
        XCTAssertEqual(ConsoleDock.start(), .started)
        XCTAssertEqual(ConsoleDock.start(), .alreadyRunning)

        ConsoleDock.stop()
        ConsoleDock.stop()

        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testConfigurationDefaultsMatchCoreDefaults() {
        let configuration = ConsoleDock.Configuration.default

        XCTAssertEqual(configuration.maximumEntries, 2_000)
        XCTAssertEqual(configuration.maximumMessageLength, 8_192)
        XCTAssertTrue(configuration.captureStandardOutput)
        XCTAssertTrue(configuration.captureStandardError)
        XCTAssertTrue(configuration.showsFloatingButton)
        XCTAssertFalse(configuration.allowsReleaseBuilds)
    }

    func testInvalidConfigurationMapsToFailure() {
        let configuration = ConsoleDock.Configuration(maximumEntries: 0)

        let result = ConsoleDock.start(configuration: configuration)

        guard case let .failed(failure) = result else {
            return XCTFail("Expected invalid configuration to fail, got \(result)")
        }

        XCTAssertEqual(failure.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(failure.code, 1)
        XCTAssertEqual(failure.message, "maximumEntries must be greater than zero")
        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testLoggingAPIsAreSafeNoOpsWhenNotRunning() {
        ConsoleDock.debug("debug")
        ConsoleDock.info("info")
        ConsoleDock.warning("warning")
        ConsoleDock.error("error")

        XCTAssertFalse(ConsoleDock.isRunning)
        XCTAssertTrue(ConsoleDock.entries.isEmpty)
    }

    func testSwiftFacadeLogReadAndClear() {
        XCTAssertEqual(ConsoleDock.start(), .started)

        ConsoleDock.debug("debug")
        ConsoleDock.info("info")
        ConsoleDock.warning("warning")
        ConsoleDock.error("error")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.map(\.level), [.debug, .info, .warning, .error])
        XCTAssertEqual(entries.map(\.source), [.native, .native, .native, .native])
        XCTAssertEqual(entries.map(\.message), ["debug", "info", "warning", "error"])

        ConsoleDock.clear()

        XCTAssertTrue(ConsoleDock.entries.isEmpty)
    }

    func testSwiftConfigurationBridgesStoreLimitsAndRedactor() {
        let configuration = ConsoleDock.Configuration(
            maximumEntries: 1,
            maximumMessageLength: 6,
            redactor: { message in
                message.replacingOccurrences(of: "private", with: "public")
            }
        )
        XCTAssertEqual(ConsoleDock.start(configuration: configuration), .started)

        ConsoleDock.info("first")
        ConsoleDock.error("private-value")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].level, .error)
        XCTAssertEqual(entries[0].source, .native)
        XCTAssertEqual(entries[0].message, "public")
    }
}
