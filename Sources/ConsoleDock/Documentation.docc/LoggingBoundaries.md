# Logging Boundaries

Understand what ConsoleDock can capture and what it intentionally does not promise.

## Supported Paths

ConsoleDock can store entries from:

- explicit native calls such as ``ConsoleDock/info(_:)`` and ``ConsoleDock/error(_:)``;
- Swift `print` output that reaches the app process stdout;
- C `printf` and `fprintf(stderr)` output after standard stream buffering flushes;
- direct app-process writes to stdout and stderr;
- many `NSLog` messages when the runtime writes them through process stderr.

stdout and stderr capture passes bytes through to the original descriptors where possible, frames bytes into lines, redacts them, truncates them, and stores them in local memory.

## Not A Unified Logging Reader

ConsoleDock does not promise complete, reliable, live, zero-intrusion capture of:

- Swift `Logger`;
- `os_log`;
- Apple unified logging entries;
- logs from other apps or system processes;
- debugger-only output, breakpoints, LLDB expressions, or sanitizer diagnostics.

Those systems are not equivalent to ordinary stdout/stderr writes, and iOS apps have system restrictions around reading unified logging data.
ConsoleDock does not read Apple unified logging back from inside the app.

## Use Native Logging For Reliability

For logs that must appear in the in-app panel, call the explicit API or add an adapter in your existing logging stack.

```swift
ConsoleDock.debug("Cache hit")
ConsoleDock.info("Checkout started")
ConsoleDock.log(level: .warning, message: "Retrying checkout")
ConsoleDock.error("Payment failed")
```

For an existing logger, add a sink, appender, or transport that forwards the already-formatted message to ConsoleDock. This preserves most old call sites while avoiding unsupported system-log capture assumptions.

See <doc:ExistingLoggerMigration> for Swift and Objective-C migration patterns.
