@testable import ConsoleDock
import ConsoleDockCore
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
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .alreadyRunning)

        ConsoleDock.stop()
        ConsoleDock.stop()

        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testObjectiveCUIKitFacadeStartStopLifecycle() {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false

        XCTAssertEqual(ConsoleDockUIKit.start(configuration: configuration, error: nil), .started)
        XCTAssertTrue(ConsoleDockUIKit.isRunning())

        ConsoleDockUIKit.showConsole()
        ConsoleDockUIKit.hideConsole()
        ConsoleDockUIKit.stop()

        XCTAssertFalse(ConsoleDockUIKit.isRunning())
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

    func testEntriesDidChangeNotificationNameIsExposed() {
        XCTAssertEqual(ConsoleDock.entriesDidChangeNotification.rawValue, "CDKConsoleDockEntriesDidChangeNotification")
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
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

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

    func testSnapshotFormatterExportsStablePlainText() {
        let generatedAt = Date(timeIntervalSince1970: 0)
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1.25),
                level: .info,
                source: .native,
                message: "native token=<redacted>"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2.5),
                level: .error,
                source: .stderr,
                message: "line one\nline two"
            )
        ]

        let snapshot = ConsoleDockSnapshotFormatter.snapshotText(entries: entries, generatedAt: generatedAt)

        XCTAssertEqual(
            snapshot,
            """
            ConsoleDock Log Snapshot
            Generated: 1970-01-01T00:00:00.000Z
            Entries: 2

            [1970-01-01T00:00:01.250Z] [native] [INFO] native token=<redacted>
            [1970-01-01T00:00:02.500Z] [stderr] [ERROR] line one\\nline two
            """
        )
    }

    func testSnapshotFormatterHandlesEmptyEntries() {
        let snapshot = ConsoleDockSnapshotFormatter.snapshotText(
            entries: [],
            generatedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(
            snapshot,
            """
            ConsoleDock Log Snapshot
            Generated: 1970-01-01T00:00:00.000Z
            Entries: 0

            (no entries)
            """
        )
    }

    func testSwiftConfigurationBridgesStoreLimitsAndRedactor() {
        let configuration = ConsoleDock.Configuration(
            maximumEntries: 1,
            maximumMessageLength: 6,
            captureStandardOutput: false,
            captureStandardError: false,
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

    func testEntriesObserverDeliversInitialSnapshot() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.info("initial")

        let expectation = expectation(description: "Initial snapshot delivered")
        var snapshots: [[ConsoleDock.LogEntry]] = []
        let observer = ConsoleDockEntriesObserver(deliveryQueue: .main) { snapshot in
            snapshots.append(snapshot)
            expectation.fulfill()
        }
        defer { observer.invalidate() }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(snapshots.last?.map(\.message), ["initial"])
    }

    func testEntriesObserverRefreshesAfterAppend() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        let initialExpectation = expectation(description: "Initial empty snapshot delivered")
        let appendExpectation = expectation(description: "Append snapshot delivered")
        var didSeeInitialSnapshot = false
        var snapshots: [[ConsoleDock.LogEntry]] = []
        let observer = ConsoleDockEntriesObserver(deliveryQueue: .main) { snapshot in
            snapshots.append(snapshot)
            if !didSeeInitialSnapshot {
                didSeeInitialSnapshot = true
                initialExpectation.fulfill()
            } else if snapshot.map(\.message) == ["appended"] {
                appendExpectation.fulfill()
            }
        }
        defer { observer.invalidate() }

        wait(for: [initialExpectation], timeout: 1.0)
        ConsoleDock.info("appended")
        wait(for: [appendExpectation], timeout: 1.0)

        XCTAssertEqual(snapshots.last?.map(\.message), ["appended"])
    }

    func testEntriesObserverStopsAfterInvalidate() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        let initialExpectation = expectation(description: "Initial snapshot delivered")
        let unexpectedExpectation = expectation(description: "No snapshot after invalidate")
        unexpectedExpectation.isInverted = true
        var didSeeInitialSnapshot = false
        let observer = ConsoleDockEntriesObserver(deliveryQueue: .main) { _ in
            if !didSeeInitialSnapshot {
                didSeeInitialSnapshot = true
                initialExpectation.fulfill()
            } else {
                unexpectedExpectation.fulfill()
            }
        }

        wait(for: [initialExpectation], timeout: 1.0)
        observer.invalidate()
        ConsoleDock.info("after invalidate")
        wait(for: [unexpectedExpectation], timeout: 0.2)
    }
}

private extension ConsoleDock.Configuration {
    static let nativeOnly = ConsoleDock.Configuration(
        captureStandardOutput: false,
        captureStandardError: false
    )
}
