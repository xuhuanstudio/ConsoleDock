# ConsoleDock MVP Architecture

Date: 2026-06-22

## Objective

ConsoleDock is an in-app debug console for iOS testing. Its first usable release should let testers view process-local app logs on device without connecting Xcode, while keeping the product boundary accurate and safe.

The MVP should prove three things:

1. A host app can integrate ConsoleDock with a small amount of setup.
2. Existing projects can get useful baseline logs through stdout/stderr capture.
3. New or upgraded projects can get reliable logs through ConsoleDock's explicit API.

## Non-Goals

ConsoleDock is not:

- an Xcode plugin
- a system log reader
- a debugger replacement
- a complete Apple unified logging reader
- a tool for reading logs from other apps or system processes
- a remote telemetry or analytics SDK

The MVP will not promise full zero-intrusion capture of Swift `Logger` or `os_log`.

## MVP Scope

The MVP includes:

- Swift Package Manager package structure.
- Objective-C/C-compatible core target for capture, storage, redaction, and lifecycle.
- Swift facade target for ergonomic Swift API.
- UIKit-based in-app console UI.
- stdout/stderr capture with pass-through to the original file descriptors.
- explicit ConsoleDock logging API.
- in-memory ring buffer.
- default sensitive-value redaction.
- Release build fail-closed behavior.
- unit and simulator test coverage for core behavior.

The MVP excludes:

- CocoaPods podspec.
- XCFramework build pipeline.
- remote upload.
- persistent database storage.
- full third-party adapter set.
- network inspector.
- crash reporter.
- Swift `Logger` / `os_log` zero-intrusion ingestion.

## Package and Module Design

Initial SwiftPM products:

- `ConsoleDock`: primary library product for Swift and mixed projects.
- `ConsoleDockCore`: low-level Objective-C/C-compatible product for older Objective-C projects and future CocoaPods packaging.

Initial targets:

- `ConsoleDockCore`
  - Language: Objective-C with small C helpers where useful.
  - Responsibilities: file descriptor capture, reader queues, line framing, ring buffer, redaction, lifecycle state, and Objective-C API.
  - Public prefix: `CDK`.

- `ConsoleDock`
  - Language: Swift.
  - Responsibilities: Swift facade, configuration builder, Swift log API, UIKit presentation coordinator, and type-safe wrappers around core.
  - Depends on: `ConsoleDockCore`, `UIKit`.

- `ConsoleDockCoreTests`
  - Tests core algorithms that do not require UI.

- `ConsoleDockTests`
  - Tests Swift facade behavior and integration boundaries.

A future `ConsoleDockUI` target can be split out when a headless-only package variant becomes useful. It should not be split in the MVP unless the code grows enough to justify the extra package surface.

## Swift and Objective-C Boundaries

The Objective-C-compatible layer owns process-global side effects and the stable compatibility API.

Planned Objective-C API shape:

```objc
#import <ConsoleDockCore/ConsoleDockCore.h>

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.maximumEntries = 2000;

[CDKConsoleDock startWithConfiguration:configuration];
[CDKConsoleDock logWithLevel:CDKLogLevelInfo message:@"Login succeeded"];
[CDKConsoleDock stop];
```

Planned Swift API shape:

```swift
import ConsoleDock

ConsoleDock.start(
    configuration: .init(
        maximumEntries: 2_000,
        captureStandardOutput: true,
        captureStandardError: true
    )
)

ConsoleDock.info("Login succeeded")
ConsoleDock.error("Request failed", metadata: ["endpoint": "/v1/session"])
ConsoleDock.stop()
```

Swift APIs should be thin wrappers over core state, not a second implementation of capture or storage.

## Capture Pipeline

`ConsoleDock.start()` should install stdout/stderr capture only once.

Capture steps:

1. Validate that ConsoleDock is enabled for the current build policy.
2. Duplicate and store original `STDOUT_FILENO` and `STDERR_FILENO`.
3. Create separate pipes for stdout and stderr.
4. Redirect each file descriptor with `dup2`.
5. Start dedicated serial reader queues or dispatch sources for each pipe.
6. Read bytes from the pipe.
7. Immediately write the bytes back to the saved original descriptor so Xcode and external consumers still receive output.
8. Decode bytes into UTF-8 with replacement behavior for invalid sequences.
9. Split into line entries while retaining partial lines until newline, flush, stop, or size limit.
10. Normalize into `CDKLogEntry`.
11. Apply redaction before storage and UI delivery.
12. Append to the ring buffer.
13. Notify observers for UI refresh.

`ConsoleDock.stop()` must:

1. restore original file descriptors with `dup2`;
2. close pipe ends and duplicated descriptors;
3. flush partial lines with an explicit partial marker;
4. cancel reader queues or dispatch sources;
5. make repeated `stop()` calls harmless.

## Supported Logging Paths

Expected MVP behavior:

