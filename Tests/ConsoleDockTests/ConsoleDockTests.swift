import ConsoleDockCore
import XCTest

@testable import ConsoleDock

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

    func testSwiftFacadeCanAttachUIWhenCoreIsAlreadyRunning() {
        XCTAssertEqual(CDKConsoleDock.start(with: CDKConfiguration.default()), .started)

        let result = ConsoleDock.start(configuration: .default)

        XCTAssertEqual(result, .alreadyRunning)
        XCTAssertTrue(ConsoleDock.shouldInstallUI(startResult: result, configuration: .default))
    }

    func testSwiftFacadeDoesNotAttachUIWhenDisabledByConfiguration() {
        let configuration = ConsoleDock.Configuration(showsFloatingButton: false)

        XCTAssertFalse(ConsoleDock.shouldInstallUI(startResult: .started, configuration: configuration))
        XCTAssertFalse(ConsoleDock.shouldInstallUI(startResult: .alreadyRunning, configuration: configuration))
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

    func testSwiftDiagnosticsMapsCoreFields() {
        let configuration = ConsoleDock.Configuration(
            maximumEntries: 9,
            maximumMessageLength: 12,
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: false,
            allowsReleaseBuilds: true,
            redactor: { message in
                message.replacingOccurrences(of: "secret", with: "public")
            }
        )
        XCTAssertEqual(ConsoleDock.start(configuration: configuration), .started)

        ConsoleDock.info("secret-token")
        CDKConsoleDock.append(CDKLineEvent(source: .stderr, message: "partial", isPartial: true))

        let diagnostics = ConsoleDock.diagnostics
        XCTAssertTrue(diagnostics.isRunning)
        XCTAssertFalse(diagnostics.capturesStandardOutput)
        XCTAssertFalse(diagnostics.capturesStandardError)
        XCTAssertFalse(diagnostics.showsFloatingButton)
        XCTAssertTrue(diagnostics.allowsReleaseBuilds)
        XCTAssertEqual(diagnostics.maximumEntries, 9)
        XCTAssertEqual(diagnostics.maximumMessageLength, 12)
        XCTAssertEqual(diagnostics.entryCount, 2)
        XCTAssertEqual(diagnostics.redactedEntryCount, 1)
        XCTAssertEqual(diagnostics.truncatedEntryCount, 0)
        XCTAssertEqual(diagnostics.partialEntryCount, 1)
    }

    func testEntriesDidChangeNotificationNameIsExposed() {
        XCTAssertEqual(ConsoleDock.entriesDidChangeNotification.rawValue, "CDKConsoleDockEntriesDidChangeNotification")
    }

    func testDiagnosticsDidChangeNotificationNameIsExposed() {
        XCTAssertEqual(
            ConsoleDock.diagnosticsDidChangeNotification.rawValue,
            "CDKConsoleDockDiagnosticsDidChangeNotification"
        )
    }

    func testInvalidConfigurationMapsToFailure() {
        let configuration = ConsoleDock.Configuration(maximumEntries: 0)

        let result = ConsoleDock.start(configuration: configuration)

        guard case .failed(let failure) = result else {
            return XCTFail("Expected invalid configuration to fail, got \(result)")
        }

        XCTAssertEqual(failure.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(failure.code, 1)
        XCTAssertEqual(failure.message, "maximumEntries must be greater than zero")
        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testNegativeEntryLimitMapsToFailureWithoutCrashing() {
        let configuration = ConsoleDock.Configuration(maximumEntries: -1)

        let result = ConsoleDock.start(configuration: configuration)

        guard case .failed(let failure) = result else {
            return XCTFail("Expected negative entry limit to fail, got \(result)")
        }

        XCTAssertEqual(failure.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(failure.code, 1)
        XCTAssertEqual(failure.message, "maximumEntries must be greater than zero")
        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testNegativeMessageLengthMapsToFailureWithoutCrashing() {
        let configuration = ConsoleDock.Configuration(maximumMessageLength: -1)

        let result = ConsoleDock.start(configuration: configuration)

        guard case .failed(let failure) = result else {
            return XCTFail("Expected negative message length to fail, got \(result)")
        }

        XCTAssertEqual(failure.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(failure.code, 2)
        XCTAssertEqual(failure.message, "maximumMessageLength must be greater than zero")
        XCTAssertFalse(ConsoleDock.isRunning)
    }

    func testLoggingAPIsAreSafeNoOpsWhenNotRunning() {
        ConsoleDock.debug("debug")
        ConsoleDock.info("info")
        ConsoleDock.warning("warning")
        ConsoleDock.error("error")
        ConsoleDock.fault("fault")

        XCTAssertFalse(ConsoleDock.isRunning)
        XCTAssertTrue(ConsoleDock.entries.isEmpty)
    }

    func testSwiftFacadeLogReadAndClear() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.debug("debug")
        ConsoleDock.info("info")
        ConsoleDock.warning("warning")
        ConsoleDock.error("error")
        ConsoleDock.fault("fault")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.map(\.level), [.debug, .info, .warning, .error, .fault])
        XCTAssertEqual(entries.map(\.source), [.native, .native, .native, .native, .native])
        XCTAssertEqual(entries.map(\.message), ["debug", "info", "warning", "error", "fault"])

        ConsoleDock.clear()

        XCTAssertTrue(ConsoleDock.entries.isEmpty)
    }

    func testSwiftFacadeEntriesExposeStableIdentifiers() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.info("first")
        ConsoleDock.error("second")

        XCTAssertEqual(ConsoleDock.entries.map(\.id), [1, 2])
    }

    func testSwiftFacadeEntriesExposePartialLineMetadata() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "partial", isPartial: true))

        XCTAssertEqual(ConsoleDock.entries.first?.message, "partial")
        XCTAssertEqual(ConsoleDock.entries.first?.partial, true)
    }

    func testSwiftLogEntryInitializerDefaultsIdentifierForFixtures() {
        let entry = ConsoleDock.LogEntry(
            timestamp: Date(timeIntervalSince1970: 1),
            level: .info,
            source: .native,
            message: "fixture"
        )

        XCTAssertEqual(entry.id, 0)
        XCTAssertEqual(entry.message, "fixture")
        XCTAssertFalse(entry.partial)
        XCTAssertFalse(entry.redacted)
        XCTAssertFalse(entry.truncated)
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

    func testSnapshotFormatterIncludesDiagnosticsWhenProvided() {
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: true,
            capturesStandardOutput: true,
            capturesStandardError: false,
            showsFloatingButton: true,
            allowsReleaseBuilds: false,
            maximumEntries: 2_000,
            maximumMessageLength: 8_192,
            entryCount: 3,
            redactedEntryCount: 1,
            truncatedEntryCount: 1,
            partialEntryCount: 1
        )
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1.25),
                level: .info,
                source: .native,
                message: "visible"
            )
        ]

        let snapshot = ConsoleDockSnapshotFormatter.snapshotText(
            entries: entries,
            generatedAt: Date(timeIntervalSince1970: 0),
            diagnostics: diagnostics,
            visibleEntryCount: entries.count
        )

        XCTAssertEqual(
            snapshot,
            """
            ConsoleDock Log Snapshot
            Generated: 1970-01-01T00:00:00.000Z
            Entries: 3
            Visible Entries: 1
            Diagnostics:
              Running: true
              stdout: enabled
              stderr: disabled
              Floating Button: enabled
              Release Builds: disabled by runtime config
              Limits: entries=2000 messageLength=8192
              Redacted: 1
              Truncated: 1
              Partial: 1

            [1970-01-01T00:00:01.250Z] [native] [INFO] visible
            """
        )
    }

    func testDiagnosticsStatusTextIsCompactAndSafe() {
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: false,
            capturesStandardOutput: true,
            capturesStandardError: true,
            showsFloatingButton: false,
            allowsReleaseBuilds: false,
            maximumEntries: 10,
            maximumMessageLength: 256,
            entryCount: 8,
            redactedEntryCount: 2,
            truncatedEntryCount: 1,
            partialEntryCount: 3
        )

        XCTAssertEqual(
            ConsoleDockDiagnosticsFormatter.statusText(
                diagnostics: diagnostics,
                visibleEntryCount: 5,
                isPaused: true
            ),
            """
            Running: off  Entries: 8 visible 5  stdout: on  stderr: on
            Limits: entries=10 messageLength=256  redacted=2 truncated=1 partial=3  live: paused
            """
        )
    }

    func testSnapshotFormatterFormatsSingleEntryForCopy() {
        let entry = ConsoleDock.LogEntry(
            timestamp: Date(timeIntervalSince1970: 3.75),
            level: .warning,
            source: .stdout,
            message: "line one\r\nline two token=<redacted>"
        )

        XCTAssertEqual(
            ConsoleDockSnapshotFormatter.entryText(entry),
            "[1970-01-01T00:00:03.750Z] [stdout] [WARN] line one\\nline two token=<redacted>"
        )
    }

    func testEntryFilterReturnsAllEntriesForEmptyQueryAndAllSources() {
        let entries = filterFixtureEntries()

        let filtered = ConsoleDockEntryFilter.filteredEntries(entries, query: "  ")

        XCTAssertEqual(
            filtered.map(\.message),
            [
                "Native login succeeded",
                "stdout response",
                "stderr network failure",
                "cache warning",
                "fatal fault"
            ])
    }

    func testEntryFilterMatchesMessageLevelAndSourceCaseInsensitively() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "LOGIN").map(\.message),
            ["Native login succeeded"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "error").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "STDOUT").map(\.message),
            ["stdout response"]
        )
    }

    func testEntryFilterRestrictsSourceScope() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "", sourceScope: .stderr).map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "response", sourceScope: .native).map(\.message),
            []
        )
    }

    func testEntryFilterRestrictsLevelScope() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "", levelScope: .warning).map(\.message),
            ["cache warning"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "", levelScope: .fault).map(\.message),
            ["fatal fault"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "network", levelScope: .debug).map(\.message),
            []
        )
    }

    func testEntryFilterCombinesQuerySourceAndLevelScope() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(
                entries,
                query: "network",
                sourceScope: .stderr,
                levelScope: .error
            ).map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(
                entries,
                query: "network",
                sourceScope: .stderr,
                levelScope: .warning
            ).map(\.message),
            []
        )
    }

    func testLiveUpdateBufferFreezesDisplayedEntriesWhilePaused() {
        var buffer = ConsoleDockLiveUpdateBuffer()
        let initialEntries = [filterFixtureEntries()[0]]
        let updatedEntries = filterFixtureEntries()

        XCTAssertTrue(buffer.receive(snapshot: initialEntries))
        buffer.pause()

        XCTAssertFalse(buffer.receive(snapshot: updatedEntries))

        XCTAssertTrue(buffer.isPaused)
        XCTAssertEqual(buffer.displayedEntries.map(\.message), ["Native login succeeded"])
    }

    func testLiveUpdateBufferResumesWithPendingSnapshot() {
        var buffer = ConsoleDockLiveUpdateBuffer()
        let initialEntries = [filterFixtureEntries()[0]]
        let updatedEntries = filterFixtureEntries()

        XCTAssertTrue(buffer.receive(snapshot: initialEntries))
        buffer.pause()
        XCTAssertFalse(buffer.receive(snapshot: updatedEntries))
        buffer.resume(latestEntries: initialEntries)

        XCTAssertFalse(buffer.isPaused)
        XCTAssertEqual(
            buffer.displayedEntries.map(\.message),
            [
                "Native login succeeded",
                "stdout response",
                "stderr network failure",
                "cache warning",
                "fatal fault"
            ])
    }

    func testLiveUpdateBufferReplaceDisplayedEntriesClearsPendingSnapshot() {
        var buffer = ConsoleDockLiveUpdateBuffer()
        let initialEntries = [filterFixtureEntries()[0]]
        let updatedEntries = filterFixtureEntries()

        XCTAssertTrue(buffer.receive(snapshot: initialEntries))
        buffer.pause()
        XCTAssertFalse(buffer.receive(snapshot: updatedEntries))
        buffer.replaceDisplayedEntries([])
        buffer.resume(latestEntries: [])

        XCTAssertFalse(buffer.isPaused)
        XCTAssertTrue(buffer.displayedEntries.isEmpty)
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
        XCTAssertTrue(entries[0].redacted)
        XCTAssertTrue(entries[0].truncated)
    }

    func testSwiftStartUsesConfigurationSnapshotAfterCallerMutatesConfiguration() {
        var configuration = ConsoleDock.Configuration(
            maximumMessageLength: 5,
            captureStandardOutput: false,
            captureStandardError: false,
            redactor: { message in
                message.replacingOccurrences(of: "secret", with: "public")
            }
        )
        XCTAssertEqual(ConsoleDock.start(configuration: configuration), .started)

        configuration.maximumMessageLength = 100
        configuration.redactor = nil

        ConsoleDock.info("secret-value")

        let entry = ConsoleDock.entries.first
        XCTAssertEqual(entry?.message, "publi")
        XCTAssertEqual(entry?.redacted, true)
        XCTAssertEqual(entry?.truncated, true)
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

    func testEntriesObserverIgnoresSameNameNotificationsFromOtherObjects() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let notificationCenter = NotificationCenter()
        let deliveryQueue = DispatchQueue(label: "ConsoleDockTests.ObserverDelivery")
        let initialExpectation = expectation(description: "Initial snapshot delivered")
        let sourceExpectation = expectation(description: "ConsoleDock object snapshot delivered")
        var snapshots: [[ConsoleDock.LogEntry]] = []
        let observer = ConsoleDockEntriesObserver(
            notificationCenter: notificationCenter,
            deliveryQueue: deliveryQueue
        ) { snapshot in
            snapshots.append(snapshot)
            if snapshots.count == 1 {
                initialExpectation.fulfill()
            } else if snapshots.count == 2 {
                sourceExpectation.fulfill()
            }
        }
        defer { observer.invalidate() }

        wait(for: [initialExpectation], timeout: 1.0)
        notificationCenter.post(name: ConsoleDock.entriesDidChangeNotification, object: NSObject())
        let snapshotsAfterUnrelatedNotification = deliveryQueue.sync { snapshots.count }
        XCTAssertEqual(snapshotsAfterUnrelatedNotification, 1)

        notificationCenter.post(name: ConsoleDock.entriesDidChangeNotification, object: CDKConsoleDock.self)
        wait(for: [sourceExpectation], timeout: 1.0)

        XCTAssertEqual(snapshots.count, 2)
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

extension ConsoleDock.Configuration {
    fileprivate static let nativeOnly = ConsoleDock.Configuration(
        captureStandardOutput: false,
        captureStandardError: false
    )
}

extension ConsoleDockTests {
    fileprivate func filterFixtureEntries() -> [ConsoleDock.LogEntry] {
        [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1),
                level: .info,
                source: .native,
                message: "Native login succeeded"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2),
                level: .debug,
                source: .stdout,
                message: "stdout response"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 3),
                level: .error,
                source: .stderr,
                message: "stderr network failure"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 4),
                level: .warning,
                source: .native,
                message: "cache warning"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 5),
                level: .fault,
                source: .native,
                message: "fatal fault"
            )
        ]
    }
}
