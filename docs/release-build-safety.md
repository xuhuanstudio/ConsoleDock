# Release Build Safety

ConsoleDock is a debug and test SDK. It must not appear in production builds by accident.

## Default Behavior

Release builds return `disabled` from `start` by default.

This is enforced in `ConsoleDockCore`, so it applies to both Swift and Objective-C callers:

```swift
let result = ConsoleDock.start()
// Release default: .disabled
```

```objc
CDKStartResult result = [CDKConsoleDock startWithConfiguration:nil];
// Release default: CDKStartResultDisabled
```

Debug builds are enabled by default for local development and test devices.

## Explicit Release Opt-In

Starting ConsoleDock in a Release build requires both conditions:

- compile ConsoleDock with `CONSOLEDOCK_ENABLE_RELEASE`;
- set `allowsReleaseBuilds` to `true` in configuration.

One condition alone is not enough. A Release build without the compile-time flag is disabled even if configuration allows Release builds. A Release build with the compile-time flag is still disabled unless configuration also allows Release builds.

Swift:

```swift
ConsoleDock.start(
    configuration: .init(
        allowsReleaseBuilds: true
    )
)
```

Objective-C:

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.allowsReleaseBuilds = YES;
[CDKConsoleDock startWithConfiguration:configuration];
```

Only use this for controlled internal Release-style test builds. Do not enable ConsoleDock in App Store production builds.

## CI Coverage

CI runs focused Release safety tests in two modes:

```sh
swift test -c release --filter ConsoleDockCoreTests/testReleaseBuild
swift test -c release -Xcc -DCONSOLEDOCK_ENABLE_RELEASE -Xswiftc -DCONSOLEDOCK_ENABLE_RELEASE --filter ConsoleDockCoreTests/testReleaseBuild
```

The first command proves Release defaults to disabled. The second proves the compile-time flag still requires runtime configuration before startup succeeds.
