import ConsoleDockCore
import Foundation

@objc(CDKConsoleDockUIKit)
public final class ConsoleDockUIKit: NSObject {
    @discardableResult
    @objc(startWithConfiguration:error:)
    public static func start(configuration: CDKConfiguration?, error: NSErrorPointer) -> CDKStartResult {
        let result = CDKConsoleDock.start(with: configuration, error: error)
        if shouldInstallUI(configuration: configuration, result: result) {
            installUIIfAvailable()
        }
        return result
    }

    @objc(stop)
    public static func stop() {
        CDKConsoleDock.stop()
        teardownUIIfAvailable()
    }

    @objc(isRunning)
    public static func isRunning() -> Bool {
        CDKConsoleDock.isRunning()
    }

    @objc(showConsole)
    public static func showConsole() {
        guard CDKConsoleDock.isRunning() else { return }
        showConsoleIfAvailable()
    }

    @objc(hideConsole)
    public static func hideConsole() {
        hideConsoleIfAvailable()
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
