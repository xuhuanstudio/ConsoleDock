#import "AppDelegate.h"

#import "MainViewController.h"

@import ConsoleDock;
@import ConsoleDockCore;

@interface AppDelegate ()

- (void)startConsoleDockForUISmokeRun:(BOOL)isUISmokeRun;
- (void)registerDebugActions;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL isUISmokeRun = [NSProcessInfo.processInfo.arguments containsObject:@"--consoledock-ui-smoke"];
    [self startConsoleDockForUISmokeRun:isUISmokeRun];
    [self registerDebugActions];
    [CDKConsoleDock info:@"ObjCSampleApp launched"];
    if (!isUISmokeRun) {
        printf("ConsoleDock Objective-C sample launch printf token=objc-launch-secret\n");
        fflush(stdout);
        NSLog(@"ConsoleDock Objective-C sample launch NSLog token=objc-nslog-secret");
    }

    if (@available(iOS 13.0, *)) {
        return YES;
    }

    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[MainViewController alloc] init]];
    [window makeKeyAndVisible];
    self.window = window;

    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0))
{
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [CDKConsoleDockUIKit stop];
}

- (void)startConsoleDockForUISmokeRun:(BOOL)isUISmokeRun
{
    CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
    configuration.maximumEntries = isUISmokeRun ? 100 : 500;
    configuration.maximumMessageLength = 4096;
    configuration.captureStandardOutput = !isUISmokeRun;
    configuration.captureStandardError = !isUISmokeRun;
    configuration.showsFloatingButton = YES;
    configuration.allowsReleaseBuilds = NO;

    NSError *error = nil;
    CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:&error];
    if (result == CDKStartResultFailed) {
        NSLog(@"ConsoleDock failed to start: %@", error.localizedDescription ?: @"Unknown error");
    }
}

- (void)registerDebugActions
{
    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.smoke-logs"
                                                title:@"Generate Smoke Logs"
                                                group:@"Samples"
                                               detail:@"Writes info, error, and fault entries from a ConsoleDock action."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDock info:@"objc debug action smoke info token=objc-action-secret"];
                                                  [CDKConsoleDock error:@"objc debug action smoke error"];
                                                  [CDKConsoleDock fault:@"objc debug action smoke fault"];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.show-console"
                                                title:@"Show Console"
                                                group:@"Navigation"
                                               detail:@"Opens the ConsoleDock panel."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDockUIKit showConsole];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.clear"
                                                title:@"Clear Entries"
                                                group:@"Maintenance"
                                               detail:@"Clears the in-memory ConsoleDock log entries."
                                 requiresConfirmation:YES
                                              handler:^{
                                                  [CDKConsoleDock clearEntries];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.simulate-error"
                                                title:@"Simulate Error"
                                                group:@"Scenario"
                                               detail:@"Writes a sample error entry for UI testing."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDock error:@"objc debug action simulated error"];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.log-diagnostics"
                                                title:@"Log Diagnostics"
                                                group:@"Diagnostics"
                                               detail:@"Writes current ConsoleDock diagnostics."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
                                                  [CDKConsoleDock info:
                                                      [NSString stringWithFormat:@"objc debug action diagnostics running=%@ entries=%lu",
                                                                                 diagnostics.isRunning ? @"YES" : @"NO",
                                                                                 (unsigned long)diagnostics.entryCount]];
                                              }];
}

@end