- Swift `print`: usually captured through stdout.
- C `printf`: captured through stdout after libc flush behavior allows bytes to reach the descriptor.
- `fprintf(stderr, ...)`: captured through stderr.
- direct `write(STDOUT_FILENO, ...)` and `write(STDERR_FILENO, ...)`: captured.
- `NSLog`: captured only when the runtime writes the output through process stderr.

Explicitly unsupported as zero-intrusion complete capture:

- Swift `Logger`
- `os_log`
- historical or system-wide unified logging entries

Recommended guidance for unified logging users:

```swift
ConsoleDock.info("Login succeeded")
```

The ConsoleDock API may also forward to Apple unified logging, but the in-app panel must be populated from ConsoleDock's internal store.

## Entry Model

Minimum `CDKLogEntry` fields:

- stable identifier
- timestamp
- source: stdout, stderr, native, adapter
- level: debug, info, warning, error, fault
- message
- metadata dictionary
- thread label or queue label where practical
- truncation flag
- redaction flag

The entry model should avoid retaining arbitrary objects from the host app.

## Storage

MVP storage is memory-only.

Requirements:

- ring buffer with configurable maximum entry count;
- configurable maximum message length;
- bounded total approximate byte size;
- thread-safe append and snapshot;
- observer notifications delivered on a documented queue;
- no disk persistence by default.

Storage must preserve insertion order and must not block the capture reader queues on UI work.

## UIKit UI

MVP UI should use UIKit for compatibility with older iOS apps.

Planned UI:

- floating dock button;
- drag-to-position behavior;
- console panel presented over the current foreground scene/window;
- log list using a monospaced font;
- level/source badges;
- search;
- pause/resume live follow;
- clear visible entries;
- copy selected entry;
- share/export current snapshot as plain text.

The UI should not require SwiftUI. It should handle multiple scenes by attaching to the active foreground scene when available and falling back conservatively for older apps.

## Privacy and Redaction

Redaction happens before data enters storage, UI, copy, share, or export.

Default redaction should cover common key names and header-style values:

- `Authorization`
- `Cookie`
- `Set-Cookie`
- `password`
- `passwd`
- `token`
- `access_token`
- `refresh_token`
- `secret`
- `api_key`
- `client_secret`

Defaults should prefer false negatives avoidance for obvious secrets while avoiding aggressive mutation of ordinary text.

The API must allow a custom redactor:

```swift
ConsoleDock.start(
    configuration: .init(redactor: { entry in
        entry.redacting(pattern: #"user_id=\d+"#, replacement: "user_id=<redacted>")
    })
)
```

No network upload is included in the MVP.

## Release Build Protection

ConsoleDock should fail closed outside debug builds.

Default behavior:

- Debug builds: `start()` can install capture and UI.
- Release builds: `start()` is a no-op and returns a disabled status.

Explicit release enabling must require an intentional compile-time condition or configuration such as `CONSOLEDOCK_ENABLE_RELEASE`. Documentation must warn that enabling an in-app console in production can expose sensitive data and internal implementation details.

## Error Handling and Resource Cleanup

Public start APIs should return or expose a startup status.

Important failure cases:

- already started;
- file descriptor duplication failed;
- pipe creation failed;
- redirection failed;
- build policy disabled ConsoleDock;
- UI cannot attach to a window scene.

Startup should either complete fully or roll back all partially installed capture resources.

The capture core must be idempotent:

- repeated `start()` should not stack redirects;
- repeated `stop()` should be harmless;
- app background/foreground transitions should not lose stored entries;
- process termination should not require explicit cleanup to remain safe.

## Testing Matrix

Core unit tests:

- ring buffer eviction;
- line framing for complete and partial lines;
- invalid UTF-8 replacement;
- redaction defaults;
- custom redactor order;
- metadata and level mapping;
- truncation behavior;
- start/stop state transitions without UI.

Capture integration tests:

- direct `write` to stdout;
- direct `write` to stderr;
- `printf` with `fflush`;
- `fprintf(stderr, ...)`;
- Swift `print`;
- pass-through to original descriptors;
- descriptor restoration after stop.

UI tests:

- dock button appears in debug-enabled sample app;
- panel opens and closes;
- entries append in order;
- search filters results;
- pause prevents auto-follow without dropping entries;
- clear affects the visible store according to documented behavior;
- copy/share export uses redacted text.

Build-policy tests:

- Release/default-disabled build does not install capture;
- explicit enabled build installs capture;
- disabled build does not present UI.

Tests that mutate stdout/stderr must run serially.

## MVP Acceptance Criteria

The MVP is acceptable when:

- a Swift sample app can add ConsoleDock and call `ConsoleDock.start()`;
- an Objective-C sample app can call the core API;
- Swift `print`, C `printf`, `fprintf(stderr)`, and direct writes appear in the panel;
- captured output still reaches Xcode Console;
- `stop()` restores stdout/stderr;
- Release default behavior is no-op;
- redaction applies before UI/copy/share;
- documentation clearly states the `Logger` / `os_log` boundary;
- CI can build and run the available test suite on macOS with an iOS simulator destination where needed.

