import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockFilteringTests: ConsoleDockTestCase {
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
}
