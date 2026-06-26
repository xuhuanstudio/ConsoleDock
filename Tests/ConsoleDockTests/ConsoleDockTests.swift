import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockTests: XCTestCase {
    override func tearDown() {
        ConsoleDock.removeAllActions()
        ConsoleDock.clearAppContextProvider()
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
        XCTAssertTrue(ConsoleDock.shouldConfigureUI(startResult: result))
    }

    func testSwiftFacadeConfiguresUIForSuccessfulStartResultsOnly() {
        XCTAssertTrue(ConsoleDock.shouldConfigureUI(startResult: .started))
        XCTAssertTrue(ConsoleDock.shouldConfigureUI(startResult: .alreadyRunning))
        XCTAssertFalse(ConsoleDock.shouldConfigureUI(startResult: .disabled))
        XCTAssertFalse(
            ConsoleDock.shouldConfigureUI(
                startResult: .failed(
                    ConsoleDock.StartFailure(domain: "test", code: 1, message: "failed")
                )
            )
        )
    }

    func testObjectiveCUIKitFacadeStartStopLifecycle() {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false

        XCTAssertEqual(ConsoleDockUIKit.start(configuration: configuration, error: nil), .started)
        XCTAssertTrue(ConsoleDockUIKit.isRunning())

        ConsoleDockUIKit.showConsole()
        ConsoleDockUIKit.hideConsole()
        ConsoleDockUIKit.hideFloatingButton()
        ConsoleDockUIKit.showFloatingButton()
        ConsoleDockUIKit.stop()

        XCTAssertFalse(ConsoleDockUIKit.isRunning())
    }

    func testObjectiveCUIKitFacadeFloatingButtonControlsAreSafeBeforeStart() {
        ConsoleDockUIKit.hideFloatingButton()
        ConsoleDockUIKit.showFloatingButton()

        XCTAssertFalse(ConsoleDockUIKit.isRunning())
    }

    func testReleaseBuildSwiftFacadeDefaultStartGateIsDisabled() {
        let configuration = ConsoleDock.Configuration(
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: false
        )

        let result = ConsoleDock.start(configuration: configuration)

        #if DEBUG
            XCTAssertEqual(result, .started)
            XCTAssertTrue(ConsoleDock.isRunning)
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(ConsoleDock.isRunning)
        #endif
    }

    func testReleaseBuildSwiftFacadeOptInRequiresCompileTimeFlagAndRuntimeConfiguration() {
        let configuration = ConsoleDock.Configuration(
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: false,
            allowsReleaseBuilds: true
        )

        let result = ConsoleDock.start(configuration: configuration)

        #if DEBUG || CONSOLEDOCK_ENABLE_RELEASE
            XCTAssertEqual(result, .started)
            XCTAssertTrue(ConsoleDock.isRunning)
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(ConsoleDock.isRunning)
        #endif
    }

    func testReleaseBuildObjectiveCUIKitFacadeDefaultStartGateIsDisabled() {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false
        configuration.showsFloatingButton = false

        let result = ConsoleDockUIKit.start(configuration: configuration, error: nil)

        #if DEBUG
            XCTAssertEqual(result, .started)
            XCTAssertTrue(ConsoleDockUIKit.isRunning())
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(ConsoleDockUIKit.isRunning())
        #endif
    }

    func testReleaseBuildObjectiveCUIKitFacadeOptInRequiresCompileTimeFlagAndRuntimeConfiguration() {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false
        configuration.showsFloatingButton = false
        configuration.allowsReleaseBuilds = true

        let result = ConsoleDockUIKit.start(configuration: configuration, error: nil)

        #if DEBUG || CONSOLEDOCK_ENABLE_RELEASE
            XCTAssertEqual(result, .started)
            XCTAssertTrue(ConsoleDockUIKit.isRunning())
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(ConsoleDockUIKit.isRunning())
        #endif
    }

    func testConfigurationDefaultsMatchCoreDefaults() {
        let configuration = ConsoleDock.Configuration.default

        XCTAssertEqual(configuration.maximumEntries, 2_000)
        XCTAssertEqual(configuration.maximumMessageLength, 8_192)
        XCTAssertTrue(configuration.captureStandardOutput)
        XCTAssertTrue(configuration.captureStandardError)
        XCTAssertTrue(configuration.showsFloatingButton)
        XCTAssertEqual(configuration.floatingButtonPosition, .bottomTrailing)
        XCTAssertFalse(configuration.allowsReleaseBuilds)
    }

    func testSwiftConfigurationMapsFloatingButtonPositionToCoreConfiguration() {
        let configuration = ConsoleDock.Configuration(
            captureStandardOutput: false,
            captureStandardError: false,
            floatingButtonPosition: .topLeading
        )

        XCTAssertEqual(configuration.makeCoreConfiguration().floatingButtonPosition, .topLeading)
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

    func testSwiftSessionMetadataMapsCoreFields() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        let metadata = ConsoleDock.sessionMetadata

        XCTAssertFalse(metadata.sessionIdentifier.isEmpty)
        XCTAssertNotNil(metadata.startedAt)
        XCTAssertGreaterThanOrEqual(
            metadata.generatedAt.timeIntervalSince1970,
            metadata.startedAt!.timeIntervalSince1970
        )
        XCTAssertFalse(metadata.processName.isEmpty)
        XCTAssertFalse(metadata.operatingSystemVersion.isEmpty)
        XCTAssertFalse(metadata.deviceModel.isEmpty)
        XCTAssertFalse(metadata.localeIdentifier.isEmpty)
        XCTAssertFalse(metadata.timeZoneIdentifier.isEmpty)
    }

    func testSwiftFacadeMarkStoresMarkerEntry() throws {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.mark("Tapped pay button token=secret")

        let entry = try XCTUnwrap(ConsoleDock.entries.first)
        XCTAssertEqual(entry.level, .info)
        XCTAssertEqual(entry.source, .native)
        XCTAssertEqual(entry.message, "[marker] Tapped pay button token=<redacted>")
        XCTAssertTrue(entry.redacted)
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

    func testSwiftFacadeLogWithLevelRoutesNativeEntries() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.log(level: .debug, message: "debug")
        ConsoleDock.log(level: .info, message: "info")
        ConsoleDock.log(level: .warning, message: "warning")
        ConsoleDock.log(level: .error, message: "error")
        ConsoleDock.log(level: .fault, message: "fault")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.map(\.level), [.debug, .info, .warning, .error, .fault])
        XCTAssertEqual(entries.map(\.source), [.native, .native, .native, .native, .native])
        XCTAssertEqual(entries.map(\.message), ["debug", "info", "warning", "error", "fault"])
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

    func testSnapshotFormatterOmitsVisibleEntriesLineWhenSharingAllLogs() {
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: true,
            capturesStandardOutput: true,
            capturesStandardError: true,
            showsFloatingButton: true,
            allowsReleaseBuilds: false,
            maximumEntries: 2_000,
            maximumMessageLength: 8_192,
            entryCount: 1,
            redactedEntryCount: 0,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1),
                level: .info,
                source: .native,
                message: "all logs"
            )
        ]

        let snapshot = ConsoleDockSnapshotFormatter.snapshotText(
            entries: entries,
            generatedAt: Date(timeIntervalSince1970: 0),
            diagnostics: diagnostics,
            visibleEntryCount: nil
        )

        XCTAssertFalse(snapshot.contains("Visible Entries:"))
        XCTAssertTrue(snapshot.contains("Entries: 1"))
    }

    func testTimelineBuilderReturnsNoEventsForEmptyInput() {
        let events = ConsoleDockTimelineBuilder.events(entries: [], actionExecutions: [])

        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(ConsoleDockTimelineBuilder.reportLines(entries: [], actionExecutions: []).isEmpty)
    }

    func testTimelineBuilderIncludesMarkersActionsErrorsAndFaults() {
        let entries = [
            ConsoleDock.LogEntry(
                id: 1,
                timestamp: Date(timeIntervalSince1970: 2),
                level: .info,
                source: .native,
                message: "[marker] Open checkout"
            ),
            ConsoleDock.LogEntry(
                id: 2,
                timestamp: Date(timeIntervalSince1970: 4),
                level: .error,
                source: .stderr,
                message: "payment failed"
            ),
            ConsoleDock.LogEntry(
                id: 3,
                timestamp: Date(timeIntervalSince1970: 5),
                level: .fault,
                source: .native,
                message: "checkout fault"
            )
        ]
        let executions = [
            ConsoleDock.DebugActionExecution(
                id: 1,
                actionID: "open.checkout",
                title: "Open Checkout",
                group: "Navigation",
                startedAt: Date(timeIntervalSince1970: 3),
                completedAt: Date(timeIntervalSince1970: 3.25),
                outcome: .completed,
                parameterSummary: "orderId=\"A-100\""
            )
        ]

        let events = ConsoleDockTimelineBuilder.events(entries: entries, actionExecutions: executions)

        XCTAssertEqual(events.map(\.kind), [.marker, .action, .log, .log])
        XCTAssertEqual(events.map(\.title), ["Open checkout", "Open Checkout", "payment failed", "checkout fault"])
        XCTAssertEqual(
            events.map(\.reportText),
            [
                "[1970-01-01T00:00:02.000Z] [marker] Open checkout",
                "[1970-01-01T00:00:03.000Z] [action] [completed] Open Checkout [open.checkout] group=Navigation params: orderId=\"A-100\"",
                "[1970-01-01T00:00:04.000Z] [log] [ERROR] payment failed",
                "[1970-01-01T00:00:05.000Z] [log] [FAULT] checkout fault"
            ]
        )
        XCTAssertEqual(events[0].logEntry?.id, 1)
        XCTAssertEqual(events[1].actionExecution?.id, 1)
    }

    func testTimelineBuilderExcludesNonMarkerDebugInfoAndWarningLogs() {
        let entries = [
            ConsoleDock.LogEntry(
                id: 1,
                timestamp: Date(timeIntervalSince1970: 1),
                level: .debug,
                source: .native,
                message: "debug"
            ),
            ConsoleDock.LogEntry(
                id: 2,
                timestamp: Date(timeIntervalSince1970: 2),
                level: .info,
                source: .native,
                message: "info"
            ),
            ConsoleDock.LogEntry(
                id: 3,
                timestamp: Date(timeIntervalSince1970: 3),
                level: .warning,
                source: .native,
                message: "warning"
            ),
            ConsoleDock.LogEntry(
                id: 4,
                timestamp: Date(timeIntervalSince1970: 4),
                level: .info,
                source: .native,
                message: "[marker] Still included"
            )
        ]

        let events = ConsoleDockTimelineBuilder.events(entries: entries, actionExecutions: [])

        XCTAssertEqual(events.map(\.title), ["Still included"])
        XCTAssertEqual(events.map(\.kind), [.marker])
    }

    func testTimelineBuilderSortsByTimestampWithStableEqualTimeOrdering() {
        let sharedDate = Date(timeIntervalSince1970: 10)
        let entries = [
            ConsoleDock.LogEntry(
                id: 1,
                timestamp: sharedDate,
                level: .error,
                source: .native,
                message: "first error"
            ),
            ConsoleDock.LogEntry(
                id: 2,
                timestamp: sharedDate,
                level: .info,
                source: .native,
                message: "[marker] second marker"
            )
        ]
        let executions = [
            ConsoleDock.DebugActionExecution(
                id: 1,
                actionID: "third.action",
                title: "Third Action",
                group: nil,
                startedAt: sharedDate,
                completedAt: sharedDate,
                outcome: .skipped,
                message: "disabled"
            )
        ]

        let events = ConsoleDockTimelineBuilder.events(entries: entries, actionExecutions: executions)

        XCTAssertEqual(events.map(\.title), ["first error", "second marker", "Third Action"])
    }

    func testTimelineBuilderActionDetailTextIncludesExecutionMetadata() {
        let execution = ConsoleDock.DebugActionExecution(
            id: 1,
            actionID: "open.order",
            title: "Open Order",
            group: "Navigation",
            startedAt: Date(timeIntervalSince1970: 2),
            completedAt: Date(timeIntervalSince1970: 3),
            outcome: .failed,
            parameterSummary: "orderId=\"A-100\"",
            message: "error=boom"
        )

        let detail = ConsoleDockTimelineBuilder.actionDetailText(execution)

        XCTAssertTrue(detail.contains("Action ID: open.order"))
        XCTAssertTrue(detail.contains("Title: Open Order"))
        XCTAssertTrue(detail.contains("Outcome: failed"))
        XCTAssertTrue(detail.contains("Started: 1970-01-01T00:00:02.000Z"))
        XCTAssertTrue(detail.contains("Completed: 1970-01-01T00:00:03.000Z"))
        XCTAssertTrue(detail.contains("Group: Navigation"))
        XCTAssertTrue(detail.contains("Parameters: orderId=\"A-100\""))
        XCTAssertTrue(detail.contains("Message: error=boom"))
        XCTAssertFalse(detail.contains("Time:"))
    }

    func testIssueReportFormatterIncludesSessionDiagnosticsMarkersAndLogs() {
        let metadata = ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-123",
            startedAt: Date(timeIntervalSince1970: 1.25),
            generatedAt: Date(timeIntervalSince1970: 0),
            bundleIdentifier: "io.github.consoledock.Sample",
            appVersion: "1.2.3",
            appBuild: "456",
            processName: "Sample",
            operatingSystemVersion: "Version 18.0",
            deviceModel: "iPhone",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC"
        )
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: true,
            capturesStandardOutput: false,
            capturesStandardError: true,
            showsFloatingButton: true,
            allowsReleaseBuilds: false,
            maximumEntries: 100,
            maximumMessageLength: 4_096,
            entryCount: 2,
            redactedEntryCount: 1,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2.5),
                level: .info,
                source: .native,
                message: "[marker] Started checkout"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 3.75),
                level: .error,
                source: .stderr,
                message: "payment token=<redacted>",
                redacted: true
            )
        ]

        let report = ConsoleDockIssueReportFormatter.reportText(
            entries: entries,
            metadata: metadata,
            diagnostics: diagnostics
        )

        XCTAssertEqual(
            report,
            """
            ConsoleDock Issue Report
            Generated: 1970-01-01T00:00:00.000Z

            Session:
              Session ID: session-123
              Started: 1970-01-01T00:00:01.250Z
              Bundle ID: io.github.consoledock.Sample
              App Version: 1.2.3
              App Build: 456
              Process: Sample
              OS: Version 18.0
              Device: iPhone
              Locale: en_US
              Time Zone: UTC

            Diagnostics:
              Running: true
              stdout: disabled
              stderr: enabled
              Floating Button: enabled
              Release Builds: disabled by runtime config
              Limits: entries=100 messageLength=4096
              Redacted: 1
              Truncated: 0
              Partial: 0

            App Context:
              (no app context)

            Reproduction Timeline:
              [1970-01-01T00:00:02.500Z] [marker] Started checkout
              [1970-01-01T00:00:03.750Z] [log] [ERROR] payment token=<redacted>

            Markers:
              [1970-01-01T00:00:02.500Z] [native] [INFO] [marker] Started checkout

            Logs:
              [1970-01-01T00:00:02.500Z] [native] [INFO] [marker] Started checkout
              [1970-01-01T00:00:03.750Z] [stderr] [ERROR] [redacted] payment token=<redacted>
            """
        )
    }

    func testIssueReportFormatterHandlesEmptyEntriesAndMissingMetadata() {
        let metadata = ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-empty",
            startedAt: nil,
            generatedAt: Date(timeIntervalSince1970: 0),
            bundleIdentifier: nil,
            appVersion: nil,
            appBuild: nil,
            processName: "Sample",
            operatingSystemVersion: "Version 18.0",
            deviceModel: "unknown",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC"
        )
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: false,
            capturesStandardOutput: false,
            capturesStandardError: false,
            showsFloatingButton: false,
            allowsReleaseBuilds: false,
            maximumEntries: 100,
            maximumMessageLength: 4_096,
            entryCount: 0,
            redactedEntryCount: 0,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )

        let report = ConsoleDockIssueReportFormatter.reportText(
            entries: [],
            metadata: metadata,
            diagnostics: diagnostics
        )

        XCTAssertTrue(report.contains("Started: unavailable"))
        XCTAssertTrue(report.contains("Bundle ID: unavailable"))
        XCTAssertTrue(report.contains("Reproduction Timeline:\n  (no timeline events)"))
        XCTAssertTrue(report.contains("Markers:\n  (no markers)"))
        XCTAssertTrue(report.contains("Logs:\n  (no entries)"))
    }

    func testIssueReportFormatterIncludesTimelineWithActionsMarkersAndErrorsInTimestampOrder() {
        let metadata = ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-timeline",
            startedAt: Date(timeIntervalSince1970: 1),
            generatedAt: Date(timeIntervalSince1970: 0),
            bundleIdentifier: nil,
            appVersion: nil,
            appBuild: nil,
            processName: "Sample",
            operatingSystemVersion: "Version 18.0",
            deviceModel: "iPhone",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC"
        )
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: true,
            capturesStandardOutput: false,
            capturesStandardError: false,
            showsFloatingButton: false,
            allowsReleaseBuilds: false,
            maximumEntries: 100,
            maximumMessageLength: 4_096,
            entryCount: 2,
            redactedEntryCount: 0,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 4),
                level: .error,
                source: .native,
                message: "Checkout failed"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2),
                level: .info,
                source: .native,
                message: "[marker] Open checkout"
            )
        ]
        let executions = [
            ConsoleDock.DebugActionExecution(
                id: 1,
                actionID: "open.order",
                title: "Open Order",
                group: "Navigation",
                startedAt: Date(timeIntervalSince1970: 3),
                completedAt: Date(timeIntervalSince1970: 3.5),
                outcome: .completed,
                parameterSummary: "orderId=\"A-100\""
            )
        ]

        let report = ConsoleDockIssueReportFormatter.reportText(
            entries: entries,
            metadata: metadata,
            diagnostics: diagnostics,
            actionExecutions: executions
        )

        XCTAssertTrue(
            report.contains(
                """
                Reproduction Timeline:
                  [1970-01-01T00:00:02.000Z] [marker] Open checkout
                  [1970-01-01T00:00:03.000Z] [action] [completed] Open Order [open.order] group=Navigation params: orderId="A-100"
                  [1970-01-01T00:00:04.000Z] [log] [ERROR] Checkout failed
                """
            )
        )
    }

    func testIssueReportFileExporterWritesTemporaryTextFile() throws {
        let reportText = "ConsoleDock Issue Report\nGenerated: fixture"

        let fileURL = try ConsoleDockIssueReportFileExporter.makeTemporaryReportFile(
            reportText: reportText,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }

        XCTAssertEqual(fileURL.pathExtension, "txt")
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("ConsoleDock-Issue-Report-19700101-000000-000-"))
        XCTAssertEqual(try String(contentsOf: fileURL), reportText)
    }

    func testSupportReportFiltersEntriesAndActionsByLastMinutes() {
        let report = ConsoleDockSupportReportBuilder.makeReport(
            options: ConsoleDock.SupportReportOptions(
                timeRange: .last(minutes: 10),
                includesIntegrationHealth: false
            ),
            entries: [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 2_999),
                    level: .info,
                    source: .native,
                    message: "too old"
                ),
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 3_001),
                    level: .error,
                    source: .native,
                    message: "recent failure"
                ),
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 3_600),
                    level: .fault,
                    source: .stderr,
                    message: "latest fault"
                )
            ],
            metadata: fixtureMetadata(generatedAt: Date(timeIntervalSince1970: 3_600)),
            diagnostics: fixtureDiagnostics(entryCount: 3),
            appContext: [],
            actionExecutions: [
                ConsoleDock.DebugActionExecution(
                    id: 1,
                    actionID: "old.action",
                    title: "Old Action",
                    group: nil,
                    startedAt: Date(timeIntervalSince1970: 2_998),
                    completedAt: Date(timeIntervalSince1970: 2_999),
                    outcome: .completed
                ),
                ConsoleDock.DebugActionExecution(
                    id: 2,
                    actionID: "recent.action",
                    title: "Recent Action",
                    group: nil,
                    startedAt: Date(timeIntervalSince1970: 3_500),
                    completedAt: Date(timeIntervalSince1970: 3_501),
                    outcome: .completed
                )
            ]
        )

        XCTAssertEqual(report.timeRangeDescription, "last 10 minutes")
        XCTAssertEqual(report.includedEntryCount, 2)
        XCTAssertEqual(report.omittedEntryCount, 1)
        XCTAssertEqual(report.includedActionExecutionCount, 1)
        XCTAssertEqual(report.omittedActionExecutionCount, 1)
        XCTAssertTrue(report.text.contains("ConsoleDock Support Report"))
        XCTAssertTrue(report.text.contains("Included Entries: 2 of 3 retained"))
        XCTAssertTrue(report.text.contains("recent failure"))
        XCTAssertTrue(report.text.contains("latest fault"))
        XCTAssertTrue(report.text.contains("Recent Action"))
        XCTAssertFalse(report.text.contains("too old"))
        XCTAssertFalse(report.text.contains("Old Action"))
        XCTAssertTrue(report.text.contains("no continuous log file or automatic upload"))
    }

    func testSupportReportLast60MinutesIncludesLongFlowWithinCurrentCache() {
        let report = ConsoleDockSupportReportBuilder.makeReport(
            options: .last60Minutes,
            entries: [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 1),
                    level: .info,
                    source: .native,
                    message: "outside one hour"
                ),
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 200),
                    level: .warning,
                    source: .native,
                    message: "long flow warning"
                )
            ],
            metadata: fixtureMetadata(generatedAt: Date(timeIntervalSince1970: 3_800)),
            diagnostics: fixtureDiagnostics(entryCount: 2),
            appContext: [],
            actionExecutions: []
        )

        XCTAssertEqual(report.timeRangeDescription, "last 60 minutes")
        XCTAssertEqual(report.includedEntryCount, 1)
        XCTAssertEqual(report.omittedEntryCount, 1)
        XCTAssertTrue(report.text.contains("long flow warning"))
        XCTAssertFalse(report.text.contains("outside one hour"))
    }

    func testSupportReportRangeNormalizesReversedDates() {
        let report = ConsoleDockSupportReportBuilder.makeReport(
            options: ConsoleDock.SupportReportOptions(
                timeRange: .range(
                    from: Date(timeIntervalSince1970: 30),
                    to: Date(timeIntervalSince1970: 10)
                ),
                includesIntegrationHealth: false
            ),
            entries: [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 9),
                    level: .info,
                    source: .native,
                    message: "before range"
                ),
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 20),
                    level: .info,
                    source: .native,
                    message: "inside range"
                )
            ],
            metadata: fixtureMetadata(generatedAt: Date(timeIntervalSince1970: 40)),
            diagnostics: fixtureDiagnostics(entryCount: 2),
            appContext: [],
            actionExecutions: []
        )

        XCTAssertTrue(report.text.contains("1970-01-01T00:00:10.000Z to 1970-01-01T00:00:30.000Z"))
        XCTAssertTrue(report.text.contains("inside range"))
        XCTAssertFalse(report.text.contains("before range"))
    }

    func testSupportReportTruncatesAtBoundedLimit() {
        let report = ConsoleDockSupportReportBuilder.makeReport(
            options: ConsoleDock.SupportReportOptions(
                timeRange: .allRetained,
                maximumReportCharacterCount: 1_024,
                includesIntegrationHealth: false
            ),
            entries: [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 1),
                    level: .error,
                    source: .native,
                    message: String(repeating: "x", count: 4_000)
                )
            ],
            metadata: fixtureMetadata(),
            diagnostics: fixtureDiagnostics(entryCount: 1),
            appContext: [],
            actionExecutions: []
        )

        XCTAssertTrue(report.isReportTruncated)
        XCTAssertGreaterThan(report.reportCharacterCount, report.text.count)
        XCTAssertEqual(report.text.count, 1_024)
        XCTAssertTrue(report.text.contains("support report truncated at 1024 characters"))
        XCTAssertTrue(report.text.contains("Truncated: true"))
    }

    func testSupportReportFileExporterWritesTemporaryTextFile() throws {
        let reportText = "ConsoleDock Support Report\nGenerated: fixture"

        let fileURL = try ConsoleDockIssueReportFileExporter.makeTemporarySupportReportFile(
            reportText: reportText,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }

        XCTAssertEqual(fileURL.pathExtension, "txt")
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("ConsoleDock-Support-Report-19700101-000000-000-"))
        XCTAssertEqual(try String(contentsOf: fileURL), reportText)
    }

    func testSupportReportFileExporterPrunesTemporaryTextFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConsoleDockSupportReports", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        defer { try? FileManager.default.removeItem(at: directory) }

        var latestFileURL: URL?
        for offset in 0..<25 {
            latestFileURL = try ConsoleDockIssueReportFileExporter.makeTemporarySupportReportFile(
                reportText: "ConsoleDock Support Report \(offset)",
                generatedAt: Date(timeIntervalSince1970: TimeInterval(offset))
            )
        }

        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let supportReportFiles = fileURLs.filter { fileURL in
            fileURL.pathExtension == "txt"
                && fileURL.lastPathComponent.hasPrefix("ConsoleDock-Support-Report-")
        }
        XCTAssertLessThanOrEqual(supportReportFiles.count, 20)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(latestFileURL).path))
    }

    func testObjectiveCUIKitFacadeBuildsSupportReportAndTemporaryFile() throws {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false
        XCTAssertEqual(ConsoleDockUIKit.start(configuration: configuration, error: nil), .started)
        ConsoleDock.info("ObjC support report entry")

        let report = ConsoleDockUIKit.supportReport(lastMinutes: 60, maximumReportCharacterCount: 0)

        XCTAssertEqual(report.timeRangeDescription, "last 60 minutes")
        XCTAssertGreaterThanOrEqual(report.includedEntryCount, 1)
        XCTAssertTrue(report.text.contains("ConsoleDock Support Report"))
        XCTAssertTrue(report.text.contains("ObjC support report entry"))
        XCTAssertTrue(report.text.contains("no continuous log file or automatic upload"))

        var error: NSError?
        let fileURL = try XCTUnwrap(
            ConsoleDockUIKit.makeTemporarySupportReportFile(
                lastMinutes: 60,
                maximumReportCharacterCount: 0,
                error: &error
            )
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }

        XCTAssertNil(error)
        XCTAssertEqual(fileURL.pathExtension, "txt")
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("ConsoleDock-Support-Report-"))
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

    func testSnapshotFormatterIncludesEntryFlagsWhenPresent() {
        let entry = ConsoleDock.LogEntry(
            timestamp: Date(timeIntervalSince1970: 4.25),
            level: .error,
            source: .stderr,
            message: "oversized token=<redacted>",
            partial: true,
            redacted: true,
            truncated: true
        )

        XCTAssertEqual(
            ConsoleDockSnapshotFormatter.entryText(entry),
            "[1970-01-01T00:00:04.250Z] [stderr] [ERROR] [partial redacted truncated] oversized token=<redacted>"
        )
    }

    func testSnapshotFormatterFormatsDetailedEntryForCopy() {
        let entry = ConsoleDock.LogEntry(
            timestamp: Date(timeIntervalSince1970: 5.5),
            level: .fault,
            source: .native,
            message: "line one\nline two",
            partial: false,
            redacted: true,
            truncated: false
        )

        XCTAssertEqual(
            ConsoleDockSnapshotFormatter.entryDetailText(entry),
            """
            Time: 1970-01-01T00:00:05.500Z
            Source: native
            Level: FAULT
            Partial: false
            Redacted: true
            Truncated: false

            line one
            line two
            """
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

    func testEntryFilterSupportsStructuredSourceQueries() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "source:stderr").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "source:STDOUT").map(\.message),
            ["stdout response"]
        )
    }

    func testEntryFilterSupportsStructuredLevelQueriesAndWarnAlias() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "level:error").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "level:warn").map(\.message),
            ["cache warning"]
        )
    }

    func testEntryFilterSupportsStructuredFlagQueries() {
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1),
                level: .info,
                source: .native,
                message: "partial entry",
                partial: true
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2),
                level: .warning,
                source: .stdout,
                message: "redacted entry",
                redacted: true
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 3),
                level: .error,
                source: .stderr,
                message: "truncated entry",
                truncated: true
            )
        ]

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "is:partial").map(\.message),
            ["partial entry"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "is:redacted").map(\.message),
            ["redacted entry"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "is:truncated").map(\.message),
            ["truncated entry"]
        )
    }

    func testEntryFilterSupportsQuotedPhrasesAndExcludedTerms() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "\"network failure\"").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "native -login").map(\.message),
            ["cache warning", "fatal fault"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "network -\"network failure\"").map(\.message),
            []
        )
    }

    func testEntryFilterUnknownStructuredTokensFallBackToText() {
        let entries =
            filterFixtureEntries()
            + [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 6),
                    level: .info,
                    source: .native,
                    message: "manual source:external marker"
                )
            ]

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "source:external").map(\.message),
            ["manual source:external marker"]
        )
    }

    func testEntryFilterCombinesStructuredQueriesWithSegmentedScopes() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "source:stderr level:error").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "source:stdout level:error").map(\.message),
            []
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(
                entries,
                query: "level:error",
                sourceScope: .stderr,
                levelScope: .all
            ).map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(
                entries,
                query: "level:error",
                sourceScope: .native,
                levelScope: .all
            ).map(\.message),
            []
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(
                entries,
                query: "source:native",
                sourceScope: .all,
                levelScope: .fault
            ).map(\.message),
            ["fatal fault"]
        )
    }

    func testEntryFilterUsesAndSemanticsForMultipleTerms() {
        let entries = filterFixtureEntries()

        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "network failure").map(\.message),
            ["stderr network failure"]
        )
        XCTAssertEqual(
            ConsoleDockEntryFilter.filteredEntries(entries, query: "network login").map(\.message),
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

    func testSwiftLogForwarderPrefixesCategoryAndFiltersMinimumLevel() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let forwarder = ConsoleDock.LogForwarder(category: " App\nLog ", minimumLevel: .warning)

        forwarder.debug("ignored debug")
        forwarder.info("ignored info")
        forwarder.warning("cache warming")
        forwarder.error("request failed")

        XCTAssertEqual(ConsoleDock.entries.map(\.level), [.warning, .error])
        XCTAssertEqual(ConsoleDock.entries.map(\.message), ["[App Log] cache warming", "[App Log] request failed"])
        XCTAssertEqual(forwarder.category, "App Log")
        XCTAssertEqual(forwarder.minimumLevel, .warning)
    }

    func testSwiftLogForwarderConvenienceMethodsForwardNativeEntries() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let forwarder = ConsoleDock.LogForwarder()

        forwarder.debug("debug")
        forwarder.info("info")
        forwarder.warning("warning")
        forwarder.error("error")
        forwarder.fault("fault")

        XCTAssertEqual(ConsoleDock.entries.map(\.level), [.debug, .info, .warning, .error, .fault])
        XCTAssertEqual(ConsoleDock.entries.map(\.message), ["debug", "info", "warning", "error", "fault"])
    }

    func testIssueReportTextIncludesCurrentSessionAndEntries() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.mark("Open checkout")
        ConsoleDock.error("Checkout failed")

        let report = ConsoleDock.issueReportText()

        XCTAssertTrue(report.contains("ConsoleDock Issue Report"))
        XCTAssertTrue(report.contains("Session ID:"))
        XCTAssertTrue(report.contains("Markers:"))
        XCTAssertTrue(report.contains("[marker] Open checkout"))
        XCTAssertTrue(report.contains("Checkout failed"))
    }

    func testObjectiveCUIKitFacadeIssueReportTextUsesSharedReportFormatter() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.info("ObjC facade report")

        let report = ConsoleDockUIKit.issueReportText()

        XCTAssertTrue(report.contains("ConsoleDock Issue Report"))
        XCTAssertTrue(report.contains("ObjC facade report"))
    }

    func testIntegrationDiagnosisFormatterReportsCountsAndRecommendations() {
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 1),
                level: .info,
                source: .native,
                message: "native"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2),
                level: .debug,
                source: .stdout,
                message: "stdout"
            ),
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 3),
                level: .error,
                source: .stderr,
                message: "stderr",
                partial: true,
                redacted: true,
                truncated: true
            )
        ]
        let snapshot = ConsoleDockIntegrationDiagnosisFormatter.Snapshot(
            generatedAt: Date(timeIntervalSince1970: 0),
            metadata: fixtureMetadata(),
            diagnostics: fixtureDiagnostics(
                entryCount: 3,
                redactedEntryCount: 1,
                truncatedEntryCount: 1,
                partialEntryCount: 1
            ),
            entries: entries,
            debugActions: [ConsoleDockDebugAction(id: "open.checkout", title: "Open Checkout")],
            actionExecutions: [
                ConsoleDock.DebugActionExecution(
                    id: 1,
                    actionID: "open.checkout",
                    title: "Open Checkout",
                    group: nil,
                    startedAt: Date(timeIntervalSince1970: 4),
                    completedAt: Date(timeIntervalSince1970: 5),
                    outcome: .completed
                )
            ],
            appContextProviderRegistered: true,
            appContext: [
                ConsoleDock.AppContextSection(
                    title: "App",
                    items: [.init(key: "Environment", value: "staging")]
                )
            ],
            archiveState: .available(count: 2)
        )

        let report = ConsoleDockIntegrationDiagnosisFormatter.diagnosisText(snapshot: snapshot)

        XCTAssertTrue(report.contains("ConsoleDock Integration Diagnosis"))
        XCTAssertTrue(report.contains("Generated: 1970-01-01T00:00:00.000Z"))
        XCTAssertTrue(report.contains("Sources: native=1 stdout=1 stderr=1"))
        XCTAssertTrue(report.contains("Levels: debug=1 info=1 warning=0 error=1 fault=0"))
        XCTAssertTrue(report.contains("Flags: redacted=1 truncated=1 partial=1"))
        XCTAssertTrue(report.contains("Debug Actions: registered=1 executions=1"))
        XCTAssertTrue(report.contains("App Context: provider=registered sections=1 items=1"))
        XCTAssertTrue(report.contains("Session Archives: count=2"))
        XCTAssertTrue(report.contains("Swift Logger, os_log, and Apple unified logging are not fully captured"))
    }

    func testIntegrationDiagnosisFormatterReportsSetupGaps() {
        let snapshot = ConsoleDockIntegrationDiagnosisFormatter.Snapshot(
            generatedAt: Date(timeIntervalSince1970: 0),
            metadata: fixtureMetadata(startedAt: nil),
            diagnostics: fixtureDiagnostics(
                isRunning: false,
                capturesStandardOutput: false,
                capturesStandardError: false,
                showsFloatingButton: false,
                entryCount: 0
            ),
            entries: [],
            debugActions: [],
            actionExecutions: [],
            appContextProviderRegistered: false,
            appContext: [],
            archiveState: .available(count: 0)
        )

        let recommendations = ConsoleDockIntegrationDiagnosisFormatter.recommendations(snapshot)

        XCTAssertTrue(recommendations.contains { $0.contains("ConsoleDock is not running") })
        XCTAssertTrue(recommendations.contains { $0.contains("No entries are retained yet") })
        XCTAssertTrue(recommendations.contains { $0.contains("stdout capture is disabled") })
        XCTAssertTrue(recommendations.contains { $0.contains("stderr capture is disabled") })
        XCTAssertTrue(recommendations.contains { $0.contains("No Debug Actions are registered") })
        XCTAssertTrue(recommendations.contains { $0.contains("No App Context provider is registered") })
    }

    func testHealthSectionUsesIntegrationSnapshot() {
        let snapshot = ConsoleDockIntegrationDiagnosisFormatter.Snapshot(
            generatedAt: Date(timeIntervalSince1970: 0),
            metadata: fixtureMetadata(),
            diagnostics: fixtureDiagnostics(entryCount: 1),
            entries: [
                ConsoleDock.LogEntry(
                    timestamp: Date(timeIntervalSince1970: 1),
                    level: .warning,
                    source: .native,
                    message: "warning"
                )
            ],
            debugActions: [],
            actionExecutions: [],
            appContextProviderRegistered: false,
            appContext: [],
            archiveState: .available(count: 0)
        )

        let section = ConsoleDockIntegrationDiagnosisFormatter.healthSection(snapshot: snapshot)

        XCTAssertEqual(section.title, "ConsoleDock Health")
        XCTAssertTrue(section.items.contains(.init(key: "Running", value: "on")))
        XCTAssertTrue(section.items.contains(.init(key: "Entry Sources", value: "native=1 stdout=0 stderr=0")))
        XCTAssertTrue(section.items.contains { $0.key == "Recommendations" })
    }

    func testConsoleDockIntegrationDiagnosisTextIncludesCurrentEntries() {
        withTemporaryArchiveStore { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.info("diagnosis native entry")

            let report = ConsoleDock.integrationDiagnosisText()

            XCTAssertTrue(report.contains("ConsoleDock Integration Diagnosis"))
            XCTAssertTrue(report.contains("Total: 1"))
            XCTAssertTrue(report.contains("Sources: native=1 stdout=0 stderr=0"))
            XCTAssertTrue(report.contains("stdout capture is disabled by configuration"))
            XCTAssertTrue(report.contains("diagnosis native entry") == false)
        }
    }

    func testObjectiveCUIKitFacadeIntegrationDiagnosisTextUsesSwiftFacade() {
        withTemporaryArchiveStore { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.warning("ObjC facade diagnosis")

            let report = ConsoleDockUIKit.integrationDiagnosisText()

            XCTAssertTrue(report.contains("ConsoleDock Integration Diagnosis"))
            XCTAssertTrue(report.contains("Sources: native=1 stdout=0 stderr=0"))
        }
    }

    func testIssueReportIncludesConsoleDockHealth() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.error("health issue report")

        let report = ConsoleDock.issueReportText()

        XCTAssertTrue(report.contains("ConsoleDock Health:"))
        XCTAssertTrue(report.contains("Entry Sources: native=1 stdout=0 stderr=0"))
        XCTAssertTrue(report.contains("health issue report"))
    }

    func testAppContextProviderNormalizesAndClearsSnapshot() {
        ConsoleDock.setAppContextProvider {
            [
                ConsoleDock.AppContextSection(
                    title: " App\nState ",
                    items: [
                        .init(key: " Environment ", value: " staging "),
                        .init(key: "Environment", value: "duplicate"),
                        .init(key: "\n", value: "missing key"),
                        .init(key: "Flags", value: " new-checkout=on\r\nqa-mode=off ")
                    ]
                ),
                ConsoleDock.AppContextSection(title: "Empty", items: [])
            ]
        }

        XCTAssertEqual(
            ConsoleDock.appContext,
            [
                ConsoleDock.AppContextSection(
                    title: "App State",
                    items: [
                        .init(key: "Environment", value: "staging"),
                        .init(key: "Flags", value: "new-checkout=on\nqa-mode=off")
                    ]
                )
            ]
        )

        ConsoleDock.clearAppContextProvider()

        XCTAssertTrue(ConsoleDock.appContext.isEmpty)
    }

    func testIssueReportIncludesAppContext() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.setAppContextProvider {
            [
                ConsoleDock.AppContextSection(
                    title: "App",
                    items: [
                        .init(key: "Environment", value: "staging"),
                        .init(key: "User ID", value: "user-123")
                    ]
                )
            ]
        }

        let report = ConsoleDock.issueReportText()

        XCTAssertTrue(report.contains("App Context:"))
        XCTAssertTrue(report.contains("  App:"))
        XCTAssertTrue(report.contains("    Environment: staging"))
        XCTAssertTrue(report.contains("    User ID: user-123"))
    }

    func testIssueReportIncludesEmptyAppContextState() {
        let metadata = ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-empty",
            startedAt: nil,
            generatedAt: Date(timeIntervalSince1970: 0),
            bundleIdentifier: nil,
            appVersion: nil,
            appBuild: nil,
            processName: "Sample",
            operatingSystemVersion: "Version 18.0",
            deviceModel: "unknown",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC"
        )
        let diagnostics = ConsoleDock.Diagnostics(
            isRunning: false,
            capturesStandardOutput: false,
            capturesStandardError: false,
            showsFloatingButton: false,
            allowsReleaseBuilds: false,
            maximumEntries: 100,
            maximumMessageLength: 4_096,
            entryCount: 0,
            redactedEntryCount: 0,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )
        let report = ConsoleDockIssueReportFormatter.reportText(
            entries: [],
            metadata: metadata,
            diagnostics: diagnostics
        )

        XCTAssertTrue(report.contains("App Context:\n  (no app context)"))
    }

    func testObjectiveCUIKitFacadeAppContextProviderFeedsIssueReport() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDockUIKit.setAppContextProvider {
            [
                ConsoleDockAppContextSection.section(
                    title: "ObjC",
                    items: [
                        ConsoleDockAppContextItem.item(key: "Environment", value: "qa")
                    ]
                )
            ]
        }

        let report = ConsoleDockUIKit.issueReportText()

        XCTAssertTrue(report.contains("  ObjC:"))
        XCTAssertTrue(report.contains("    Environment: qa"))
    }

    func testDebugActionRegistrationStoresMetadata() {
        ConsoleDock.registerAction(
            id: "open.checkout",
            title: "Open Checkout",
            group: "Navigation",
            detail: "Jump to checkout test entry",
            requiresConfirmation: true
        ) {}

        XCTAssertEqual(
            ConsoleDock.debugActions,
            [
                ConsoleDockDebugAction(
                    id: "open.checkout",
                    title: "Open Checkout",
                    group: "Navigation",
                    detail: "Jump to checkout test entry",
                    requiresConfirmation: true
                )
            ]
        )
    }

    func testParameterizedDebugActionRegistrationStoresNormalizedParameters() {
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [
                .string(id: " orderId\n", title: " Order\nID ", detail: " Required\nidentifier ", isRequired: true),
                .string(id: "orderId", title: "Duplicate"),
                .choice(
                    id: " environment ",
                    title: " Environment ",
                    choices: [
                        .init(id: " staging ", title: " Staging "),
                        .init(id: "staging", title: "Duplicate"),
                        .init(id: "\n", title: "Missing ID"),
                        .init(id: "qa", title: "QA")
                    ],
                    defaultChoiceID: " qa "
                ),
                .choice(id: "empty.choice", title: "Empty Choice", choices: [])
            ]
        ) { _ in }

        let parameters = ConsoleDock.debugActions.first?.parameters

        XCTAssertEqual(parameters?.map(\.id), ["orderId", "environment"])
        XCTAssertEqual(parameters?.map(\.title), ["Order ID", "Environment"])
        XCTAssertEqual(parameters?.first?.detail, "Required\nidentifier")
        XCTAssertEqual(parameters?.first?.isRequired, true)
        XCTAssertEqual(parameters?.last?.defaultValue, .choice("qa"))
        XCTAssertEqual(
            parameters?.last?.kind,
            .choice([
                .init(id: "staging", title: "Staging"),
                .init(id: "qa", title: "QA")
            ])
        )
    }

    func testParameterizedDebugActionReceivesNormalizedValues() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Parameterized action executed")

        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .number(id: "count", title: "Count", defaultValue: 2),
                .bool(id: "animated", title: "Animated", defaultValue: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [
                        .init(id: "staging", title: "Staging"),
                        .init(id: "qa", title: "QA")
                    ],
                    defaultChoiceID: "staging"
                )
            ]
        ) { parameters in
            XCTAssertEqual(parameters.string("orderId"), "A123")
            XCTAssertEqual(parameters.number("count"), 4)
            XCTAssertEqual(parameters.bool("animated"), true)
            XCTAssertEqual(parameters.choice("environment"), "qa")
            expectation.fulfill()
        }

        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: [
                "orderId": .string(" A123\n"),
                "count": .number(4),
                "environment": .choice(" qa ")
            ]
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(ConsoleDock.entries.map(\.message).contains("Debug action completed: Open Order [open.order]"))
    }

    func testParameterizedDebugActionRecordsExecutionHistoryWithParameterSummary() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            group: "Navigation",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .number(id: "count", title: "Count", defaultValue: 2),
                .bool(id: "animated", title: "Animated", defaultValue: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [.init(id: "qa", title: "QA")],
                    defaultChoiceID: "qa"
                )
            ]
        ) { _ in }

        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: [
                "orderId": .string(" A123\n"),
                "count": .number(4)
            ]
        )

        let execution = ConsoleDock.actionExecutionHistory.first
        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)
        XCTAssertEqual(execution?.id, 1)
        XCTAssertEqual(execution?.actionID, "open.order")
        XCTAssertEqual(execution?.title, "Open Order")
        XCTAssertEqual(execution?.group, "Navigation")
        XCTAssertEqual(execution?.outcome, .completed)
        XCTAssertEqual(execution?.parameterSummary, "orderId=\"A123\", count=4, animated=true, environment=qa")
        XCTAssertNil(execution?.message)
    }

    func testDebugActionRecordsFailedAndSkippedExecutions() {
        struct FixtureError: Error {}
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.registerAction(id: "throwing", title: "Throwing") {
            throw FixtureError()
        }
        ConsoleDock.registerAction(id: "disabled", title: "Disabled", isEnabled: false) {}
        ConsoleDock.registerAction(
            id: "required",
            title: "Required",
            parameters: [.string(id: "orderId", title: "Order ID", isRequired: true)]
        ) { _ in }

        ConsoleDock.performDebugAction(id: "throwing")
        ConsoleDock.performDebugAction(id: "disabled")
        ConsoleDock.performDebugAction(id: "required")

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.map(\.actionID), ["throwing", "disabled", "required"])
        XCTAssertEqual(ConsoleDock.actionExecutionHistory.map(\.outcome), [.failed, .skipped, .skipped])
        XCTAssertTrue(ConsoleDock.actionExecutionHistory[0].message?.contains("error=") == true)
        XCTAssertEqual(ConsoleDock.actionExecutionHistory[1].message, "disabled")
        XCTAssertEqual(ConsoleDock.actionExecutionHistory[2].message, "missing required parameters: orderId")
    }

    func testActionExecutionHistoryIsClearableWithoutRemovingRecentParameters() {
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [.string(id: "orderId", title: "Order ID", isRequired: true)]
        ) { _ in }

        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )
        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)
        let recentValues = ConsoleDock.recentDebugActionParameterValues(actionID: "open.order")
        XCTAssertEqual(recentValues["orderId"], .string("A-100"))

        ConsoleDock.clearActionExecutionHistory()

        XCTAssertTrue(ConsoleDock.actionExecutionHistory.isEmpty)
        let retainedRecentValues = ConsoleDock.recentDebugActionParameterValues(actionID: "open.order")
        XCTAssertEqual(retainedRecentValues["orderId"], .string("A-100"))
    }

    func testActionRecentParametersAreSessionLocal() {
        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )

        ConsoleDockDebugActionRegistry.shared.resetSessionState()

        XCTAssertTrue(ConsoleDock.recentDebugActionParameterValues(actionID: "open.order").isEmpty)
    }

    func testObjectiveCUIKitFacadeParameterizedActionReceivesObjectiveCValues() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Objective-C parameterized action executed")

        let environmentChoices = [
            ConsoleDockDebugActionChoice.choice(identifier: "staging", title: "Staging"),
            ConsoleDockDebugActionChoice.choice(identifier: "qa", title: "QA")
        ]
        let parameters = [
            ConsoleDockDebugActionParameter.stringParameter(
                identifier: "orderId",
                title: "Order ID",
                detail: nil,
                isRequired: true,
                defaultValue: nil
            ),
            ConsoleDockDebugActionParameter.numberParameter(
                identifier: "count",
                title: "Count",
                detail: nil,
                isRequired: false,
                defaultValue: NSNumber(value: 2)
            ),
            ConsoleDockDebugActionParameter.boolParameter(
                identifier: "animated",
                title: "Animated",
                detail: nil,
                isRequired: false,
                defaultValue: NSNumber(value: true)
            ),
            ConsoleDockDebugActionParameter.choiceParameter(
                identifier: "environment",
                title: "Environment",
                detail: nil,
                isRequired: false,
                choices: environmentChoices,
                defaultChoiceIdentifier: "staging"
            )
        ]

        ConsoleDockUIKit.registerAction(
            identifier: "objc.open.order",
            title: "ObjC Open Order",
            group: "Navigation",
            detail: "Open an order from an Objective-C app",
            requiresConfirmation: false,
            parameters: parameters
        ) { values in
            XCTAssertEqual(values["orderId"] as? String, "A123")
            XCTAssertEqual((values["count"] as? NSNumber)?.doubleValue, 4)
            XCTAssertEqual((values["animated"] as? NSNumber)?.boolValue, true)
            XCTAssertEqual(values["environment"] as? String, "qa")
            expectation.fulfill()
        }

        ConsoleDock.performDebugAction(
            id: "objc.open.order",
            parameterValues: [
                "orderId": .string(" A123 "),
                "count": .number(4),
                "environment": .choice("qa")
            ]
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(
            ConsoleDock.entries.map(\.message)
                .contains("Debug action completed: ObjC Open Order [objc.open.order]")
        )
    }

    func testObjectiveCUIKitFacadeParameterizedActionStoresMetadataAndHonorsDisabledState() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        let parameters = [
            ConsoleDockDebugActionParameter.boolParameter(
                identifier: "enabled",
                title: "Enabled",
                detail: "Optional flag",
                isRequired: false,
                defaultValue: NSNumber(value: true)
            )
        ]

        ConsoleDockUIKit.registerAction(
            identifier: " objc.disabled ",
            title: " ObjC Disabled ",
            group: " Tools ",
            detail: " Cannot run ",
            requiresConfirmation: true,
            isEnabled: false,
            style: .destructive,
            parameters: parameters
        ) { _ in
            didRun = true
        }

        let action = ConsoleDock.debugActions.first
        XCTAssertEqual(action?.id, "objc.disabled")
        XCTAssertEqual(action?.title, "ObjC Disabled")
        XCTAssertEqual(action?.group, "Tools")
        XCTAssertEqual(action?.detail, "Cannot run")
        XCTAssertEqual(action?.requiresConfirmation, true)
        XCTAssertEqual(action?.isEnabled, false)
        XCTAssertEqual(action?.style, .destructive)
        XCTAssertEqual(action?.parameters.first?.id, "enabled")
        XCTAssertEqual(action?.parameters.first?.defaultValue, .bool(true))

        ConsoleDock.performDebugAction(id: "objc.disabled")

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: ObjC Disabled [objc.disabled] disabled"]
        )
    }

    func testParameterizedDebugActionUsesDefaultsForProgrammaticExecution() {
        var received: ConsoleDock.DebugActionParameters?
        ConsoleDock.registerAction(
            id: "defaults",
            title: "Defaults",
            parameters: [
                .number(id: "count", title: "Count", defaultValue: 3),
                .bool(id: "animated", title: "Animated", defaultValue: false),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [
                        .init(id: "staging", title: "Staging")
                    ],
                    defaultChoiceID: "staging"
                )
            ]
        ) { parameters in
            received = parameters
        }

        ConsoleDock.performDebugAction(id: "defaults")

        XCTAssertEqual(received?.number("count"), 3)
        XCTAssertEqual(received?.bool("animated"), false)
        XCTAssertEqual(received?.choice("environment"), "staging")
    }

    func testParameterizedDebugActionSkipsMissingRequiredParameters() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        ConsoleDock.registerAction(
            id: "required",
            title: "Required",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [.init(id: "staging", title: "Staging")],
                    isRequired: true
                )
            ]
        ) { _ in
            didRun = true
        }

        ConsoleDock.performDebugAction(
            id: "required",
            parameterValues: ["environment": .choice("production")]
        )

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: Required [required] missing required parameters: orderId, environment"]
        )
    }

    func testDebugActionRegistrationNormalizesRequiredMetadataAndIgnoresEmptyValues() {
        ConsoleDock.registerAction(id: "   ", title: "Missing ID") {}
        ConsoleDock.registerAction(id: "missing.title", title: " \n ") {}

        var didRun = false
        ConsoleDock.registerAction(
            id: " open.checkout\n",
            title: " Open\nCheckout ",
            group: " Navigation\nTests ",
            detail: " Jump to checkout test entry\n ",
            requiresConfirmation: false
        ) {
            didRun = true
        }

        XCTAssertEqual(
            ConsoleDock.debugActions,
            [
                ConsoleDockDebugAction(
                    id: "open.checkout",
                    title: "Open Checkout",
                    group: "Navigation Tests",
                    detail: "Jump to checkout test entry",
                    requiresConfirmation: false
                )
            ]
        )

        ConsoleDock.performDebugAction(id: " open.checkout ")
        XCTAssertTrue(didRun)

        ConsoleDock.unregisterAction(id: " open.checkout ")
        XCTAssertTrue(ConsoleDock.debugActions.isEmpty)
    }

    func testDebugActionDuplicateIdentifierReplacesInOriginalPosition() {
        ConsoleDock.registerAction(id: "first", title: "First", group: "A") {}
        ConsoleDock.registerAction(id: "second", title: "Second", group: "A") {}
        ConsoleDock.registerAction(id: "first", title: "First Replacement", group: "B", detail: "updated") {}

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["first", "second"])
        XCTAssertEqual(ConsoleDock.debugActions.map(\.title), ["First Replacement", "Second"])
        XCTAssertEqual(ConsoleDock.debugActions[0].group, "B")
        XCTAssertEqual(ConsoleDock.debugActions[0].detail, "updated")
    }

    func testDebugActionUnregisterAndRemoveAllActions() {
        ConsoleDock.registerAction(id: "first", title: "First") {}
        ConsoleDock.registerAction(id: "second", title: "Second") {}

        ConsoleDock.unregisterAction(id: "first")

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["second"])

        ConsoleDock.removeAllActions()

        XCTAssertTrue(ConsoleDock.debugActions.isEmpty)
    }

    func testDebugActionFilterMatchesIDTitleGroupAndDetail() {
        let actions = [
            ConsoleDockDebugAction(
                id: "open.checkout",
                title: "Open Checkout",
                group: "Navigation",
                detail: "Jump to payment"
            ),
            ConsoleDockDebugAction(
                id: "seed.user",
                title: "Seed User",
                group: "Data",
                detail: "Create local account"
            ),
            ConsoleDockDebugAction(
                id: "diagnostics",
                title: "Log Diagnostics",
                group: nil,
                detail: nil
            )
        ]

        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "checkout").map(\.id),
            ["open.checkout"]
        )
        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "seed.user").map(\.id),
            ["seed.user"]
        )
        XCTAssertEqual(ConsoleDockDebugActionFilter.filteredActions(actions, query: "data").map(\.id), ["seed.user"])
        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "PAYMENT").map(\.id),
            ["open.checkout"]
        )
        XCTAssertEqual(ConsoleDockDebugActionFilter.filteredActions(actions, query: " ").map(\.id), actions.map(\.id))
    }

    func testDebugActionPerformsOnMainThreadAndLogsStartAndCompletion() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Debug action executed")

        ConsoleDock.registerAction(id: "smoke", title: "Smoke Action") {
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        DispatchQueue.global().async {
            ConsoleDock.performDebugAction(id: "smoke")
        }

        wait(for: [expectation], timeout: 1.0)

        let messages = ConsoleDock.entries.map(\.message)
        XCTAssertTrue(messages.contains("Debug action started: Smoke Action [smoke]"))
        XCTAssertTrue(messages.contains("Debug action completed: Smoke Action [smoke]"))
    }

    func testDebugActionThrowingHandlerLogsFailure() {
        struct FixtureError: Error {}
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.registerAction(id: "throwing", title: "Throwing Action") {
            throw FixtureError()
        }

        ConsoleDock.performDebugAction(id: "throwing")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.map(\.level), [.info, .error])
        XCTAssertEqual(entries.first?.message, "Debug action started: Throwing Action [throwing]")
        XCTAssertTrue(entries.last?.message.contains("Debug action failed: Throwing Action [throwing]") == true)
    }

    func testDebugActionConfirmationFlagDoesNotPreventRegistryExecution() {
        var didRun = false
        ConsoleDock.registerAction(
            id: "danger",
            title: "Danger",
            requiresConfirmation: true
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.requiresConfirmation, true)
        ConsoleDock.performDebugAction(id: "danger")

        XCTAssertTrue(didRun)
    }

    func testDisabledDebugActionDoesNotRunAndLogsSkipped() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        ConsoleDock.registerAction(
            id: "disabled",
            title: "Disabled Action",
            isEnabled: false
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.isEnabled, false)
        ConsoleDock.performDebugAction(id: "disabled")

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: Disabled Action [disabled] disabled"]
        )
    }

    func testDestructiveDebugActionStyleIsMetadataOnlyForRegistryExecution() {
        var didRun = false
        ConsoleDock.registerAction(
            id: "clear",
            title: "Clear Entries",
            style: .destructive
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.style, .destructive)
        XCTAssertEqual(ConsoleDock.debugActions.first?.requiresConfirmation, false)
        ConsoleDock.performDebugAction(id: "clear")

        XCTAssertTrue(didRun)
    }

    func testDebugActionHandlerDoesNotRunWhileRegistryLockIsHeld() {
        ConsoleDock.registerAction(id: "outer", title: "Outer") {
            ConsoleDock.registerAction(id: "inner", title: "Inner") {}
        }

        ConsoleDock.performDebugAction(id: "outer")

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["outer", "inner"])
    }

    func testDebugActionRegistryHandlesConcurrentRegistration() {
        let queue = DispatchQueue(label: "ConsoleDockTests.DebugActions", attributes: .concurrent)
        let group = DispatchGroup()

        for index in 0..<50 {
            group.enter()
            queue.async {
                ConsoleDock.registerAction(id: "action.\(index)", title: "Action \(index)") {}
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
        XCTAssertEqual(Set(ConsoleDock.debugActions.map(\.id)).count, 50)
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

    func testSessionArchiveSaveStoresRedactedIssueReportMetadata() throws {
        let createdAt = Date(timeIntervalSince1970: 10)
        try withTemporaryArchiveStore(
            dates: [createdAt],
            uuids: [Self.fixtureUUID(1)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.info("checkout token=session-secret")

            let archive = try ConsoleDock.saveSessionArchive(note: " Checkout smoke \n")

            XCTAssertEqual(archive.id, "00000000-0000-0000-0000-000000000001")
            XCTAssertEqual(archive.createdAt, createdAt)
            XCTAssertEqual(archive.sourceSessionIdentifier, ConsoleDock.sessionMetadata.sessionIdentifier)
            XCTAssertNotNil(archive.sourceSessionStartedAt)
            XCTAssertEqual(archive.title, "Session 1970-01-01T00:00:10.000Z")
            XCTAssertEqual(archive.note, "Checkout smoke")
            XCTAssertEqual(archive.entryCount, 1)
            XCTAssertFalse(archive.isReportTruncated)
            XCTAssertTrue(archive.reportText.contains("ConsoleDock Issue Report"))
            XCTAssertTrue(archive.reportText.contains("token=<redacted>"))
            XCTAssertFalse(archive.reportText.contains("session-secret"))
            XCTAssertEqual(try ConsoleDock.sessionArchives(), [archive])
        }
    }

    func testSessionArchiveStoreReturnsNewestFirstAndPrunesOldestArchives() throws {
        try withTemporaryArchiveStore(
            maximumArchives: 2,
            dates: [
                Date(timeIntervalSince1970: 1),
                Date(timeIntervalSince1970: 2),
                Date(timeIntervalSince1970: 3)
            ],
            uuids: [Self.fixtureUUID(1), Self.fixtureUUID(2), Self.fixtureUUID(3)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

            let first = try ConsoleDock.saveSessionArchive(note: "first")
            let second = try ConsoleDock.saveSessionArchive(note: "second")
            let third = try ConsoleDock.saveSessionArchive(note: "third")

            let archives = try ConsoleDock.sessionArchives()
            XCTAssertEqual(archives.map(\.id), [third.id, second.id])
            XCTAssertFalse(archives.map(\.id).contains(first.id))
        }
    }

    func testSessionArchiveStoreTruncatesReportAtConfiguredLimit() throws {
        try withTemporaryArchiveStore(
            maximumReportCharacterCount: 700,
            dates: [Date(timeIntervalSince1970: 1)],
            uuids: [Self.fixtureUUID(1)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.info(String(repeating: "long-message-", count: 500))

            let archive = try ConsoleDock.saveSessionArchive()

            XCTAssertTrue(archive.isReportTruncated)
            XCTAssertGreaterThan(archive.reportCharacterCount, archive.reportText.count)
            XCTAssertLessThanOrEqual(archive.reportText.count, 700)
            XCTAssertTrue(archive.reportText.contains("ConsoleDock archive truncated at 700 characters"))
        }
    }

    func testSessionArchiveDeleteAndClearOperations() throws {
        try withTemporaryArchiveStore(
            dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)],
            uuids: [Self.fixtureUUID(1), Self.fixtureUUID(2)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            let first = try ConsoleDock.saveSessionArchive(note: "first")
            let second = try ConsoleDock.saveSessionArchive(note: "second")

            try ConsoleDock.deleteSessionArchive(id: first.id)

            XCTAssertEqual(try ConsoleDock.sessionArchives().map(\.id), [second.id])

            try ConsoleDock.clearSessionArchives()

            XCTAssertTrue(try ConsoleDock.sessionArchives().isEmpty)
        }
    }

    func testSessionArchiveStoreSurvivesNewInstanceAndSkipsMalformedFiles() throws {
        try withTemporaryArchiveStore(
            dates: [Date(timeIntervalSince1970: 1)],
            uuids: [Self.fixtureUUID(1)]
        ) { directoryURL in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.error("recoverable failure")
            let archive = try ConsoleDock.saveSessionArchive(note: "persisted")
            let malformedURL = directoryURL.appendingPathComponent("malformed.json")
            try "not json".write(to: malformedURL, atomically: true, encoding: .utf8)

            let reloadedStore = ConsoleDockSessionArchiveStore(directoryURL: directoryURL)
            let archives = try reloadedStore.archives()

            XCTAssertEqual(archives.map(\.id), [archive.id])
            XCTAssertTrue(archives.first?.reportText.contains("recoverable failure") == true)
        }
    }

    func testObjectiveCUIKitFacadeBridgesSessionArchiveAPIs() throws {
        try withTemporaryArchiveStore(
            dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)],
            uuids: [Self.fixtureUUID(1), Self.fixtureUUID(2)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
            ConsoleDock.info("ObjC archive")
            var error: NSError?

            let archive = try XCTUnwrap(ConsoleDockUIKit.saveSessionArchive(note: "ObjC note", error: &error))
            XCTAssertNil(error)
            XCTAssertEqual(archive.identifier, "00000000-0000-0000-0000-000000000001")
            XCTAssertEqual(archive.note, "ObjC note")
            XCTAssertTrue(archive.reportText.contains("ObjC archive"))

            let archives = try XCTUnwrap(ConsoleDockUIKit.sessionArchives(error: &error))
            XCTAssertEqual(archives.map(\.identifier), [archive.identifier])

            XCTAssertTrue(ConsoleDockUIKit.deleteSessionArchive(identifier: archive.identifier, error: &error))
            XCTAssertTrue(try ConsoleDock.sessionArchives().isEmpty)

            _ = try XCTUnwrap(ConsoleDockUIKit.saveSessionArchive(note: nil, error: &error))
            XCTAssertTrue(ConsoleDockUIKit.clearSessionArchives(error: &error))
            XCTAssertTrue(try ConsoleDock.sessionArchives().isEmpty)
            XCTAssertNil(error)
        }
    }
}

extension ConsoleDock.Configuration {
    fileprivate static let nativeOnly = ConsoleDock.Configuration(
        captureStandardOutput: false,
        captureStandardError: false
    )
}

extension ConsoleDockTests {
    fileprivate func fixtureMetadata(
        startedAt: Date? = Date(timeIntervalSince1970: 0),
        generatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> ConsoleDock.SessionMetadata {
        ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-fixture",
            startedAt: startedAt,
            generatedAt: generatedAt,
            bundleIdentifier: "com.example.ConsoleDockTests",
            appVersion: "1.0",
            appBuild: "1",
            processName: "ConsoleDockTests",
            operatingSystemVersion: "Version 18.0",
            deviceModel: "iPhone",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC"
        )
    }

    fileprivate func fixtureDiagnostics(
        isRunning: Bool = true,
        capturesStandardOutput: Bool = true,
        capturesStandardError: Bool = true,
        showsFloatingButton: Bool = true,
        allowsReleaseBuilds: Bool = false,
        maximumEntries: Int = 2_000,
        maximumMessageLength: Int = 8_192,
        entryCount: Int = 0,
        redactedEntryCount: Int = 0,
        truncatedEntryCount: Int = 0,
        partialEntryCount: Int = 0
    ) -> ConsoleDock.Diagnostics {
        ConsoleDock.Diagnostics(
            isRunning: isRunning,
            capturesStandardOutput: capturesStandardOutput,
            capturesStandardError: capturesStandardError,
            showsFloatingButton: showsFloatingButton,
            allowsReleaseBuilds: allowsReleaseBuilds,
            maximumEntries: maximumEntries,
            maximumMessageLength: maximumMessageLength,
            entryCount: entryCount,
            redactedEntryCount: redactedEntryCount,
            truncatedEntryCount: truncatedEntryCount,
            partialEntryCount: partialEntryCount
        )
    }

    fileprivate static func fixtureUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    fileprivate func withTemporaryArchiveStore(
        maximumArchives: Int = 5,
        maximumReportCharacterCount: Int = 256_000,
        dates: [Date] = [Date(timeIntervalSince1970: 0)],
        uuids: [UUID] = [ConsoleDockTests.fixtureUUID(1)],
        _ body: (URL) throws -> Void
    ) rethrows {
        let originalStore = ConsoleDockSessionArchiveStore.shared
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConsoleDockTests-\(UUID().uuidString)", isDirectory: true)
        var remainingDates = dates
        var remainingUUIDs = uuids
        ConsoleDockSessionArchiveStore.shared = ConsoleDockSessionArchiveStore(
            directoryURL: directoryURL,
            maximumArchives: maximumArchives,
            maximumReportCharacterCount: maximumReportCharacterCount,
            dateProvider: {
                remainingDates.isEmpty ? Date(timeIntervalSince1970: 0) : remainingDates.removeFirst()
            },
            uuidProvider: {
                remainingUUIDs.isEmpty ? UUID() : remainingUUIDs.removeFirst()
            }
        )
        defer {
            ConsoleDockSessionArchiveStore.shared = originalStore
            try? FileManager.default.removeItem(at: directoryURL)
        }
        try body(directoryURL)
    }

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
