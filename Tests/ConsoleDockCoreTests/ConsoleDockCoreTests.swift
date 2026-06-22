import ConsoleDockCore
import XCTest

final class ConsoleDockCoreTests: XCTestCase {
    override func tearDown() {
        CDKConsoleDock.clearEntries()
        CDKConsoleDock.stop()
        super.tearDown()
    }

    func testDefaultConfigurationValues() {
        let configuration = CDKConfiguration.default()

        XCTAssertEqual(configuration.maximumEntries, 2_000)
        XCTAssertEqual(configuration.maximumMessageLength, 8_192)
        XCTAssertTrue(configuration.captureStandardOutput)
        XCTAssertTrue(configuration.captureStandardError)
        XCTAssertTrue(configuration.showsFloatingButton)
        XCTAssertFalse(configuration.allowsReleaseBuilds)
    }

    func testStartStopLifecycle() {
        let result = CDKConsoleDock.start(with: .default())

        XCTAssertEqual(result, .started)
        XCTAssertTrue(CDKConsoleDock.isRunning())

        CDKConsoleDock.stop()

        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testRepeatedStartAndStopAreStable() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .alreadyRunning)

        CDKConsoleDock.stop()
        CDKConsoleDock.stop()

        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testInvalidConfigurationFailsWithoutStarting() {
        let configuration = CDKConfiguration.default()
        configuration.maximumEntries = 0

        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .failed)
        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testInvalidConfigurationPopulatesNSError() {
        let configuration = CDKConfiguration.default()
        configuration.maximumEntries = 0
        var error: NSError?

        let result = CDKConsoleDock.start(with: configuration, error: &error)

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(error?.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(error?.code, 1)
        XCTAssertEqual(error?.localizedDescription, "maximumEntries must be greater than zero")
        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testInvalidMessageLengthFailsWithoutStarting() {
        let configuration = CDKConfiguration.default()
        configuration.maximumMessageLength = 0
        var error: NSError?

        let result = CDKConsoleDock.start(with: configuration, error: &error)

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(error?.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(error?.code, 2)
        XCTAssertEqual(error?.localizedDescription, "maximumMessageLength must be greater than zero")
        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testNativeLogAppendsReadableEntry() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)

        let before = Date()
        CDKConsoleDock.info("Login succeeded")
        let after = Date()

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].level, .info)
        XCTAssertEqual(entries[0].source, .native)
        XCTAssertEqual(entries[0].message, "Login succeeded")
        XCTAssertGreaterThanOrEqual(entries[0].timestamp.timeIntervalSince1970, before.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(entries[0].timestamp.timeIntervalSince1970, after.timeIntervalSince1970)
    }

    func testRingBufferEvictsOldestEntries() {
        let configuration = CDKConfiguration.default()
        configuration.maximumEntries = 2
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.debug("one")
        CDKConsoleDock.info("two")
        CDKConsoleDock.error("three")

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.map(\.message), ["two", "three"])
        XCTAssertEqual(entries.map(\.level), [.info, .error])
    }

