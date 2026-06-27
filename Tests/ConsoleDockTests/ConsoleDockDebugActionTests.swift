import ConsoleDockCore
import XCTest

@testable import ConsoleDock

final class ConsoleDockDebugActionTests: ConsoleDockTestCase {
    func testDebugActionRegistrationStoresMetadata() {
        ConsoleDock.registerAction(
            id: "open.checkout",
            title: "Open Checkout",
            group: "Navigation",
            detail: "Jump to checkout test entry",
            requiresConfirmation: true
        ) {}

        XCTAssertEqual(
            ConsoleDock.debugActions,
            [
                ConsoleDockDebugAction(
                    id: "open.checkout",
                    title: "Open Checkout",
                    group: "Navigation",
                    detail: "Jump to checkout test entry",
                    requiresConfirmation: true
                )
            ]
        )
    }

    func testParameterizedDebugActionRegistrationStoresNormalizedParameters() {
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [
                .string(id: " orderId\n", title: " Order\nID ", detail: " Required\nidentifier ", isRequired: true),
                .string(id: "orderId", title: "Duplicate"),
                .choice(
                    id: " environment ",
                    title: " Environment ",
                    choices: [
                        .init(id: " staging ", title: " Staging "),
                        .init(id: "staging", title: "Duplicate"),
                        .init(id: "\n", title: "Missing ID"),
                        .init(id: "qa", title: "QA")
                    ],
                    defaultChoiceID: " qa "
                ),
                .choice(id: "empty.choice", title: "Empty Choice", choices: [])
            ]
        ) { _ in }

        let parameters = ConsoleDock.debugActions.first?.parameters

