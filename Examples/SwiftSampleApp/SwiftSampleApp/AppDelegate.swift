import ConsoleDock
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let isUISmokeRun = ProcessInfo.processInfo.arguments.contains("--consoledock-ui-smoke")
        ConsoleDock.start(configuration: isUISmokeRun ? .uiSmoke : .sample)
        registerDebugActions()
        ConsoleDock.info("SwiftSampleApp launched")
        if !isUISmokeRun {
            print("ConsoleDock sample launch print token=launch-secret")
            fflush(stdout)
        }

        if #available(iOS 13.0, *) {
            return true
        }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: MainViewController())
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    @available(iOS 13.0, *)
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ConsoleDock.stop()
    }

    private func registerDebugActions() {
        ConsoleDock.registerAction(
            id: "swift.sample.smoke-logs",
            title: "Generate Smoke Logs",
            group: "Samples",
            detail: "Writes info, error, and fault entries from a ConsoleDock action."
        ) {
            ConsoleDock.info("debug action smoke info token=swift-action-secret")
            ConsoleDock.error("debug action smoke error")
            ConsoleDock.fault("debug action smoke fault")
        }

        ConsoleDock.registerAction(
            id: "swift.sample.marker",
            title: "Add Marker",
            group: "Samples",
            detail: "Writes a sample timeline marker."
        ) {
            ConsoleDock.mark("debug action sample marker")
        }

        ConsoleDock.registerAction(
            id: "swift.sample.show-console",
            title: "Show Console",
            group: "Navigation",
            detail: "Opens the ConsoleDock panel."
        ) {
            ConsoleDock.showConsole()
        }

        ConsoleDock.registerAction(
            id: "swift.sample.hide-floating-button",
            title: "Hide Floating Button",
            group: "Navigation",
            detail: "Hides the bundled ConsoleDock trigger without stopping logging."
        ) {
            ConsoleDock.hideFloatingButton()
        }

        ConsoleDock.registerAction(
            id: "swift.sample.show-floating-button",
            title: "Show Floating Button",
            group: "Navigation",
            detail: "Shows the bundled ConsoleDock trigger again."
        ) {
            ConsoleDock.showFloatingButton()
        }

        ConsoleDock.registerAction(
            id: "swift.sample.clear",
            title: "Clear Entries",
            group: "Maintenance",
            detail: "Clears the in-memory ConsoleDock log entries.",
            requiresConfirmation: true,
            style: .destructive
        ) {
            ConsoleDock.clear()
        }

        ConsoleDock.registerAction(
            id: "swift.sample.disabled",
            title: "Disabled Placeholder",
            group: "Maintenance",
            detail: "Shows how unavailable debug actions appear in the panel.",
            isEnabled: false
        ) {
            ConsoleDock.info("disabled sample action should not run")
        }

        ConsoleDock.registerAction(
            id: "swift.sample.simulate-error",
            title: "Simulate Error",
            group: "Scenario",
            detail: "Writes a sample error entry for UI testing."
        ) {
            ConsoleDock.error("debug action simulated error")
        }

        ConsoleDock.registerAction(
            id: "swift.sample.log-diagnostics",
            title: "Log Diagnostics",
            group: "Diagnostics",
            detail: "Writes current ConsoleDock diagnostics."
        ) {
            let diagnostics = ConsoleDock.diagnostics
            ConsoleDock.info(
                "debug action diagnostics running=\(diagnostics.isRunning) entries=\(diagnostics.entryCount)"
            )
        }
    }
}

extension ConsoleDock.Configuration {
    static let sample = ConsoleDock.Configuration(
        maximumEntries: 500,
        maximumMessageLength: 4_096,
        captureStandardOutput: true,
        captureStandardError: true,
        showsFloatingButton: true,
        floatingButtonPosition: .bottomLeading,
        allowsReleaseBuilds: false
    )

    static let uiSmoke = ConsoleDock.Configuration(
        maximumEntries: 100,
        maximumMessageLength: 4_096,
        captureStandardOutput: false,
        captureStandardError: false,
        showsFloatingButton: true,
        floatingButtonPosition: .bottomLeading,
        allowsReleaseBuilds: false
    )
}
