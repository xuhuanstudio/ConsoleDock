import ConsoleDock
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ConsoleDock.start(configuration: .sample)
        ConsoleDock.info("SwiftSampleApp launched")
        print("ConsoleDock sample launch print token=launch-secret")
        fflush(stdout)

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
}

extension ConsoleDock.Configuration {
    static let sample = ConsoleDock.Configuration(
        maximumEntries: 500,
        maximumMessageLength: 4_096,
        captureStandardOutput: true,
        captureStandardError: true,
        showsFloatingButton: true,
        allowsReleaseBuilds: false
    )
}
