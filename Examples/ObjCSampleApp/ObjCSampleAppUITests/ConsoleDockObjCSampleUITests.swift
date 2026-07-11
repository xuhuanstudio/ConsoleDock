import XCTest

final class ConsoleDockObjCSampleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testConsoleDockPanelSmokeFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--consoledock-ui-smoke")
        app.launch()

        XCTAssertTrue(app.staticTexts["ConsoleDock Objective-C Sample"].waitForExistence(timeout: 5))

        let nativeInfoButton = app.buttons["objc-sample.cdkconsoledock-info"]
        XCTAssertTrue(nativeInfoButton.waitForExistence(timeout: 5))
        nativeInfoButton.tap()
        let nativeErrorButton = app.buttons["objc-sample.cdkconsoledock-error"]
        XCTAssertTrue(nativeErrorButton.waitForExistence(timeout: 5))
        nativeErrorButton.tap()
        let nativeFaultButton = app.buttons["objc-sample.cdkconsoledock-fault"]
        XCTAssertTrue(nativeFaultButton.waitForExistence(timeout: 5))
        nativeFaultButton.tap()

        let showConsoleButton = app.buttons["objc-sample.show-console"]
        XCTAssertTrue(showConsoleButton.waitForExistence(timeout: 5))
        showConsoleButton.tap()

        let statusLabel = app.descendants(matching: .any)["consoledock.status"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("Running: on"))

        let entriesTable = app.tables["consoledock.entries-table"]
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "token=<redacted>", in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc native info", in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc native error", in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc native fault", in: entriesTable, timeout: 5))
        XCTAssertFalse(tableEntry(containing: "objc-secret", existsIn: entriesTable))
        let logsSearch = app.searchFields.firstMatch
        XCTAssertTrue(logsSearch.waitForExistence(timeout: 5))
        XCTAssertTrue(typeText("level:error", into: logsSearch, in: app))
        XCTAssertTrue(waitForVisibleEntryCount(1, in: statusLabel, timeout: 10))
        XCTAssertTrue(waitForTableEntry(containing: "objc native error", in: entriesTable, timeout: 5))
        XCTAssertFalse(tableEntry(containing: "objc native fault", existsIn: entriesTable))
        clearSearchField(logsSearch, in: app)
        XCTAssertTrue(waitForVisibleEntryCount(4, in: statusLabel, timeout: 10))

        let levelFilter = app.segmentedControls["consoledock.level-filter"]
        XCTAssertTrue(levelFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(selectLevel("Error", in: levelFilter, statusLabel: statusLabel, visibleCount: 1, timeout: 20))
        XCTAssertTrue(waitForTableEntry(containing: "objc native error", in: entriesTable, timeout: 5))
        XCTAssertTrue(selectLevel("Fault", in: levelFilter, statusLabel: statusLabel, visibleCount: 1, timeout: 20))
        XCTAssertTrue(waitForTableEntry(containing: "objc native fault", in: entriesTable, timeout: 5))
        XCTAssertTrue(selectLevel("All", in: levelFilter, statusLabel: statusLabel, visibleCount: 4, timeout: 20))
        XCTAssertTrue(waitForTableEntry(containing: "objc native info", in: entriesTable, timeout: 5))

        let jumpButton = app.buttons["consoledock.jump"]
        XCTAssertTrue(jumpButton.waitForExistence(timeout: 5))
        jumpButton.tap()
        XCTAssertTrue(app.buttons["consoledock.jump-latest-log"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.jump-first-error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.jump-previous-error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.jump-next-error"].waitForExistence(timeout: 5))
        app.buttons["consoledock.jump-first-error"].firstMatch.tap()
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))
        jumpButton.tap()
        XCTAssertTrue(app.buttons["consoledock.jump-next-error"].waitForExistence(timeout: 5))
        app.buttons["consoledock.jump-next-error"].firstMatch.tap()
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))
        jumpButton.tap()
        XCTAssertTrue(app.buttons["consoledock.jump-latest-log"].waitForExistence(timeout: 5))
        app.buttons["consoledock.jump-latest-log"].firstMatch.tap()
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))

        let redactedEntry = tableStaticText(containing: "token=<redacted>", in: entriesTable)
        redactedEntry.tap()
        XCTAssertTrue(app.textViews["consoledock.entry-detail.message"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.copy-message"].waitForExistence(timeout: 5))
        app.buttons["consoledock.copy-message"].tap()
        XCTAssertTrue(app.buttons["consoledock.copy-entry"].waitForExistence(timeout: 5))
        tapBackButton(in: app)
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))

        let markButton = app.buttons["consoledock.mark"]
        XCTAssertTrue(markButton.waitForExistence(timeout: 5))
        markButton.tap()
        let markerAlert = app.alerts.firstMatch
        XCTAssertTrue(markerAlert.waitForExistence(timeout: 5))
        let markerTextField = markerAlert.textFields["consoledock.marker-text"]
        XCTAssertTrue(markerTextField.waitForExistence(timeout: 5))
        XCTAssertTrue(typeText("ObjC UI smoke marker", into: markerTextField, in: app))
        markerAlert.buttons["consoledock.add-marker"].firstMatch.tap()
        XCTAssertTrue(waitForElementToDisappear(markerAlert, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "[marker] ObjC UI smoke marker", in: entriesTable, timeout: 10))

        tapMode("Timeline", in: app)
        let timelineTable = app.tables["consoledock.timeline-table"]
        XCTAssertTrue(timelineTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "ObjC UI smoke marker", in: timelineTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc native error", in: timelineTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc native fault", in: timelineTable, timeout: 5))
        tableStaticText(containing: "ObjC UI smoke marker", in: timelineTable).tap()
        XCTAssertTrue(app.textViews["consoledock.entry-detail.message"].waitForExistence(timeout: 5))
        tapBackButton(in: app)
        XCTAssertTrue(timelineTable.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.timeline-refresh"].waitForExistence(timeout: 5))
        tapMode("Logs", in: app)
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))

        let pauseButton = app.buttons["consoledock.pause-live"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 15))
        pauseButton.tap()

        let resumeButton = app.buttons["consoledock.resume-live"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 5))
        resumeButton.tap()
        XCTAssertTrue(waitForLabel(containing: "live: following", in: statusLabel, timeout: 10))
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 10))

        let clearButton = app.buttons["consoledock.clear"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        XCTAssertTrue(waitForNoTableEntries(in: entriesTable, timeout: 5))
        XCTAssertTrue(waitForLabel(containing: "Entries: 0 visible 0", in: statusLabel, timeout: 5))

        tapMode("Actions", in: app)

        let actionsTable = app.tables["consoledock.actions-table"]
        XCTAssertTrue(actionsTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Generate Smoke Logs", in: actionsTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Disabled Placeholder", in: actionsTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Disabled", in: actionsTable, timeout: 5))
        let actionsSearch = app.searchFields["consoledock.actions-search"]
        XCTAssertTrue(actionsSearch.waitForExistence(timeout: 5))
        XCTAssertTrue(typeText("Smoke", into: actionsSearch, in: app))
        XCTAssertTrue(waitForTableEntry(containing: "Generate Smoke Logs", in: actionsTable, timeout: 5))
        XCTAssertFalse(tableEntry(containing: "Clear Entries", existsIn: actionsTable))
        tableStaticText(containing: "Generate Smoke Logs", in: actionsTable).tap()

        tapMode("Logs", in: app)
        XCTAssertTrue(waitForTableEntry(containing: "objc debug action smoke error", in: entriesTable, timeout: 5))
        tapMode("Timeline", in: app)
        XCTAssertTrue(timelineTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Generate Smoke Logs", in: timelineTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "objc debug action smoke error", in: timelineTable, timeout: 5))
        tableStaticText(containing: "Generate Smoke Logs", in: timelineTable).tap()
        XCTAssertTrue(app.textViews["consoledock.timeline-action-detail.text"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.timeline-action-detail.copy"].waitForExistence(timeout: 5))
        app.buttons["consoledock.timeline-action-detail.copy"].tap()
        tapBackButton(in: app)
        XCTAssertTrue(timelineTable.waitForExistence(timeout: 5))

        tapMode("Actions", in: app)
        XCTAssertTrue(waitForTableEntry(containing: "Open Order", in: actionsTable, timeout: 5))
        tableStaticText(containing: "Open Order", in: actionsTable).tap()
        let orderIDField = app.textFields["consoledock.action-parameters.string.orderId"]
        XCTAssertTrue(orderIDField.waitForExistence(timeout: 5))
        XCTAssertTrue(typeText("O-100", into: orderIDField, in: app))
        XCTAssertTrue(app.textFields["consoledock.action-parameters.number.quantity"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["consoledock.action-parameters.bool.animated"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.segmentedControls["consoledock.action-parameters.choice.environment"].waitForExistence(timeout: 5)
        )
        let parameterForm = app.otherElements["consoledock.action-parameters.form"]
        app.buttons["consoledock.action-parameters.run"].tap()
        XCTAssertTrue(waitForElementToDisappear(parameterForm, timeout: 10))
        tapMode("Logs", in: app)
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForTableEntry(
                containing: "objc parameterized order action orderId=O-100", in: entriesTable, timeout: 15)
        )

        tapMode("Actions", in: app)
        XCTAssertTrue(waitForTableEntry(containing: "Open Order", in: actionsTable, timeout: 5))
        tableStaticText(containing: "Open Order", in: actionsTable).tap()
        XCTAssertTrue(orderIDField.waitForExistence(timeout: 5))
        XCTAssertEqual(orderIDField.value as? String, "O-100")
        app.buttons["consoledock.action-parameters.cancel"].tap()

        XCTAssertTrue(waitForTableEntry(containing: "Clear Entries", in: actionsTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Destructive", in: actionsTable, timeout: 5))
        tableStaticText(containing: "Clear Entries", in: actionsTable).tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.alerts.firstMatch.buttons["consoledock.cancel-action"].firstMatch.tap()
        XCTAssertTrue(waitForElementToDisappear(app.alerts.firstMatch, timeout: 2))
        tableStaticText(containing: "Clear Entries", in: actionsTable).tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.alerts.firstMatch.buttons["consoledock.confirm-action"].firstMatch.tap()
        tapMode("Logs", in: app)
        XCTAssertTrue(
            waitForTableEntry(containing: "Debug action completed: Clear Entries", in: entriesTable, timeout: 5))

        tapMode("Context", in: app)
        let contextTable = app.tables["consoledock.context-table"]
        XCTAssertTrue(contextTable.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "ConsoleDock Health", in: contextTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Entry Sources", in: contextTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "Objective-C", in: contextTable, timeout: 5))
        XCTAssertTrue(waitForTableEntry(containing: "ui-smoke", in: contextTable, timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.context.copy-diagnosis"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.context-refresh"].waitForExistence(timeout: 5))
        app.buttons["consoledock.context-refresh"].tap()
        tapMode("Logs", in: app)

        let closeButton = app.buttons["consoledock.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(waitForElementToDisappear(statusLabel, timeout: 2))

        XCTAssertTrue(showConsoleButton.waitForExistence(timeout: 5))
        showConsoleButton.tap()
        let shareButton = app.buttons["consoledock.share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        shareButton.tap()
        XCTAssertTrue(app.buttons["consoledock.share-issue-report"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.copy-issue-report"].waitForExistence(timeout: 5))
        let createSupportReportButton = app.buttons["consoledock.create-support-report"]
        XCTAssertTrue(createSupportReportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.save-session-archive"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.saved-session-archives"].waitForExistence(timeout: 5))
        createSupportReportButton.firstMatch.tap()

        let supportReportPreview = app.textViews["consoledock.support-report.preview"]
        XCTAssertTrue(supportReportPreview.waitForExistence(timeout: 5))
        let supportReportRange = app.segmentedControls["consoledock.support-report.range"]
        XCTAssertTrue(supportReportRange.waitForExistence(timeout: 5))
        supportReportRange.buttons["60m"].tap()
        let supportReportSummary = app.staticTexts["consoledock.support-report.summary"]
        XCTAssertTrue(supportReportSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(containing: "last 60 minutes", in: supportReportSummary, timeout: 5))
        XCTAssertTrue(app.switches["consoledock.support-report.app-context"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["consoledock.support-report.health"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consoledock.support-report.copy"].waitForExistence(timeout: 5))
        app.buttons["consoledock.support-report.copy"].tap()
        tapBackButton(in: app)
        XCTAssertTrue(entriesTable.waitForExistence(timeout: 5))
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

    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if !element.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return !element.exists
    }

    private func tapMode(_ title: String, in app: XCUIApplication, timeout: TimeInterval = 30) {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            dismissTransientInput(in: app)

            let modeButton = app.segmentedControls["consoledock.mode-control"].buttons[title]
            if modeButton.exists, modeButton.isHittable {
                modeButton.tap()
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                return
            }

            let fallbackButton = app.buttons[title].firstMatch
            if fallbackButton.exists, fallbackButton.isHittable {
                fallbackButton.tap()
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        XCTFail("Mode button '\(title)' did not become hittable")
    }

    private func dismissTransientInput(in app: XCUIApplication) {
        let keyboardSearchButton = app.keyboards.buttons["Search"].firstMatch
        if keyboardSearchButton.exists, keyboardSearchButton.isHittable {
            keyboardSearchButton.tap()
        }

        let keyboardDoneButton = app.keyboards.buttons["Done"].firstMatch
        if keyboardDoneButton.exists, keyboardDoneButton.isHittable {
            keyboardDoneButton.tap()
        }

        let cancelButton = app.buttons["Cancel"].firstMatch
        if cancelButton.exists, cancelButton.isHittable {
            cancelButton.tap()
        }
    }

    private func typeText(
        _ text: String,
        into textInput: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) -> Bool {
        guard waitForHittable(textInput, timeout: timeout) else {
            return false
        }

        textInput.tap()
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 2) {
            textInput.tap()
            _ = keyboard.waitForExistence(timeout: 1)
        }
        textInput.typeText(text)
        return true
    }

    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.isHittable {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return element.exists && element.isHittable
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

    private func selectLevel(
        _ title: String,
        in levelFilter: XCUIElement,
        statusLabel: XCUIElement,
        visibleCount: Int,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let button = levelFilter.buttons[title]
            if button.exists {
                button.tap()
            }
            let remaining = max(0.2, min(5, deadline.timeIntervalSinceNow))
            if waitForVisibleEntryCount(visibleCount, in: statusLabel, timeout: remaining) {
                return true
            }
        } while Date() < deadline
        return false
    }

    private func waitForVisibleEntryCount(_ count: Int, in statusLabel: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let pattern = "\\bvisible\\s+\(count)\\b"
        repeat {
            if statusLabel.label.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func clearSearchField(_ searchField: XCUIElement, in app: XCUIApplication) {
        if waitForHittable(searchField, timeout: 5) {
            searchField.tap()
        }
        if let value = searchField.value as? String, !value.isEmpty {
            searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        let searchButton = app.keyboards.buttons["Search"].firstMatch
        if searchButton.waitForExistence(timeout: 1) {
            searchButton.tap()
        } else {
            searchField.typeText("\n")
        }
        let cancelButton = app.buttons["Cancel"].firstMatch
        if cancelButton.waitForExistence(timeout: 1), cancelButton.isHittable {
            cancelButton.tap()
        }
        let closeSearchButton = app.buttons["close"].firstMatch
        if closeSearchButton.waitForExistence(timeout: 1) {
            closeSearchButton.tap()
        }
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

    private func tapBackButton(in app: XCUIApplication) {
        if app.navigationBars.buttons["ConsoleDock"].exists {
            app.navigationBars.buttons["ConsoleDock"].tap()
        } else {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}
