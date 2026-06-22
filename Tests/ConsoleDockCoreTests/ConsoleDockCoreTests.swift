import ConsoleDockCore
import Darwin
import XCTest

final class ConsoleDockCoreTests: XCTestCase {
    private static let descriptorLock = NSLock()

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

    func testReleaseBuildDefaultStartGateIsDisabled() {
        let configuration = noCaptureConfiguration()

        let result = CDKConsoleDock.start(with: configuration)

        #if DEBUG
            XCTAssertEqual(result, .started)
            XCTAssertTrue(CDKConsoleDock.isRunning())
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(CDKConsoleDock.isRunning())
        #endif
    }

    func testReleaseBuildOptInRequiresCompileTimeFlagAndRuntimeConfiguration() {
        let configuration = noCaptureConfiguration()
        configuration.allowsReleaseBuilds = true

        let result = CDKConsoleDock.start(with: configuration)

        #if DEBUG || CONSOLEDOCK_ENABLE_RELEASE
            XCTAssertEqual(result, .started)
            XCTAssertTrue(CDKConsoleDock.isRunning())
        #else
            XCTAssertEqual(result, .disabled)
            XCTAssertFalse(CDKConsoleDock.isRunning())
        #endif
    }

    func testStartStopLifecycle() {
        let result = CDKConsoleDock.start(with: noCaptureConfiguration())

        XCTAssertEqual(result, .started)
        XCTAssertTrue(CDKConsoleDock.isRunning())

        CDKConsoleDock.stop()

        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testRepeatedStartAndStopAreStable() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .alreadyRunning)

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
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        let before = Date()
        CDKConsoleDock.info("Login succeeded")
        let after = Date()

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].level, .info)
        XCTAssertEqual(entries[0].source, .native)
        XCTAssertEqual(entries[0].message, "Login succeeded")
        XCTAssertFalse(entries[0].redacted)
        XCTAssertFalse(entries[0].truncated)
        XCTAssertGreaterThanOrEqual(entries[0].timestamp.timeIntervalSince1970, before.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(entries[0].timestamp.timeIntervalSince1970, after.timeIntervalSince1970)
    }

    func testStoredEntriesReceiveIncreasingIdentifiers() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        CDKConsoleDock.info("first")
        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "second", isPartial: false))
        CDKConsoleDock.error("third")

        XCTAssertEqual(CDKConsoleDock.entries().map(\.identifier), [1, 2, 3])
    }

    func testStartResetsEntryIdentifiersWithSessionStore() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("previous session")
        XCTAssertEqual(CDKConsoleDock.entries().map(\.identifier), [1])

        CDKConsoleDock.stop()
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("current session")

        XCTAssertEqual(CDKConsoleDock.entries().map(\.identifier), [1])
    }

    func testLogEntryInitializersExposeEntryMetadata() {
        let timestamp = Date(timeIntervalSince1970: 1)

        let identifiedEntry = CDKLogEntry(
            identifier: 42,
            timestamp: timestamp,
            level: .info,
            source: .native,
            message: "identified"
        )
        let processedEntry = CDKLogEntry(
            identifier: 43,
            timestamp: timestamp,
            level: .warning,
            source: .stderr,
            message: "processed",
            redacted: true,
            truncated: true
        )
        let compatibilityEntry = CDKLogEntry(
            timestamp: timestamp,
            level: .info,
            source: .native,
            message: "compatibility"
        )

        XCTAssertEqual(identifiedEntry.identifier, 42)
        XCTAssertEqual(identifiedEntry.timestamp, timestamp)
        XCTAssertEqual(compatibilityEntry.identifier, 0)
        XCTAssertFalse(identifiedEntry.redacted)
        XCTAssertFalse(identifiedEntry.truncated)
        XCTAssertEqual(processedEntry.identifier, 43)
        XCTAssertTrue(processedEntry.redacted)
        XCTAssertTrue(processedEntry.truncated)
    }

    func testNativeFaultLogAppendsFaultEntry() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        CDKConsoleDock.fault("Disk corruption detected")

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].level, .fault)
        XCTAssertEqual(entries[0].source, .native)
        XCTAssertEqual(entries[0].message, "Disk corruption detected")
    }

    func testRingBufferEvictsOldestEntries() {
        let configuration = noCaptureConfiguration()
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
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("previous")
        XCTAssertEqual(CDKConsoleDock.entries().map(\.message), ["previous"])

        CDKConsoleDock.stop()
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("current")

        XCTAssertEqual(CDKConsoleDock.entries().map(\.message), ["current"])
    }

    func testClearEntriesRemovesStoredEntries() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.warning("Retrying")

        XCTAssertEqual(CDKConsoleDock.entries().count, 1)

        CDKConsoleDock.clearEntries()

        XCTAssertTrue(CDKConsoleDock.entries().isEmpty)
    }

    func testDefaultRedactionRunsBeforeStorage() throws {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        CDKConsoleDock.info(
            """
            Authorization: Bearer bearer123
            Cookie: session=cookie123; refresh=cookie456
            Set-Cookie: session=setcookie123
            password=hunter2 passwd=pass123 token=tok123 access_token=access123 refresh-token=refresh123 api_key=api123 client_secret=client123 key=key123 secret=secret123
            {"refresh_token":"jsonRefresh123","client_secret":"jsonClient123"}
            """
        )

        let entry = try XCTUnwrap(CDKConsoleDock.entries().first)
        let message = entry.message
        XCTAssertTrue(message.contains("<redacted>"))
        XCTAssertTrue(message.contains("Authorization: Bearer <redacted>"))
        XCTAssertTrue(message.contains("Cookie: <redacted>"))
        XCTAssertTrue(message.contains("Set-Cookie: <redacted>"))
        XCTAssertTrue(entry.redacted)
        XCTAssertFalse(entry.truncated)
        XCTAssertFalse(message.contains("bearer123"))
        XCTAssertFalse(message.contains("cookie123"))
        XCTAssertFalse(message.contains("cookie456"))
        XCTAssertFalse(message.contains("setcookie123"))
        XCTAssertFalse(message.contains("hunter2"))
        XCTAssertFalse(message.contains("pass123"))
        XCTAssertFalse(message.contains("tok123"))
        XCTAssertFalse(message.contains("access123"))
        XCTAssertFalse(message.contains("refresh123"))
        XCTAssertFalse(message.contains("api123"))
        XCTAssertFalse(message.contains("client123"))
        XCTAssertFalse(message.contains("key123"))
        XCTAssertFalse(message.contains("secret123"))
        XCTAssertFalse(message.contains("jsonRefresh123"))
        XCTAssertFalse(message.contains("jsonClient123"))
    }

    func testCustomRedactionRunsBeforeStorage() {
        let configuration = noCaptureConfiguration()
        configuration.redactionBlock = { message in
            message.replacingOccurrences(of: "user_id=42", with: "user_id=<redacted>")
        }
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.info("Loaded user_id=42")

        let entry = CDKConsoleDock.entries().first
        XCTAssertEqual(entry?.message, "Loaded user_id=<redacted>")
        XCTAssertEqual(entry?.redacted, true)
        XCTAssertEqual(entry?.truncated, false)
    }

    func testMessageIsTruncatedBeforeStorage() {
        let configuration = noCaptureConfiguration()
        configuration.maximumMessageLength = 5
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.info("123456789")

        let entry = CDKConsoleDock.entries().first
        XCTAssertEqual(entry?.message, "12345")
        XCTAssertEqual(entry?.redacted, false)
        XCTAssertEqual(entry?.truncated, true)
    }

    func testNativeLoggingIsNoOpWhenNotRunning() {
        CDKConsoleDock.info("Should not be stored")

        XCTAssertTrue(CDKConsoleDock.entries().isEmpty)
    }

    func testNativeLogAppendPostsEntriesDidChangeNotification() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.info("notify native")

        XCTAssertEqual(notifications.count, 1)
        assertNotificationObjectIsConsoleDock(notifications[0])
    }

    func testAppendLineEventPostsEntriesDidChangeNotification() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "notify line event", isPartial: false))

        XCTAssertEqual(notifications.count, 1)
        assertNotificationObjectIsConsoleDock(notifications[0])
    }

    func testClearEntriesAfterStoredEntriesPostsNotification() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("before clear notification")
        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.clearEntries()

        XCTAssertEqual(notifications.count, 1)
        assertNotificationObjectIsConsoleDock(notifications[0])
    }

    func testClearEntriesWhenEmptyDoesNotPostNotification() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.clearEntries()

        XCTAssertTrue(notifications.isEmpty)
    }

    func testStartResettingStoredEntriesPostsNotification() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        CDKConsoleDock.info("previous session")
        CDKConsoleDock.stop()

        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        XCTAssertTrue(CDKConsoleDock.entries().isEmpty)
        XCTAssertEqual(notifications.count, 1)
        assertNotificationObjectIsConsoleDock(notifications[0])
    }

    func testLoggingWhileNotRunningDoesNotPostNotification() {
        var notifications: [Notification] = []
        let observer = observeEntriesDidChange { notification in
            notifications.append(notification)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.info("not running notification")

        XCTAssertTrue(notifications.isEmpty)
    }

    func testEntriesCanBeReadFromNotificationObserver() {
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)
        var snapshotMessages: [String] = []
        let observer = observeEntriesDidChange { _ in
            snapshotMessages = CDKConsoleDock.entries().map(\.message)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        CDKConsoleDock.info("reentrant snapshot")

        XCTAssertEqual(snapshotMessages, ["reentrant snapshot"])
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
        XCTAssertEqual(CDKConsoleDock.start(with: noCaptureConfiguration()), .started)

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "out", isPartial: false))
        CDKConsoleDock.append(CDKLineEvent(source: .stderr, message: "err", isPartial: false))

        let entries = CDKConsoleDock.entries()
        XCTAssertEqual(entries.map(\.source), [.stdout, .stderr])
        XCTAssertEqual(entries.map(\.level), [.info, .error])
        XCTAssertEqual(entries.map(\.message), ["out", "err"])
    }

    func testAppendLineEventUsesRedactionAndTruncation() {
        let configuration = noCaptureConfiguration()
        configuration.maximumMessageLength = 18
        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

        CDKConsoleDock.append(CDKLineEvent(source: .stdout, message: "password=hunter2 suffix", isPartial: false))

        XCTAssertEqual(CDKConsoleDock.entries().first?.message, "password=<redacted")
    }

    func testCaptureStdoutDirectWriteEntersEntries() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { _ in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stdout direct\n", to: STDOUT_FILENO)

            let entry = try waitForEntry(message: "cdk stdout direct", source: .stdout)
            XCTAssertEqual(entry.level, .info)
        }
    }

    func testCaptureStderrDirectWriteEntersEntries() throws {
        try withOriginalDescriptorPipe(STDERR_FILENO) { _ in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stderr direct\n", to: STDERR_FILENO)

            let entry = try waitForEntry(message: "cdk stderr direct", source: .stderr)
            XCTAssertEqual(entry.level, .error)
        }
    }

    func testCaptureSwiftPrintEntersEntriesAndPassthrough() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            print("cdk swift print")
            fflush(stdout)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk swift print\n"))
            let entry = try waitForEntry(message: "cdk swift print", source: .stdout)
            XCTAssertEqual(entry.level, .info)
        }
    }

    func testCaptureFlushedCStdoutEntersEntriesAndPassthrough() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            fputs("cdk flushed c stdout\n", stdout)
            fflush(stdout)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk flushed c stdout\n"))
            let entry = try waitForEntry(message: "cdk flushed c stdout", source: .stdout)
            XCTAssertEqual(entry.level, .info)
        }
    }

    func testCaptureFlushedCStderrEntersEntriesAndPassthrough() throws {
        try withOriginalDescriptorPipe(STDERR_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            fputs("cdk flushed c stderr\n", stderr)
            fflush(stderr)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk flushed c stderr\n"))
            let entry = try waitForEntry(message: "cdk flushed c stderr", source: .stderr)
            XCTAssertEqual(entry.level, .error)
        }
    }

    func testStdoutPassthroughWritesToOriginalDescriptor() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stdout passthrough\n", to: STDOUT_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk stdout passthrough\n"))
            _ = try waitForEntry(message: "cdk stdout passthrough", source: .stdout)
        }
    }

    func testStderrPassthroughWritesToOriginalDescriptor() throws {
        try withOriginalDescriptorPipe(STDERR_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stderr passthrough\n", to: STDERR_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk stderr passthrough\n"))
            _ = try waitForEntry(message: "cdk stderr passthrough", source: .stderr)
        }
    }

    func testDisabledStdoutCaptureDoesNotEnterEntries() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stdout disabled\n", to: STDOUT_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk stdout disabled\n"))
            XCTAssertFalse(waitForEntryIfPresent(message: "cdk stdout disabled", source: .stdout))
        }
    }

    func testDisabledStderrCaptureDoesNotEnterEntries() throws {
        try withOriginalDescriptorPipe(STDERR_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stderr disabled\n", to: STDERR_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk stderr disabled\n"))
            XCTAssertFalse(waitForEntryIfPresent(message: "cdk stderr disabled", source: .stderr))
        }
    }

    func testStopRestoresStdoutDescriptor() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk before stop\n", to: STDOUT_FILENO)
            _ = try waitForEntry(message: "cdk before stop", source: .stdout)

            CDKConsoleDock.stop()
            CDKConsoleDock.clearEntries()
            try writeAll("cdk after stop\n", to: STDOUT_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk after stop\n"))
            XCTAssertFalse(waitForEntryIfPresent(message: "cdk after stop", source: .stdout))
        }
    }

    func testStopRestoresStderrDescriptor() throws {
        try withOriginalDescriptorPipe(STDERR_FILENO) { readDescriptor in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardOutput = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk stderr before stop\n", to: STDERR_FILENO)
            _ = try waitForEntry(message: "cdk stderr before stop", source: .stderr)

            CDKConsoleDock.stop()
            CDKConsoleDock.clearEntries()
            try writeAll("cdk stderr after stop\n", to: STDERR_FILENO)

            XCTAssertTrue(try waitForDescriptor(readDescriptor, toContain: "cdk stderr after stop\n"))
            XCTAssertFalse(waitForEntryIfPresent(message: "cdk stderr after stop", source: .stderr))
        }
    }

    func testPartialLineIsFlushedOnStop() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { _ in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)

            try writeAll("cdk partial stop", to: STDOUT_FILENO)
            CDKConsoleDock.stop()

            let entry = try waitForEntry(message: "cdk partial stop", source: .stdout)
            XCTAssertEqual(entry.level, .info)
        }
    }

    func testCaptureRepeatedStartAndStopRemainsStable() throws {
        try withOriginalDescriptorPipe(STDOUT_FILENO) { _ in
            let configuration = CDKConfiguration.default()
            configuration.captureStandardError = false

            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .alreadyRunning)
            CDKConsoleDock.stop()
            CDKConsoleDock.stop()

            XCTAssertFalse(CDKConsoleDock.isRunning())
            XCTAssertEqual(CDKConsoleDock.start(with: configuration), .started)
            CDKConsoleDock.stop()
            XCTAssertFalse(CDKConsoleDock.isRunning())
        }
    }
}

