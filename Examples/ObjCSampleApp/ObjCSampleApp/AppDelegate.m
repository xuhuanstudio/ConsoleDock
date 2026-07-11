#import "AppDelegate.h"

#import "MainViewController.h"

@import ConsoleDock;
@import ConsoleDockCore;

@interface AppDelegate ()

- (void)startConsoleDockForUISmokeRun:(BOOL)isUISmokeRun;
- (void)registerDebugActions;
- (void)registerAppContextForUISmokeRun:(BOOL)isUISmokeRun;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL isUISmokeRun = [NSProcessInfo.processInfo.arguments containsObject:@"--consoledock-ui-smoke"];
    [self startConsoleDockForUISmokeRun:isUISmokeRun];
    if (isUISmokeRun) {
        NSError *archiveError = nil;
        if (![CDKConsoleDockUIKit clearSessionArchivesWithError:&archiveError]) {
            [CDKConsoleDock error:[NSString stringWithFormat:@"Failed to clear UI smoke archives: %@",
                                                            archiveError.localizedDescription ?: @"unknown error"]];
        }
    }
    [self registerDebugActions];
    [self registerAppContextForUISmokeRun:isUISmokeRun];
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
    configuration.floatingButtonPosition = CDKFloatingButtonPositionBottomLeading;
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

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.marker"
                                                title:@"Add Marker"
                                                group:@"Samples"
                                               detail:@"Writes a sample timeline marker."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDock mark:@"objc debug action sample marker"];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.show-console"
                                                title:@"Show Console"
                                                group:@"Navigation"
                                               detail:@"Opens the ConsoleDock panel."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDockUIKit showConsole];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.hide-floating-button"
                                                title:@"Hide Floating Button"
                                                group:@"Navigation"
                                               detail:@"Hides the bundled ConsoleDock trigger without stopping logging."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDockUIKit hideFloatingButton];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.show-floating-button"
                                                title:@"Show Floating Button"
                                                group:@"Navigation"
                                               detail:@"Shows the bundled ConsoleDock trigger again."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDockUIKit showFloatingButton];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.clear"
                                                title:@"Clear Entries"
                                                group:@"Maintenance"
                                               detail:@"Clears the in-memory ConsoleDock log entries."
                                 requiresConfirmation:YES
                                            isEnabled:YES
                                                style:CDKDebugActionStyleDestructive
                                              handler:^{
                                                  [CDKConsoleDock clearEntries];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.disabled"
                                                title:@"Disabled Placeholder"
                                                group:@"Maintenance"
                                               detail:@"Shows how unavailable debug actions appear in the panel."
                                 requiresConfirmation:NO
                                            isEnabled:NO
                                                style:CDKDebugActionStyleNormal
                                              handler:^{
                                                  [CDKConsoleDock info:@"disabled objc sample action should not run"];
                                              }];

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.simulate-error"
                                                title:@"Simulate Error"
                                                group:@"Scenario"
                                               detail:@"Writes a sample error entry for UI testing."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  [CDKConsoleDock error:@"objc debug action simulated error"];
                                              }];

    NSArray<CDKDebugActionChoice *> *environmentChoices = @[
        [CDKDebugActionChoice choiceWithIdentifier:@"staging" title:@"Staging"],
        [CDKDebugActionChoice choiceWithIdentifier:@"qa" title:@"QA"]
    ];
    NSArray<CDKDebugActionParameter *> *orderParameters = @[
        [CDKDebugActionParameter stringParameterWithIdentifier:@"orderId"
                                                        title:@"Order ID"
                                                       detail:@"Example: O-100"
                                                   isRequired:YES
                                                 defaultValue:nil],
        [CDKDebugActionParameter numberParameterWithIdentifier:@"quantity"
                                                        title:@"Quantity"
                                                       detail:@"Used only by this local sample action."
                                                   isRequired:NO
                                                 defaultValue:@1],
        [CDKDebugActionParameter boolParameterWithIdentifier:@"animated"
                                                      title:@"Animated"
                                                     detail:nil
                                                 isRequired:NO
                                               defaultValue:@YES],
        [CDKDebugActionParameter choiceParameterWithIdentifier:@"environment"
                                                        title:@"Environment"
                                                       detail:nil
                                                   isRequired:NO
                                                      choices:environmentChoices
                                      defaultChoiceIdentifier:@"qa"]
    ];
    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.open-order"
                                                title:@"Open Order"
                                                group:@"Scenario"
                                               detail:@"Writes a local parameterized navigation-style log entry."
                                 requiresConfirmation:NO
                                           parameters:orderParameters
                                              handler:^(NSDictionary<NSString *, id> *values) {
                                                  NSString *orderID = values[@"orderId"] ?: @"missing";
                                                  NSNumber *quantity = values[@"quantity"] ?: @0;
                                                  NSNumber *animated = values[@"animated"] ?: @NO;
                                                  NSString *environment = values[@"environment"] ?: @"none";
                                                  [CDKConsoleDock info:
                                                      [NSString stringWithFormat:@"objc parameterized order action "
                                                                                 @"orderId=%@ quantity=%@ animated=%@ "
                                                                                 @"environment=%@",
                                                                                 orderID,
                                                                                 quantity,
                                                                                 animated.boolValue ? @"YES" : @"NO",
                                                                                 environment]];
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

    [CDKConsoleDockUIKit registerActionWithIdentifier:@"objc.sample.save-archive"
                                                title:@"Save Session Archive"
                                                group:@"Diagnostics"
                                               detail:@"Saves the current local issue report as a bounded on-device archive."
                                 requiresConfirmation:NO
                                              handler:^{
                                                  NSError *error = nil;
                                                  CDKSessionArchive *archive =
                                                      [CDKConsoleDockUIKit saveSessionArchiveWithNote:@"Objective-C sample debug action"
                                                                                                 error:&error];
                                                  if (archive != nil) {
                                                      [CDKConsoleDock info:
                                                          [NSString stringWithFormat:@"objc debug action saved session archive id=%@",
                                                                                     archive.identifier]];
                                                  } else {
                                                      [CDKConsoleDock error:
                                                          [NSString stringWithFormat:@"objc debug action failed to save session archive: %@",
                                                                                     error.localizedDescription ?: @"Unknown error"]];
                                                  }
                                              }];
}

- (void)registerAppContextForUISmokeRun:(BOOL)isUISmokeRun
{
    [CDKConsoleDockUIKit setAppContextProvider:^NSArray<CDKAppContextSection *> *{
        CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
        NSString *entryCount = [NSString stringWithFormat:@"%lu", (unsigned long)diagnostics.entryCount];
        return @[
            [CDKAppContextSection sectionWithTitle:@"Sample App"
                                             items:@[
                                                 [CDKAppContextItem itemWithKey:@"Language" value:@"Objective-C"],
                                                 [CDKAppContextItem itemWithKey:@"Mode"
                                                                          value:isUISmokeRun ? @"ui-smoke" : @"interactive"],
                                                 [CDKAppContextItem itemWithKey:@"Process"
                                                                          value:NSProcessInfo.processInfo.processName]
                                             ]],
            [CDKAppContextSection sectionWithTitle:@"ConsoleDock"
                                             items:@[
                                                 [CDKAppContextItem itemWithKey:@"Running"
                                                                          value:diagnostics.isRunning ? @"YES" : @"NO"],
                                                 [CDKAppContextItem itemWithKey:@"Entries" value:entryCount]
                                             ]]
        ];
    }];
}

@end
