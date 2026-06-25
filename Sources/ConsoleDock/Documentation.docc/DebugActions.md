# Debug Actions

Register local test shortcuts that appear in the bundled ConsoleDock panel.

## Overview

Debug Actions let the host app expose explicit actions for test and debugging builds. ConsoleDock stores the registered actions in memory, shows them in the Actions tab, asks for confirmation when requested, and writes action start, completion, or failure entries back into the log store.

ConsoleDock does not discover screens, take over routing, bypass business permissions, receive remote commands, or act as an automation test framework. The host app decides what each action does.

## Register An Action

```swift
ConsoleDock.registerAction(
    id: "open.checkout",
    title: "Open Checkout",
    group: "Navigation",
    detail: "Jump to checkout test entry"
) {
    AppRouter.shared.openCheckout()
}
```

Use non-empty stable `id` and `title` values. ConsoleDock trims required action metadata and uses the normalized `id` when replacing a repeated startup registration.

## Require Confirmation

Use confirmation for destructive or state-changing actions.

```swift
ConsoleDock.registerAction(
    id: "debug.clear-session",
    title: "Clear Debug Session",
    group: "Maintenance",
    detail: "Clears local test state.",
    requiresConfirmation: true
) {
    DebugSession.shared.clear()
}
```

The handler runs on the main thread so it can interact with UIKit and the app's normal navigation layer.

## Objective-C

```objc
[CDKConsoleDockUIKit registerActionWithIdentifier:@"open.checkout"
                                            title:@"Open Checkout"
                                            group:@"Navigation"
                                           detail:@"Jump to checkout test entry"
                             requiresConfirmation:NO
                                          handler:^{
    [AppRouter openCheckout];
}];
```

Objective-C handlers do not report thrown errors to ConsoleDock. If an Objective-C action can fail, log that failure from the app-specific handler.
