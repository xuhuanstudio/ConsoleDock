import XCTest

final class ConsoleDockSwiftSampleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testConsoleDockPanelSmokeFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--consoledock-ui-smoke")
        app.launch()

        XCTAssertTrue(app.staticTexts["ConsoleDock Swift Sample"].waitForExistence(timeout: 5))

        let nativeInfoButton = app.buttons["swift-sample.consoledock-info"]
        XCTAssertTrue(nativeInfoButton.waitForExistence(timeout: 5))
        nativeInfoButton.tap()

        let showConsoleButton = app.buttons["swift-sample.show-console"]
        XCTAssertTrue(showConsoleButton.waitForExistence(timeout: 5))
        showConsoleButton.tap()

        let statusLabel = app.descendants(matching: .any)["consoledock.status"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("Running: on"))

        let entriesTable = app.tables["consoledock.entries-table"]
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "token=<redacted>", in: entriesTable, timeout: 5))
        XCTAssertFalse(tableEntry(containing: "sample-secret", existsIn: entriesTable))
        let redactedEntry = tableStaticText(containing: "token=<redacted>", in: entriesTable)
        redactedEntry.tap()
        XCTAssertTrue(redactedEntry.exists)

        let pauseButton = app.buttons["consoledock.pause-live"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))
        pauseButton.tap()

        let resumeButton = app.buttons["consoledock.resume-live"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 5))
        resumeButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))

        let clearButton = app.buttons["consoledock.clear"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        XCTAssertTrue(waitForNoTableEntries(in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForLabel(containing: "Entries: 0 visible 0", in: statusLabel, timeout: 5))

        let closeButton = app.buttons["consoledock.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertFalse(statusLabel.waitForExistence(timeout: 2))
    }

    private func waitForTableEntry(in table: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if table.descendants(matching: .cell).count > 0 {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func waitForNoTableEntries(in table: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if table.descendants(matching: .cell).count == 0 {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func waitForTableEntry(containing text: String, in table: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if tableEntry(containing: text, existsIn: table) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func tableEntry(containing text: String, existsIn table: XCUIElement) -> Bool {
        tableStaticText(containing: text, in: table).exists
    }

    private func tableStaticText(containing text: String, in table: XCUIElement) -> XCUIElement {
        table
            .descendants(matching: .staticText)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    private func waitForLabel(containing text: String, in element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.label.contains(text) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }
}
