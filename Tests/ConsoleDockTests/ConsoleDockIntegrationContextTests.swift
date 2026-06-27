import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockIntegrationContextTests: ConsoleDockTestCase {
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

    func testAppContextRedactsSensitiveValuesBeforeReports() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.setAppContextProvider {
            [
                ConsoleDock.AppContextSection(
                    title: "Auth",
                    items: [
                        .init(key: "Access Token", value: "secret-token-value"),
                        .init(key: "Headers", value: "Authorization: Bearer bearer-secret")
                    ]
                )
            ]
        }

        let snapshot = ConsoleDock.appContext
        XCTAssertEqual(snapshot.first?.items.first?.value, "<redacted>")
        XCTAssertEqual(snapshot.first?.items.last?.value, "Authorization: <redacted>")

        let report = ConsoleDock.issueReportText()
        XCTAssertTrue(report.contains("    Access Token: <redacted>"))
        XCTAssertTrue(report.contains("    Headers: Authorization: <redacted>"))
        XCTAssertFalse(report.contains("secret-token-value"))
        XCTAssertFalse(report.contains("bearer-secret"))
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
}
