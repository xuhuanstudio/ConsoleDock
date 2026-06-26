# App Context

Show app-provided local context in the bundled console and issue reports.

## Overview

App Context is a small, app-owned key-value snapshot for local testing. Use it for values that help interpret logs, such as environment, feature flags, test account type, current route name, or a redacted user identifier.

ConsoleDock reads the provider on demand, displays the result in the bundled `Context` tab, and includes the same snapshot when building an issue report. The tab also prepends ConsoleDock Health for local integration diagnosis. Context is not persisted, uploaded, or refreshed in the background by ConsoleDock.

Do not put raw secrets, access tokens, or unnecessary personal data in App Context values. ConsoleDock treats context as app-authored diagnostic text and includes it in user-initiated issue report exports.

## Register A Provider

```swift
ConsoleDock.setAppContextProvider {
    [
        ConsoleDock.AppContextSection(
            title: "App",
            items: [
                .init(key: "Environment", value: "staging"),
                .init(key: "Feature Flags", value: "checkout-v2"),
                .init(key: "User ID", value: "<redacted>")
            ]
        )
    ]
}
```

The provider can be set before or after ``ConsoleDock/start(configuration:)``. Replacing the provider changes the next snapshot. Clearing the provider removes App Context from the bundled context panel and from future issue reports.

```swift
ConsoleDock.clearAppContextProvider()
```

## Objective-C

```objc
[CDKConsoleDockUIKit setAppContextProvider:^NSArray<CDKAppContextSection *> *{
    CDKAppContextItem *environment =
        [CDKAppContextItem itemWithKey:@"Environment" value:@"staging"];
    CDKAppContextSection *app =
        [CDKAppContextSection sectionWithTitle:@"App" items:@[environment]];
    return @[app];
}];
```

Use `[CDKConsoleDockUIKit clearAppContextProvider]` when the app should stop providing context.

## Boundaries

App Context is not an automatic route scanner, persistent state store, remote upload channel, or privacy filter. ConsoleDock Health is local setup guidance only and does not read Swift `Logger`, `os_log`, Apple unified logging, or other-process logs. The host app decides what App Context values are safe and useful to expose.
