import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockSnapshotTimelineTests: ConsoleDockTestCase {
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
                message: "[marker] Open checkout",
                isMarker: true
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
                message: "[marker] Still included",
                isMarker: true
            ),
            ConsoleDock.LogEntry(
                id: 5,
                timestamp: Date(timeIntervalSince1970: 5),
                level: .info,
                source: .native,
                message: "[marker] ordinary log prefix"
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
                message: "[marker] second marker",
                isMarker: true
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
                message: "[marker] Started checkout",
                isMarker: true
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
                message: "[marker] Open checkout",
                isMarker: true
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

    func testIssueReportFormatterDoesNotTreatOrdinaryMarkerPrefixLogAsMarker() {
        let metadata = ConsoleDock.SessionMetadata(
            sessionIdentifier: "session-prefix",
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
            entryCount: 1,
            redactedEntryCount: 0,
            truncatedEntryCount: 0,
            partialEntryCount: 0
        )
        let entries = [
            ConsoleDock.LogEntry(
                timestamp: Date(timeIntervalSince1970: 2),
                level: .info,
                source: .native,
                message: "[marker] ordinary log prefix"
            )
        ]

        let report = ConsoleDockIssueReportFormatter.reportText(
            entries: entries,
            metadata: metadata,
            diagnostics: diagnostics
        )

        XCTAssertTrue(report.contains("Reproduction Timeline:\n  (no timeline events)"))
        XCTAssertTrue(report.contains("Markers:\n  (no markers)"))
        XCTAssertTrue(
            report.contains(
                "Logs:\n  [1970-01-01T00:00:02.000Z] [native] [INFO] [marker] ordinary log prefix"
            )
        )
    }
}