extension ConsoleDockCoreTests {
    fileprivate func observeEntriesDidChange(_ handler: @escaping (Notification) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.CDKConsoleDockEntriesDidChange,
            object: CDKConsoleDock.self,
            queue: nil,
            using: handler
        )
    }

    fileprivate func assertNotificationObjectIsConsoleDock(
        _ notification: Notification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(notification.object as AnyObject === CDKConsoleDock.self, file: file, line: line)
    }

    fileprivate func noCaptureConfiguration() -> CDKConfiguration {
        let configuration = CDKConfiguration.default()
        configuration.captureStandardOutput = false
        configuration.captureStandardError = false
        return configuration
    }

    fileprivate func withOriginalDescriptorPipe(_ descriptor: Int32, body: (Int32) throws -> Void) throws {
        Self.descriptorLock.lock()
        defer { Self.descriptorLock.unlock() }

        fflush(stdout)
        fflush(stderr)

        let savedDescriptor = dup(descriptor)
        XCTAssertGreaterThanOrEqual(savedDescriptor, 0)
        var pipeDescriptors: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&pipeDescriptors), 0)

        let readDescriptor = pipeDescriptors[0]
        let writeDescriptor = pipeDescriptors[1]
        XCTAssertGreaterThanOrEqual(dup2(writeDescriptor, descriptor), 0)
        close(writeDescriptor)

        defer {
            CDKConsoleDock.stop()
            fflush(stdout)
            fflush(stderr)
            dup2(savedDescriptor, descriptor)
            close(savedDescriptor)
            close(readDescriptor)
        }

        try body(readDescriptor)
    }

    fileprivate func writeAll(_ string: String, to descriptor: Int32) throws {
        let bytes = Array(string.utf8)
        try bytes.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else {
                return
            }
            var written = 0
            while written < rawBuffer.count {
                let result = Darwin.write(descriptor, baseAddress.advanced(by: written), rawBuffer.count - written)
                if result < 0 {
                    if errno == EINTR {
                        continue
                    }
                    throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
                }
                if result == 0 {
                    throw POSIXError(.EIO)
                }
                written += result
            }
        }
    }

    fileprivate func waitForEntry(message: String, source: CDKLogSource, timeout: TimeInterval = 1.0) throws
        -> CDKLogEntry
    {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let entry = CDKConsoleDock.entries().first(where: { $0.message == message && $0.source == source }) {
                return entry
            }
            usleep(10_000)
        }
        XCTFail("Timed out waiting for ConsoleDock entry: \(message)")
        throw POSIXError(.ETIMEDOUT)
    }

    fileprivate func waitForEntryIfPresent(message: String, source: CDKLogSource, timeout: TimeInterval = 0.1) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if CDKConsoleDock.entries().contains(where: { $0.message == message && $0.source == source }) {
                return true
            }
            usleep(10_000)
        }
        return false
    }

    fileprivate func waitForDescriptor(_ descriptor: Int32, toContain expected: String, timeout: TimeInterval = 1.0)
        throws -> Bool
    {
        let deadline = Date().addingTimeInterval(timeout)
        var collected = Data()

        while Date() < deadline {
            var readSet = fd_set()
            fdZero(&readSet)
            fdSet(descriptor, set: &readSet)
            var interval = timeval(tv_sec: 0, tv_usec: 10_000)
            let result = select(descriptor + 1, &readSet, nil, nil, &interval)
            if result < 0 {
                if errno == EINTR {
                    continue
                }
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            if result == 0 {
                continue
            }

            var buffer = [UInt8](repeating: 0, count: 256)
            let bytesRead = Darwin.read(descriptor, &buffer, buffer.count)
            if bytesRead > 0 {
                collected.append(buffer, count: bytesRead)
                if String(data: collected, encoding: .utf8)?.contains(expected) == true {
                    return true
                }
            }
        }

        return false
    }

    fileprivate func fdZero(_ set: inout fd_set) {
        set = fd_set()
    }

    fileprivate func fdSet(_ descriptor: Int32, set: inout fd_set) {
        let bitsPerMask = 32
        let intOffset = Int(descriptor) / bitsPerMask
        let bitOffset = Int(descriptor) % bitsPerMask
        let mask = Int32(1 << bitOffset)
        switch intOffset {
        case 0:
            set.fds_bits.0 |= mask
        case 1:
            set.fds_bits.1 |= mask
        case 2:
            set.fds_bits.2 |= mask
        case 3:
            set.fds_bits.3 |= mask
        case 4:
            set.fds_bits.4 |= mask
        case 5:
            set.fds_bits.5 |= mask
        case 6:
            set.fds_bits.6 |= mask
        case 7:
            set.fds_bits.7 |= mask
        case 8:
            set.fds_bits.8 |= mask
        case 9:
            set.fds_bits.9 |= mask
        case 10:
            set.fds_bits.10 |= mask
        case 11:
            set.fds_bits.11 |= mask
        case 12:
            set.fds_bits.12 |= mask
        case 13:
            set.fds_bits.13 |= mask
        case 14:
            set.fds_bits.14 |= mask
        case 15:
            set.fds_bits.15 |= mask
        case 16:
            set.fds_bits.16 |= mask
        case 17:
            set.fds_bits.17 |= mask
        case 18:
            set.fds_bits.18 |= mask
        case 19:
            set.fds_bits.19 |= mask
        case 20:
            set.fds_bits.20 |= mask
        case 21:
            set.fds_bits.21 |= mask
        case 22:
            set.fds_bits.22 |= mask
        case 23:
            set.fds_bits.23 |= mask
        case 24:
            set.fds_bits.24 |= mask
        case 25:
            set.fds_bits.25 |= mask
        case 26:
            set.fds_bits.26 |= mask
        case 27:
            set.fds_bits.27 |= mask
        case 28:
            set.fds_bits.28 |= mask
        case 29:
            set.fds_bits.29 |= mask
        case 30:
            set.fds_bits.30 |= mask
        case 31:
            set.fds_bits.31 |= mask
        default:
            XCTFail("Descriptor is outside fd_set test helper range")
        }
    }
}
