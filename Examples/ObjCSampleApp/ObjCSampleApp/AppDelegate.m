#import "AppDelegate.h"

#import "MainViewController.h"

@import ConsoleDock;
@import ConsoleDockCore;

@interface AppDelegate ()

- (void)startConsoleDockForUISmokeRun:(BOOL)isUISmokeRun;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL isUISmokeRun = [NSProcessInfo.processInfo.arguments containsObject:@"--consoledock-ui-smoke"];
    [self startConsoleDockForUISmokeRun:isUISmokeRun];
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

@end
