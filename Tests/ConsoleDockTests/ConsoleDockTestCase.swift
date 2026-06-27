import ConsoleDockCore
import XCTest

@testable import ConsoleDock

class ConsoleDockTestCase: XCTestCase {
    override func tearDown() {
        ConsoleDock.removeAllActions()
        ConsoleDock.clearAppContextProvider()
        ConsoleDock.clear()
        ConsoleDock.stop()
        super.tearDown()
    }
}

extension ConsoleDock.Configuration {
    static let nativeOnly = ConsoleDock.Configuration(
        captureStandardOutput: false,
        captureStandardError: false
    )
}

extension ConsoleDockTestCase {
    func fixtureMetadata(
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

    func fixtureDiagnostics(
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

    static func fixtureUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    func withTemporaryArchiveStore(
        maximumArchives: Int = 5,
        maximumReportCharacterCount: Int = 256_000,
        dates: [Date] = [Date(timeIntervalSince1970: 0)],
        uuids: [UUID] = [ConsoleDockTestCase.fixtureUUID(1)],
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

    func filterFixtureEntries() -> [ConsoleDock.LogEntry] {
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
