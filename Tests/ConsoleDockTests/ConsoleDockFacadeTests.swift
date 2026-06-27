import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockFacadeTests: ConsoleDockTestCase {
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

    func testObjectiveCUIKitFacadeStartResetsDebugActionSessionState() {
        let configuration = CDKConfiguration()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false
        configuration.showsFloatingButton = false

        XCTAssertEqual(ConsoleDockUIKit.start(configuration: configuration, error: nil), .started)
        ConsoleDock.registerAction(id: "session.action", title: "Session Action") {}
        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "session.action",
            parameterValues: ["orderId": .string("A-100")]
        )
        ConsoleDock.performDebugAction(id: "session.action")

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)
        XCTAssertFalse(ConsoleDock.recentDebugActionParameterValues(actionID: "session.action").isEmpty)

        ConsoleDockUIKit.stop()
        XCTAssertEqual(ConsoleDockUIKit.start(configuration: configuration, error: nil), .started)

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["session.action"])
        XCTAssertTrue(ConsoleDock.actionExecutionHistory.isEmpty)
        XCTAssertTrue(ConsoleDock.recentDebugActionParameterValues(actionID: "session.action").isEmpty)
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

    func testSwiftFacadeAlreadyRunningKeepsActiveDiagnosticsConfiguration() {
        let firstConfiguration = ConsoleDock.Configuration(
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: false,
            floatingButtonPosition: .topLeading
        )
        let secondConfiguration = ConsoleDock.Configuration(
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: true,
            floatingButtonPosition: .bottomLeading
        )

        XCTAssertEqual(ConsoleDock.start(configuration: firstConfiguration), .started)
        XCTAssertEqual(ConsoleDock.start(configuration: secondConfiguration), .alreadyRunning)

        XCTAssertFalse(ConsoleDock.diagnostics.showsFloatingButton)
        XCTAssertEqual(ConsoleDock.diagnostics.floatingButtonPosition, .topLeading)
    }

    func testSwiftDiagnosticsMapsCoreFields() {
        let configuration = ConsoleDock.Configuration(
            maximumEntries: 9,
            maximumMessageLength: 12,
            captureStandardOutput: false,
            captureStandardError: false,
            showsFloatingButton: false,
            floatingButtonPosition: .topTrailing,
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
        XCTAssertEqual(diagnostics.floatingButtonPosition, .topTrailing)
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
        XCTAssertTrue(entry.isMarker)
        XCTAssertTrue(entry.redacted)
    }

    func testSwiftFacadeNativeLogWithMarkerPrefixIsNotMarkerEntry() throws {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.info("[marker] ordinary log")

        let entry = try XCTUnwrap(ConsoleDock.entries.first)
        XCTAssertEqual(entry.message, "[marker] ordinary log")
        XCTAssertFalse(entry.isMarker)
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
        XCTAssertFalse(entry.isMarker)
        XCTAssertFalse(entry.partial)
        XCTAssertFalse(entry.redacted)
        XCTAssertFalse(entry.truncated)
    }
}
