# Daily Debug Usability

Use the bundled UIKit console efficiently during repeated local test sessions.

## Overview

ConsoleDock is intentionally local and debug/test-first. Daily usability features should help testers open the panel, find important entries, and trigger app-registered shortcuts without turning ConsoleDock into a remote command system or automation platform.

## Configure The Floating Trigger

Choose a starting corner when the default bottom-trailing button would cover common test controls.

```swift
let configuration = ConsoleDock.Configuration(
    floatingButtonPosition: .bottomLeading
)

ConsoleDock.start(configuration: configuration)
```

Objective-C apps can configure the same behavior through `CDKConfiguration`.

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.floatingButtonPosition = CDKFloatingButtonPositionBottomLeading;

[CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];
```

## Hide Or Show The Floating Trigger

Hide the bundled trigger when the app provides its own debug entry point, then show it again when useful.

```swift
ConsoleDock.hideFloatingButton()
ConsoleDock.showFloatingButton()
```

```objc
[CDKConsoleDockUIKit hideFloatingButton];
[CDKConsoleDockUIKit showFloatingButton];
```

These calls do not start or stop ConsoleDock. They only affect the bundled trigger. Use ``ConsoleDock/showConsole()`` when the app wants to open the panel from its own UI.

## Jump Within Visible Logs

The Logs view includes a `Jump` menu for the current visible result set:

- latest visible log;
- first visible error or fault;
- previous visible error or fault;
- next visible error or fault.

Jump actions respect the current search, source filter, level filter, and pause/resume state. They do not change stored entries or filters.

## Search Logs With Local Query Tokens

The Logs search field supports plain text plus a small local query syntax:

- `source:native`, `source:stdout`, and `source:stderr`;
- `level:debug`, `level:info`, `level:warning`, `level:warn`, `level:error`, and `level:fault`;
- `is:partial`, `is:redacted`, and `is:truncated`;
- quoted phrases such as `"checkout failed"`;
- excluded text terms such as `-heartbeat` or `-"cache warmup"`.

Structured query tokens are combined with the source and level controls. Unknown `key:value` terms are treated as ordinary text so testers can keep searching without strict syntax errors.

This is local UI filtering only. ConsoleDock does not persist queries, does not change stored entries, and does not expose a public query-language API.

## Search Debug Actions

The Actions view can search by action id, title, group, or detail. Search is local UI filtering only. It does not execute actions, persist queries, receive remote commands, or change action registration.
