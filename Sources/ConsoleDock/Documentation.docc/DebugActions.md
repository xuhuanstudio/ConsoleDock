# Debug Actions

Register local test shortcuts that appear in the bundled ConsoleDock panel.

## Overview

Debug Actions let the host app expose explicit actions for test and debugging builds. ConsoleDock stores the registered actions in memory, shows them in the Actions tab, skips disabled actions, asks for confirmation when requested, and writes action start, completion, skip, or failure entries back into the log store.

ConsoleDock does not discover screens, take over routing, bypass business permissions, receive remote commands, or act as an automation test framework. The host app decides what each action does.

## Register An Action

```swift
ConsoleDock.registerAction(
    id: "open.checkout",
    title: "Open Checkout",
    group: "Navigation",
    detail: "Jump to checkout test entry",
    isEnabled: true,
    style: .normal
) {
    AppRouter.shared.openCheckout()
}
```

Use non-empty stable `id` and `title` values. ConsoleDock trims required action metadata and uses the normalized `id` when replacing a repeated startup registration.

## Disable Or Style An Action

Use `isEnabled: false` when an action is relevant to the app but temporarily unavailable. Disabled actions remain visible in the panel and are skipped by the registry if triggered programmatically.

Use ``ConsoleDock/DebugActionStyle/destructive`` for actions that clear local debug state or otherwise deserve stronger UI treatment. Style is metadata; it does not force confirmation by itself.

## Require Confirmation

Use confirmation for destructive or state-changing actions.

```swift
ConsoleDock.registerAction(
    id: "debug.clear-session",
    title: "Clear Debug Session",
    group: "Maintenance",
    detail: "Clears local test state.",
    requiresConfirmation: true,
    style: .destructive
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

Use the extended Objective-C registration method when the action needs explicit enabled state or destructive styling:

```objc
[CDKConsoleDockUIKit registerActionWithIdentifier:@"debug.clear-session"
                                            title:@"Clear Debug Session"
                                            group:@"Maintenance"
                                           detail:@"Clears local test state."
                             requiresConfirmation:YES
                                        isEnabled:YES
                                            style:CDKDebugActionStyleDestructive
                                          handler:^{
    [DebugSession clear];
}];
```

Objective-C handlers do not report thrown errors to ConsoleDock. If an Objective-C action can fail, log that failure from the app-specific handler.
