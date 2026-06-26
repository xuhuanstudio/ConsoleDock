# Objective-C Integration

Use `ConsoleDockCore` for Objective-C-compatible capture and storage APIs, and `ConsoleDock` for the bundled UIKit console facade.

## Import The Products

Objective-C and mixed apps can import both products:

```objc
@import ConsoleDock;
@import ConsoleDockCore;
```

Use `ConsoleDockCore` directly when the app only needs capture, storage, notifications, and explicit logging APIs. Add `ConsoleDock` when the app should show the bundled UIKit floating button and console panel.

## Start With The UIKit Facade

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.floatingButtonPosition = CDKFloatingButtonPositionBottomLeading;
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];

if (result == CDKStartResultStarted || result == CDKStartResultAlreadyRunning) {
    [CDKConsoleDock info:@"Login succeeded"];
    [CDKConsoleDock error:@"Request failed"];
    [CDKConsoleDock fault:@"Invariant failed"];
}
```

`CDKConsoleDockUIKit` installs the floating console when configured. The core `CDKConsoleDock` APIs remain available for reading, clearing, and writing native entries.

Use the UIKit facade to hide or show the bundled trigger at runtime without stopping ConsoleDock:

```objc
[CDKConsoleDockUIKit hideFloatingButton];
[CDKConsoleDockUIKit showFloatingButton];
```

## Keep Existing Logger Call Sites

For older Objective-C projects, prefer adding a sink or appender to the existing logger instead of rewriting every call site. The appender can forward formatted messages through `CDKLogForwarder` while the original logger keeps its current outputs.

```objc
static CDKLogForwarder *AppLogConsoleDockForwarder(void)
{
    static CDKLogForwarder *forwarder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        forwarder = [[CDKLogForwarder alloc] initWithCategory:@"AppLog"
                                                 minimumLevel:CDKLogLevelInfo];
    });
    return forwarder;
}

void AppLogInfo(NSString *message) {
    NSLog(@"%@", message);
    [AppLogConsoleDockForwarder() info:message];
}
```

ConsoleDock cannot fully capture Swift `Logger`, `os_log`, or Apple unified logging from inside the app, so adapters should forward to ConsoleDock explicitly when reliable in-app visibility is required.

See <doc:ExistingLoggerMigration> for a macro-based forwarding example.

## Mark A Test Session

Objective-C apps can add local reproduction markers through `CDKConsoleDock`:

```objc
[CDKConsoleDock mark:@"Opened checkout"];

CDKSessionMetadata *metadata = [CDKConsoleDock sessionMetadata];
NSLog(@"ConsoleDock session: %@", metadata.sessionIdentifier);
```

Markers are native info entries with a stable `[marker]` prefix. The bundled UIKit console can also create markers, show a local Timeline, share a local issue report, or copy the report text with session metadata, diagnostics, app context, a reproduction timeline, markers, and currently retained redacted logs.

```objc
NSString *report = [CDKConsoleDockUIKit issueReportText];
```

When expected entries or local debug surface data do not appear, copy the local Integration Diagnosis:

```objc
NSString *diagnosis = [CDKConsoleDockUIKit integrationDiagnosisText];
```

The bundled `Context` tab shows the same ConsoleDock Health state and includes a `Copy Integration Diagnosis` action.

Use Local Session Archive when an Objective-C app or tester needs to save that report locally for later review:

```objc
NSError *error = nil;
CDKSessionArchive *archive =
    [CDKConsoleDockUIKit saveSessionArchiveWithNote:@"Checkout smoke test"
                                             error:&error];
NSArray<CDKSessionArchive *> *archives =
    [CDKConsoleDockUIKit sessionArchivesWithError:&error];
```

Archives are explicit bounded issue-report snapshots. They do not turn ConsoleDock into raw-log persistence, remote upload, or crash reporting. See <doc:LocalSessionArchive>.

Use Support Reports when an Objective-C app-owned feedback flow needs a bounded local report for a recent time window:

```objc
NSError *error = nil;
CDKSupportReport *supportReport =
    [CDKConsoleDockUIKit supportReportWithLastMinutes:10
                          maximumReportCharacterCount:0];
NSURL *fileURL =
    [CDKConsoleDockUIKit makeTemporarySupportReportFileWithLastMinutes:60
                                           maximumReportCharacterCount:0
                                                                 error:&error];
```

Support Reports are generated on demand and are not analytics, background logging, or automatic upload. See <doc:SupportReports>.

## Register Parameterized Debug Actions

Objective-C apps can register actions with small local parameters through `CDKConsoleDockUIKit`.

```objc
CDKDebugActionParameter *orderID =
    [CDKDebugActionParameter stringParameterWithIdentifier:@"orderId"
                                                    title:@"Order ID"
                                                   detail:nil
                                               isRequired:YES
                                              defaultValue:nil];

[CDKConsoleDockUIKit registerActionWithIdentifier:@"open.order"
                                            title:@"Open Order"
                                            group:@"Scenario"
                                           detail:@"Open a local order test entry"
                             requiresConfirmation:NO
                                       parameters:@[orderID]
                                          handler:^(NSDictionary<NSString *, id> *values) {
    [AppRouter openOrderWithIdentifier:values[@"orderId"]];
}];
```

The bundled console displays the parameter form locally before running the action. ConsoleDock can reuse recent values within the current process session, but it does not persist parameter values across app restarts or receive remote commands.

## Provide App Context

Use App Context for local key-value diagnostics that should appear in the bundled `Context` tab and issue reports.

```objc
[CDKConsoleDockUIKit setAppContextProvider:^NSArray<CDKAppContextSection *> *{
    CDKAppContextItem *environment =
        [CDKAppContextItem itemWithKey:@"Environment" value:@"staging"];
    CDKAppContextSection *app =
        [CDKAppContextSection sectionWithTitle:@"App" items:@[environment]];
    return @[app];
}];
```

Clear the provider with `[CDKConsoleDockUIKit clearAppContextProvider]`.