    func testStartResetsSessionStore() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)
        CDKConsoleDock.info("previous")
        XCTAssertEqual(CDKConsoleDock.entries().map(\.message), ["previous"])

        CDKConsoleDock.stop()
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)
        CDKConsoleDock.info("current")

        XCTAssertEqual(CDKConsoleDock.entries().map(\.message), ["current"])
    }

    func testClearEntriesRemovesStoredEntries() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)
        CDKConsoleDock.warning("Retrying")

        XCTAssertEqual(CDKConsoleDock.entries().count, 1)

        CDKConsoleDock.clearEntries()

        XCTAssertTrue(CDKConsoleDock.entries().isEmpty)
    }

    func testDefaultRedactionRunsBeforeStorage() throws {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)

        CDKConsoleDock.info("Authorization: Bearer bearer123 password=hunter2 token=tok123 api_key=api123 key=key123 secret=secret123")

        let message = try XCTUnwrap(CDKConsoleDock.entries().first?.message)
        XCTAssertTrue(message.contains("<redacted>"))
        XCTAssertFalse(message.contains("bearer123"))
        XCTAssertFalse(message.contains("hunter2"))
        XCTAssertFalse(message.contains("tok123"))
        XCTAssertFalse(message.contains("api123"))
        XCTAssertFalse(message.contains("key123"))
        XCTAssertFalse(message.contains("secret123"))
    }

    func testCustomRedactionRunsBeforeStorage() {
        let configuration = CDKConfiguration.default()
        configuration.redactionBlock = { message in
            message.replacingOccurrences(of: "user_id=42", with: "user_id=<redacted>")
        }
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.info("Loaded user_id=42")

        XCTAssertEqual(CDKConsoleDock.entries().first?.message, "Loaded user_id=<redacted>")
    }

    func testMessageIsTruncatedBeforeStorage() {
        let configuration = CDKConfiguration.default()
        configuration.maximumMessageLength = 5
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.info("123456789")

        XCTAssertEqual(CDKConsoleDock.entries().first?.message, "12345")
    }

    func testNativeLoggingIsNoOpWhenNotRunning() {
        CDKConsoleDock.info("Should not be stored")

        XCTAssertTrue(CDKConsoleDock.entries().isEmpty)
    }

    func testLineFramerEmitsSingleLine() {
        let framer = CDKLineFramer()

        let events = framer.append(Data("hello\n".utf8), source: .stdout)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].source, .stdout)
        XCTAssertEqual(events[0].message, "hello")
        XCTAssertFalse(events[0].isPartial)
    }

    func testLineFramerEmitsMultipleLinesFromOneChunk() {
        let framer = CDKLineFramer()

        let events = framer.append(Data("first\nsecond\n".utf8), source: .stdout)

        XCTAssertEqual(events.map(\.message), ["first", "second"])
        XCTAssertEqual(events.map(\.source), [.stdout, .stdout])
        XCTAssertEqual(events.map(\.isPartial), [false, false])
    }

    func testLineFramerMergesPartialAcrossChunks() {
        let framer = CDKLineFramer()

        XCTAssertTrue(framer.append(Data("hel".utf8), source: .stdout).isEmpty)
        let events = framer.append(Data("lo\n".utf8), source: .stdout)

        XCTAssertEqual(events.map(\.message), ["hello"])
        XCTAssertFalse(events[0].isPartial)
    }

    func testLineFramerFlushesPartial() {
        let framer = CDKLineFramer()

        XCTAssertTrue(framer.append(Data("partial".utf8), source: .stdout).isEmpty)
        let events = framer.flushSource(.stdout)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].message, "partial")
        XCTAssertTrue(events[0].isPartial)
        XCTAssertTrue(framer.flushSource(.stdout).isEmpty)
    }

    func testLineFramerFlushEmptyIsNoOp() {
        let framer = CDKLineFramer()

        XCTAssertTrue(framer.flushSource(.stdout).isEmpty)
    }

    func testLineFramerPreservesEmptyLines() {
        let framer = CDKLineFramer()

        let events = framer.append(Data("a\n\n".utf8), source: .stdout)

        XCTAssertEqual(events.map(\.message), ["a", ""])
        XCTAssertEqual(events.map(\.isPartial), [false, false])
    }

    func testLineFramerNormalizesCRLF() {
        let framer = CDKLineFramer()

        let events = framer.append(Data("a\r\n".utf8), source: .stdout)

        XCTAssertEqual(events.map(\.message), ["a"])
    }

    func testLineFramerKeepsSourceBuffersIndependent() {
        let framer = CDKLineFramer()

        XCTAssertTrue(framer.append(Data("out".utf8), source: .stdout).isEmpty)
        let stderrEvents = framer.append(Data("err\n".utf8), source: .stderr)
        let stdoutEvents = framer.append(Data("\n".utf8), source: .stdout)

        XCTAssertEqual(stderrEvents.map(\.source), [.stderr])
        XCTAssertEqual(stderrEvents.map(\.message), ["err"])
        XCTAssertEqual(stdoutEvents.map(\.source), [.stdout])
        XCTAssertEqual(stdoutEvents.map(\.message), ["out"])
    }

    func testLineFramerReplacesInvalidUTF8() {
        let framer = CDKLineFramer()

        let events = framer.append(Data([0x61, 0xFF, 0x62, 0x0A]), source: .stdout)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].message, "a\u{FFFD}b")
    }

    func testLineFramerBoundsVeryLongPartial() {
        let framer = CDKLineFramer(maximumPartialBytes: 4)

        let immediateEvents = framer.append(Data("12345".utf8), source: .stdout)
        let flushedEvents = framer.flushSource(.stdout)

        XCTAssertEqual(immediateEvents.count, 1)
        XCTAssertEqual(immediateEvents[0].message, "1234")
        XCTAssertTrue(immediateEvents[0].isPartial)
        XCTAssertEqual(flushedEvents.count, 1)
        XCTAssertEqual(flushedEvents[0].message, "5")
        XCTAssertTrue(flushedEvents[0].isPartial)
    }

    func testAppendLineEventStoresStdoutAndStderrEntries() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "out", isPartial: false))
        CDKConsoleDock.append(CDKLineEvent(source: .stderr, message: "err", isPartial: false))

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.map(\.source), [.stdout, .stderr])
        XCTAssertEqual(entries.map(\.level), [.info, .error])
        XCTAssertEqual(entries.map(\.message), ["out", "err"])
    }

    func testAppendLineEventUsesRedactionAndTruncation() {
        let configuration = CDKConfiguration.default()
        configuration.maximumMessageLength = 18
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "password=hunter2 suffix", isPartial: false))

        XCTAssertEqual(CDKConsoleDock.entries().first?.message, "password=<redacted")
    }
}
