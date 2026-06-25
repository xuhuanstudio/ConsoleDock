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

/// Objective-C-callable facade for using ConsoleDock with the bundled UIKit console.
@objc(CDKConsoleDockUIKit)
public final class ConsoleDockUIKit: NSObject {
    /// Starts ConsoleDock and installs the floating UIKit button when configured.
    @discardableResult
    @objc(startWithConfiguration:error:)
    public static func start(configuration: CDKConfiguration?, error: NSErrorPointer) -> CDKStartResult {
        let result = CDKConsoleDock.start(with: configuration, error: error)
        if shouldInstallUI(configuration: configuration, result: result) {
            installUIIfAvailable()
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

    /// Builds a local issue report with session metadata, diagnostics, markers, and all retained entries.
    @objc(issueReportText)
    public static func issueReportText() -> String {
        ConsoleDock.issueReportText()
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

    private static func shouldInstallUI(configuration: CDKConfiguration?, result: CDKStartResult) -> Bool {
        let showsFloatingButton = configuration?.showsFloatingButton ?? CDKConfiguration().showsFloatingButton
        return showsFloatingButton && (result == .started || result == .alreadyRunning)
    }

    private static func installUIIfAvailable() {
        #if canImport(UIKit)
            ConsoleDockUIController.shared.install()
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
}
