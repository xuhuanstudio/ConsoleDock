import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockObserverArchiveTests: ConsoleDockTestCase {
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

    func testSessionArchiveSaveRedactsSensitiveNote() throws {
        let createdAt = Date(timeIntervalSince1970: 10)
        try withTemporaryArchiveStore(
            dates: [createdAt],
            uuids: [Self.fixtureUUID(1)]
        ) { _ in
            XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

            let archive = try ConsoleDock.saveSessionArchive(note: "token=session-secret")

            XCTAssertEqual(archive.note, "token=<redacted>")
            XCTAssertFalse(archive.note?.contains("session-secret") == true)
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
