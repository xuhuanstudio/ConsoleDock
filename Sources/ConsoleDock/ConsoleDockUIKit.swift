import ConsoleDockCore
import Foundation

/// Objective-C-visible style for a local debug action.
@objc(CDKDebugActionStyle)
public enum ConsoleDockDebugActionStyle: Int {
    case normal = 0
    case destructive = 1

    var swiftStyle: ConsoleDock.DebugActionStyle {
        switch self {
        case .normal:
            return .normal
        case .destructive:
            return .destructive
        @unknown default:
            return .normal
        }
    }
}

/// Objective-C-visible app context item for local issue reports.
@objc(CDKAppContextItem)
public final class ConsoleDockAppContextItem: NSObject {
    @objc public let key: String
    @objc public let value: String

    @objc(initWithKey:value:)
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    @objc(itemWithKey:value:)
    public static func item(key: String, value: String) -> ConsoleDockAppContextItem {
        ConsoleDockAppContextItem(key: key, value: value)
    }

    var swiftItem: ConsoleDock.AppContextItem {
        ConsoleDock.AppContextItem(key: key, value: value)
    }
}

/// Objective-C-visible app context section for local issue reports.
@objc(CDKAppContextSection)
public final class ConsoleDockAppContextSection: NSObject {
    @objc public let title: String
    @objc public let items: [ConsoleDockAppContextItem]

    @objc(initWithTitle:items:)
    public init(title: String, items: [ConsoleDockAppContextItem]) {
        self.title = title
        self.items = items
    }

    @objc(sectionWithTitle:items:)
    public static func section(title: String, items: [ConsoleDockAppContextItem]) -> ConsoleDockAppContextSection {
        ConsoleDockAppContextSection(title: title, items: items)
    }

    var swiftSection: ConsoleDock.AppContextSection {
        ConsoleDock.AppContextSection(title: title, items: items.map(\.swiftItem))
    }
}

/// Objective-C-callable facade for using ConsoleDock with the bundled UIKit console.
@objc(CDKConsoleDockUIKit)
public final class ConsoleDockUIKit: NSObject {
    /// Starts ConsoleDock and installs the floating UIKit button when configured.
    @discardableResult
    @objc(startWithConfiguration:error:)
    public static func start(configuration: CDKConfiguration?, error: NSErrorPointer) -> CDKStartResult {
        let result = CDKConsoleDock.start(with: configuration, error: error)
        if shouldConfigureUI(result: result) {
            configureUIIfAvailable(configuration: configuration ?? CDKConfiguration())
        }
        return result
    }

    /// Stops ConsoleDock and tears down the bundled UIKit console.
    @objc(stop)
    public static func stop() {
        CDKConsoleDock.stop()
        teardownUIIfAvailable()
    }

    /// Whether ConsoleDock is currently running.
    @objc(isRunning)
    public static func isRunning() -> Bool {
        CDKConsoleDock.isRunning()
    }

    /// Shows the bundled UIKit console when ConsoleDock is running.
    @objc(showConsole)
    public static func showConsole() {
        guard CDKConsoleDock.isRunning() else { return }
        showConsoleIfAvailable()
    }

    /// Hides the bundled UIKit console.
    @objc(hideConsole)
    public static func hideConsole() {
        hideConsoleIfAvailable()
    }

    /// Shows the bundled UIKit floating trigger when ConsoleDock is running.
    @objc(showFloatingButton)
    public static func showFloatingButton() {
        guard CDKConsoleDock.isRunning() else { return }
        showFloatingButtonIfAvailable()
    }

    /// Hides the bundled UIKit floating trigger without stopping ConsoleDock.
    @objc(hideFloatingButton)
    public static func hideFloatingButton() {
        hideFloatingButtonIfAvailable()
    }

    /// Builds a local issue report with session metadata, diagnostics, markers, and all retained entries.
    @objc(issueReportText)
    public static func issueReportText() -> String {
        ConsoleDock.issueReportText()
    }

    /// Sets an app-owned local context provider for issue reports and the bundled context panel.
    @objc(setAppContextProvider:)
    public static func setAppContextProvider(_ provider: @escaping () -> [ConsoleDockAppContextSection]) {
        ConsoleDock.setAppContextProvider {
            provider().map(\.swiftSection)
        }
    }

    /// Clears the app-owned local context provider.
    @objc(clearAppContextProvider)
    public static func clearAppContextProvider() {
        ConsoleDock.clearAppContextProvider()
    }

    /// Registers a local debug action shown by the bundled UIKit console.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        handler: @escaping () -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: true,
            style: .normal
        ) {
            handler()
        }
    }

    /// Registers a local debug action with explicit enabled state and UI style.
    @objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:isEnabled:style:handler:)
    public static func registerAction(
        identifier: String,
        title: String,
        group: String?,
        detail: String?,
        requiresConfirmation: Bool,
        isEnabled: Bool,
        style: ConsoleDockDebugActionStyle,
        handler: @escaping () -> Void
    ) {
        ConsoleDock.registerAction(
            id: identifier,
            title: title,
            group: group,
            detail: detail,
            requiresConfirmation: requiresConfirmation,
            isEnabled: isEnabled,
            style: style.swiftStyle
        ) {
            handler()
        }
    }

    /// Removes a previously registered local debug action.
    @objc(unregisterActionWithIdentifier:)
    public static func unregisterAction(identifier: String) {
        ConsoleDock.unregisterAction(id: identifier)
    }

    /// Removes all registered local debug actions.
    @objc(removeAllActions)
    public static func removeAllActions() {
        ConsoleDock.removeAllActions()
    }

    private static func shouldConfigureUI(result: CDKStartResult) -> Bool {
        result == .started || result == .alreadyRunning
    }

    private static func configureUIIfAvailable(configuration: CDKConfiguration) {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.configure(
                floatingButtonPosition: ConsoleDock.FloatingButtonPosition(
                    corePosition: configuration.floatingButtonPosition
                ),
                showsFloatingButton: configuration.showsFloatingButton
            )
        #endif
    }

    private static func teardownUIIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.teardown()
        #endif
    }

    private static func showConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showConsole()
        #endif
    }

    private static func hideConsoleIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideConsole()
        #endif
    }

    private static func showFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.showFloatingButton()
        #endif
    }

    private static func hideFloatingButtonIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.hideFloatingButton()
        #endif
    }
}
