import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockReportTests: ConsoleDockTestCase {
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
        XCTAssertTrue(report.text.contains("Support Report:"))
        XCTAssertFalse(report.text.contains("Support Bundle:"))
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
}