        XCTAssertEqual(parameters?.map(\.id), ["orderId", "environment"])
        XCTAssertEqual(parameters?.map(\.title), ["Order ID", "Environment"])
        XCTAssertEqual(parameters?.first?.detail, "Required\nidentifier")
        XCTAssertEqual(parameters?.first?.isRequired, true)
        XCTAssertEqual(parameters?.last?.defaultValue, .choice("qa"))
        XCTAssertEqual(
            parameters?.last?.kind,
            .choice([
                .init(id: "staging", title: "Staging"),
                .init(id: "qa", title: "QA")
            ])
        )
    }

    func testParameterizedDebugActionReceivesNormalizedValues() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Parameterized action executed")

        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .number(id: "count", title: "Count", defaultValue: 2),
                .bool(id: "animated", title: "Animated", defaultValue: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [
                        .init(id: "staging", title: "Staging"),
                        .init(id: "qa", title: "QA")
                    ],
                    defaultChoiceID: "staging"
                )
            ]
        ) { parameters in
            XCTAssertEqual(parameters.string("orderId"), "A123")
            XCTAssertEqual(parameters.number("count"), 4)
            XCTAssertEqual(parameters.bool("animated"), true)
            XCTAssertEqual(parameters.choice("environment"), "qa")
            expectation.fulfill()
        }

        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: [
                "orderId": .string(" A123\n"),
                "count": .number(4),
                "environment": .choice(" qa ")
            ]
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(ConsoleDock.entries.map(\.message).contains("Debug action completed: Open Order [open.order]"))
    }

    func testParameterizedDebugActionRecordsExecutionHistoryWithParameterSummary() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            group: "Navigation",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .number(id: "count", title: "Count", defaultValue: 2),
                .bool(id: "animated", title: "Animated", defaultValue: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [.init(id: "qa", title: "QA")],
                    defaultChoiceID: "qa"
                )
            ]
        ) { _ in }

        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: [
                "orderId": .string(" A123\n"),
                "count": .number(4)
            ]
        )

        let execution = ConsoleDock.actionExecutionHistory.first
        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)
        XCTAssertEqual(execution?.id, 1)
        XCTAssertEqual(execution?.actionID, "open.order")
        XCTAssertEqual(execution?.title, "Open Order")
        XCTAssertEqual(execution?.group, "Navigation")
        XCTAssertEqual(execution?.outcome, .completed)
        XCTAssertEqual(execution?.parameterSummary, "orderId=\"A123\", count=4, animated=true, environment=qa")
        XCTAssertNil(execution?.message)
    }

    func testParameterizedDebugActionRedactsSensitiveParameterSummaryValues() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.registerAction(
            id: "auth.fixture",
            title: "Auth Fixture",
            parameters: [
                .string(id: "accessToken", title: "Access Token", isRequired: true),
                .string(id: "orderId", title: "Order ID", isRequired: true)
            ]
        ) { _ in }

        ConsoleDock.performDebugAction(
            id: "auth.fixture",
            parameterValues: [
                "accessToken": .string("secret-token-value"),
                "orderId": .string("A123")
            ]
        )

        let execution = ConsoleDock.actionExecutionHistory.first
        XCTAssertEqual(execution?.parameterSummary, "accessToken=<redacted>, orderId=\"A123\"")
        XCTAssertFalse(execution?.parameterSummary?.contains("secret-token-value") == true)
    }

    func testDebugActionExecutionHistoryKeepsNewestBoundedEntries() {
        ConsoleDock.registerAction(id: "bounded", title: "Bounded") {}

        for _ in 0..<505 {
            ConsoleDock.performDebugAction(id: "bounded")
        }

        let history = ConsoleDock.actionExecutionHistory
        XCTAssertEqual(history.count, 500)
        XCTAssertEqual(history.first?.id, 6)
        XCTAssertEqual(history.last?.id, 505)
    }

    func testDebugActionRecordsFailedAndSkippedExecutions() {
        struct FixtureError: Error {}
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        ConsoleDock.registerAction(id: "throwing", title: "Throwing") {
            throw FixtureError()
        }
        ConsoleDock.registerAction(id: "disabled", title: "Disabled", isEnabled: false) {}
        ConsoleDock.registerAction(
            id: "required",
            title: "Required",
            parameters: [.string(id: "orderId", title: "Order ID", isRequired: true)]
        ) { _ in }

        ConsoleDock.performDebugAction(id: "throwing")
        ConsoleDock.performDebugAction(id: "disabled")
        ConsoleDock.performDebugAction(id: "required")

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.map(\.actionID), ["throwing", "disabled", "required"])
        XCTAssertEqual(ConsoleDock.actionExecutionHistory.map(\.outcome), [.failed, .skipped, .skipped])
        XCTAssertTrue(ConsoleDock.actionExecutionHistory[0].message?.contains("error=") == true)
        XCTAssertEqual(ConsoleDock.actionExecutionHistory[1].message, "disabled")
        XCTAssertEqual(ConsoleDock.actionExecutionHistory[2].message, "missing required parameters: orderId")
    }

    func testActionExecutionHistoryIsClearableWithoutRemovingRecentParameters() {
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [.string(id: "orderId", title: "Order ID", isRequired: true)]
        ) { _ in }

        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )
        ConsoleDock.performDebugAction(
            id: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)
        let recentValues = ConsoleDock.recentDebugActionParameterValues(actionID: "open.order")
        XCTAssertEqual(recentValues["orderId"], .string("A-100"))

        ConsoleDock.clearActionExecutionHistory()

        XCTAssertTrue(ConsoleDock.actionExecutionHistory.isEmpty)
        let retainedRecentValues = ConsoleDock.recentDebugActionParameterValues(actionID: "open.order")
        XCTAssertEqual(retainedRecentValues["orderId"], .string("A-100"))
    }

    func testObjectiveCUIKitFacadeClearsActionExecutionHistory() {
        ConsoleDock.registerAction(id: "smoke", title: "Smoke") {}
        ConsoleDock.performDebugAction(id: "smoke")

        XCTAssertEqual(ConsoleDock.actionExecutionHistory.count, 1)

        ConsoleDockUIKit.clearActionExecutionHistory()

        XCTAssertTrue(ConsoleDock.actionExecutionHistory.isEmpty)
        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["smoke"])
    }

    func testDebugActionUnregisterClearsRecentParameterValuesForAction() {
        ConsoleDock.registerAction(
            id: "open.order",
            title: "Open Order",
            parameters: [.string(id: "orderId", title: "Order ID", isRequired: true)]
        ) { _ in }
        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )

        ConsoleDock.unregisterAction(id: "open.order")

        XCTAssertTrue(ConsoleDock.recentDebugActionParameterValues(actionID: "open.order").isEmpty)
    }

    func testActionRecentParametersAreSessionLocal() {
        ConsoleDock.storeRecentDebugActionParameterValues(
            actionID: "open.order",
            parameterValues: ["orderId": .string("A-100")]
        )

        ConsoleDockDebugActionRegistry.shared.resetSessionState()

        XCTAssertTrue(ConsoleDock.recentDebugActionParameterValues(actionID: "open.order").isEmpty)
    }

    func testObjectiveCUIKitFacadeParameterizedActionReceivesObjectiveCValues() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Objective-C parameterized action executed")

        let environmentChoices = [
            ConsoleDockDebugActionChoice.choice(identifier: "staging", title: "Staging"),
            ConsoleDockDebugActionChoice.choice(identifier: "qa", title: "QA")
        ]
        let parameters = [
            ConsoleDockDebugActionParameter.stringParameter(
                identifier: "orderId",
                title: "Order ID",
                detail: nil,
                isRequired: true,
                defaultValue: nil
            ),
            ConsoleDockDebugActionParameter.numberParameter(
                identifier: "count",
                title: "Count",
                detail: nil,
                isRequired: false,
                defaultValue: NSNumber(value: 2)
            ),
            ConsoleDockDebugActionParameter.boolParameter(
                identifier: "animated",
                title: "Animated",
                detail: nil,
                isRequired: false,
                defaultValue: NSNumber(value: true)
            ),
            ConsoleDockDebugActionParameter.choiceParameter(
                identifier: "environment",
                title: "Environment",
                detail: nil,
                isRequired: false,
                choices: environmentChoices,
                defaultChoiceIdentifier: "staging"
            )
        ]

        ConsoleDockUIKit.registerAction(
            identifier: "objc.open.order",
            title: "ObjC Open Order",
            group: "Navigation",
            detail: "Open an order from an Objective-C app",
            requiresConfirmation: false,
            parameters: parameters
        ) { values in
            XCTAssertEqual(values["orderId"] as? String, "A123")
            XCTAssertEqual((values["count"] as? NSNumber)?.doubleValue, 4)
            XCTAssertEqual((values["animated"] as? NSNumber)?.boolValue, true)
            XCTAssertEqual(values["environment"] as? String, "qa")
            expectation.fulfill()
        }

        ConsoleDock.performDebugAction(
            id: "objc.open.order",
            parameterValues: [
                "orderId": .string(" A123 "),
                "count": .number(4),
                "environment": .choice("qa")
            ]
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(
            ConsoleDock.entries.map(\.message)
                .contains("Debug action completed: ObjC Open Order [objc.open.order]")
        )
    }

    func testObjectiveCUIKitFacadeParameterizedActionStoresMetadataAndHonorsDisabledState() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        let parameters = [
            ConsoleDockDebugActionParameter.boolParameter(
                identifier: "enabled",
                title: "Enabled",
                detail: "Optional flag",
                isRequired: false,
                defaultValue: NSNumber(value: true)
            )
        ]

        ConsoleDockUIKit.registerAction(
            identifier: " objc.disabled ",
            title: " ObjC Disabled ",
            group: " Tools ",
            detail: " Cannot run ",
            requiresConfirmation: true,
            isEnabled: false,
            style: .destructive,
            parameters: parameters
        ) { _ in
            didRun = true
        }

        let action = ConsoleDock.debugActions.first
        XCTAssertEqual(action?.id, "objc.disabled")
        XCTAssertEqual(action?.title, "ObjC Disabled")
        XCTAssertEqual(action?.group, "Tools")
        XCTAssertEqual(action?.detail, "Cannot run")
        XCTAssertEqual(action?.requiresConfirmation, true)
        XCTAssertEqual(action?.isEnabled, false)
        XCTAssertEqual(action?.style, .destructive)
        XCTAssertEqual(action?.parameters.first?.id, "enabled")
        XCTAssertEqual(action?.parameters.first?.defaultValue, .bool(true))

        ConsoleDock.performDebugAction(id: "objc.disabled")

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: ObjC Disabled [objc.disabled] disabled"]
        )
    }

    func testParameterizedDebugActionUsesDefaultsForProgrammaticExecution() {
        var received: ConsoleDock.DebugActionParameters?
        ConsoleDock.registerAction(
            id: "defaults",
            title: "Defaults",
            parameters: [
                .number(id: "count", title: "Count", defaultValue: 3),
                .bool(id: "animated", title: "Animated", defaultValue: false),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [
                        .init(id: "staging", title: "Staging")
                    ],
                    defaultChoiceID: "staging"
                )
            ]
        ) { parameters in
            received = parameters
        }

        ConsoleDock.performDebugAction(id: "defaults")

        XCTAssertEqual(received?.number("count"), 3)
        XCTAssertEqual(received?.bool("animated"), false)
        XCTAssertEqual(received?.choice("environment"), "staging")
    }

    func testParameterizedDebugActionSkipsMissingRequiredParameters() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        ConsoleDock.registerAction(
            id: "required",
            title: "Required",
            parameters: [
                .string(id: "orderId", title: "Order ID", isRequired: true),
                .choice(
                    id: "environment",
                    title: "Environment",
                    choices: [.init(id: "staging", title: "Staging")],
                    isRequired: true
                )
            ]
        ) { _ in
            didRun = true
        }

        ConsoleDock.performDebugAction(
            id: "required",
            parameterValues: ["environment": .choice("production")]
        )

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: Required [required] missing required parameters: orderId, environment"]
        )
    }

    func testDebugActionRegistrationNormalizesRequiredMetadataAndIgnoresEmptyValues() {
        ConsoleDock.registerAction(id: "   ", title: "Missing ID") {}
        ConsoleDock.registerAction(id: "missing.title", title: " \n ") {}

        var didRun = false
        ConsoleDock.registerAction(
            id: " open.checkout\n",
            title: " Open\nCheckout ",
            group: " Navigation\nTests ",
            detail: " Jump to checkout test entry\n ",
            requiresConfirmation: false
        ) {
            didRun = true
        }

        XCTAssertEqual(
            ConsoleDock.debugActions,
            [
                ConsoleDockDebugAction(
                    id: "open.checkout",
                    title: "Open Checkout",
                    group: "Navigation Tests",
                    detail: "Jump to checkout test entry",
                    requiresConfirmation: false
                )
            ]
        )

        ConsoleDock.performDebugAction(id: " open.checkout ")
        XCTAssertTrue(didRun)

        ConsoleDock.unregisterAction(id: " open.checkout ")
        XCTAssertTrue(ConsoleDock.debugActions.isEmpty)
    }

    func testDebugActionDuplicateIdentifierReplacesInOriginalPosition() {
        ConsoleDock.registerAction(id: "first", title: "First", group: "A") {}
        ConsoleDock.registerAction(id: "second", title: "Second", group: "A") {}
        ConsoleDock.registerAction(id: "first", title: "First Replacement", group: "B", detail: "updated") {}

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["first", "second"])
        XCTAssertEqual(ConsoleDock.debugActions.map(\.title), ["First Replacement", "Second"])
        XCTAssertEqual(ConsoleDock.debugActions[0].group, "B")
        XCTAssertEqual(ConsoleDock.debugActions[0].detail, "updated")
    }

    func testDebugActionUnregisterAndRemoveAllActions() {
        ConsoleDock.registerAction(id: "first", title: "First") {}
        ConsoleDock.registerAction(id: "second", title: "Second") {}

        ConsoleDock.unregisterAction(id: "first")

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["second"])

        ConsoleDock.removeAllActions()

        XCTAssertTrue(ConsoleDock.debugActions.isEmpty)
    }

    func testDebugActionFilterMatchesIDTitleGroupAndDetail() {
        let actions = [
            ConsoleDockDebugAction(
                id: "open.checkout",
                title: "Open Checkout",
                group: "Navigation",
                detail: "Jump to payment"
            ),
            ConsoleDockDebugAction(
                id: "seed.user",
                title: "Seed User",
                group: "Data",
                detail: "Create local account"
            ),
            ConsoleDockDebugAction(
                id: "diagnostics",
                title: "Log Diagnostics",
                group: nil,
                detail: nil
            )
        ]

        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "checkout").map(\.id),
            ["open.checkout"]
        )
        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "seed.user").map(\.id),
            ["seed.user"]
        )
        XCTAssertEqual(ConsoleDockDebugActionFilter.filteredActions(actions, query: "data").map(\.id), ["seed.user"])
        XCTAssertEqual(
            ConsoleDockDebugActionFilter.filteredActions(actions, query: "PAYMENT").map(\.id),
            ["open.checkout"]
        )
        XCTAssertEqual(ConsoleDockDebugActionFilter.filteredActions(actions, query: " ").map(\.id), actions.map(\.id))
    }

    func testDebugActionPerformsOnMainThreadAndLogsStartAndCompletion() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        let expectation = expectation(description: "Debug action executed")

        ConsoleDock.registerAction(id: "smoke", title: "Smoke Action") {
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        DispatchQueue.global().async {
            ConsoleDock.performDebugAction(id: "smoke")
        }

        wait(for: [expectation], timeout: 1.0)

        let messages = ConsoleDock.entries.map(\.message)
        XCTAssertTrue(messages.contains("Debug action started: Smoke Action [smoke]"))
        XCTAssertTrue(messages.contains("Debug action completed: Smoke Action [smoke]"))
    }

    func testDebugActionThrowingHandlerLogsFailure() {
        struct FixtureError: Error {}
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)

        ConsoleDock.registerAction(id: "throwing", title: "Throwing Action") {
            throw FixtureError()
        }

        ConsoleDock.performDebugAction(id: "throwing")

        let entries = ConsoleDock.entries
        XCTAssertEqual(entries.map(\.level), [.info, .error])
        XCTAssertEqual(entries.first?.message, "Debug action started: Throwing Action [throwing]")
        XCTAssertTrue(entries.last?.message.contains("Debug action failed: Throwing Action [throwing]") == true)
    }

    func testDebugActionConfirmationFlagDoesNotPreventRegistryExecution() {
        var didRun = false
        ConsoleDock.registerAction(
            id: "danger",
            title: "Danger",
            requiresConfirmation: true
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.requiresConfirmation, true)
        ConsoleDock.performDebugAction(id: "danger")

        XCTAssertTrue(didRun)
    }

    func testDisabledDebugActionDoesNotRunAndLogsSkipped() {
        XCTAssertEqual(ConsoleDock.start(configuration: .nativeOnly), .started)
        var didRun = false
        ConsoleDock.registerAction(
            id: "disabled",
            title: "Disabled Action",
            isEnabled: false
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.isEnabled, false)
        ConsoleDock.performDebugAction(id: "disabled")

        XCTAssertFalse(didRun)
        XCTAssertEqual(
            ConsoleDock.entries.map(\.message),
            ["Debug action skipped: Disabled Action [disabled] disabled"]
        )
    }

    func testDestructiveDebugActionStyleIsMetadataOnlyForRegistryExecution() {
        var didRun = false
        ConsoleDock.registerAction(
            id: "clear",
            title: "Clear Entries",
            style: .destructive
        ) {
            didRun = true
        }

        XCTAssertEqual(ConsoleDock.debugActions.first?.style, .destructive)
        XCTAssertEqual(ConsoleDock.debugActions.first?.requiresConfirmation, false)
        ConsoleDock.performDebugAction(id: "clear")

        XCTAssertTrue(didRun)
    }

    func testDebugActionHandlerDoesNotRunWhileRegistryLockIsHeld() {
        ConsoleDock.registerAction(id: "outer", title: "Outer") {
            ConsoleDock.registerAction(id: "inner", title: "Inner") {}
        }

        ConsoleDock.performDebugAction(id: "outer")

        XCTAssertEqual(ConsoleDock.debugActions.map(\.id), ["outer", "inner"])
    }

    func testDebugActionRegistryHandlesConcurrentRegistration() {
        let queue = DispatchQueue(label: "ConsoleDockTests.DebugActions", attributes: .concurrent)
        let group = DispatchGroup()

        for index in 0..<50 {
            group.enter()
            queue.async {
                ConsoleDock.registerAction(id: "action.\(index)", title: "Action \(index)") {}
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
        XCTAssertEqual(Set(ConsoleDock.debugActions.map(\.id)).count, 50)
    }
}
