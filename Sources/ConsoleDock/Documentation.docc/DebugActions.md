# Debug Actions

Register local test shortcuts that appear in the bundled ConsoleDock panel.

## Overview

Debug Actions let the host app expose explicit actions for test and debugging builds. ConsoleDock stores the registered actions in memory, shows them in the Actions tab, skips disabled actions, asks for confirmation when requested, writes action start, completion, skip, or failure entries back into the log store, and records local execution history for the current process session.

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

The bundled Actions view can search by action id, title, group, or detail. Search is local UI filtering only; it does not execute actions, persist queries, or change registration.

## Register A Parameterized Action

Use parameters when a local test shortcut needs a small amount of tester input before it runs.

```swift
ConsoleDock.registerAction(
    id: "open.order",
    title: "Open Order",
    group: "Scenario",
    detail: "Open a local order test entry",
    parameters: [
        .string(id: "orderId", title: "Order ID", isRequired: true),
        .number(id: "quantity", title: "Quantity", defaultValue: 1),
        .bool(id: "animated", title: "Animated", defaultValue: true),
        .choice(
            id: "environment",
            title: "Environment",
            choices: [
                .init(id: "staging", title: "Staging"),
                .init(id: "qa", title: "QA")
            ],
            defaultChoiceID: "qa"
        )
    ]
) { values in
    AppRouter.shared.openOrder(
        id: values.string("orderId") ?? "",
        quantity: values.number("quantity") ?? 1,
        animated: values.bool("animated") ?? true,
        environment: values.choice("environment") ?? "qa"
    )
}
```

The bundled UIKit console presents parameter fields locally before running the action. The form reuses the most recent valid values for the same action within the current process session, then falls back to parameter defaults. Parameter values are not persisted across app restarts by ConsoleDock, and unregistering an action clears its session-only recent values. Keep this for bounded debug/test inputs such as identifiers, environment choices, counters, and feature toggles.

Submitted parameter values can appear in local Debug Action execution history and issue-report reproduction timelines as a compact parameter summary. ConsoleDock redacts obvious secret-like parameter names and common secret-looking values, but this is only a baseline. Do not enter secrets or unnecessary personal data.

## Read Action Execution History

Use ``ConsoleDock/actionExecutionHistory`` when a custom debug surface needs the current session's local action outcomes.

```swift
for execution in ConsoleDock.actionExecutionHistory {
    print("\(execution.title): \(execution.outcome)")
}
```

Use ``ConsoleDock/clearActionExecutionHistory()`` to clear the current in-memory execution history. This does not unregister actions or clear session-only recent parameter values used by the bundled parameter form. ConsoleDock keeps the newest bounded execution history records for the current process session.

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

Objective-C parameterized actions receive a dictionary of normalized values:

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
