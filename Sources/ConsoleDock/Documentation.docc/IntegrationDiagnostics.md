# Integration Diagnostics

Use diagnostics to verify ConsoleDock's local runtime state during app integration.

## Swift

```swift
let diagnostics = ConsoleDock.diagnostics

print("running: \(diagnostics.isRunning)")
print("stdout: \(diagnostics.capturesStandardOutput)")
print("stderr: \(diagnostics.capturesStandardError)")
print("stored entries: \(diagnostics.entryCount)")
print("redacted entries: \(diagnostics.redactedEntryCount)")
```

## Objective-C

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];

NSLog(@"running: %@", diagnostics.isRunning ? @"YES" : @"NO");
NSLog(@"stdout: %@", diagnostics.captureStandardOutput ? @"YES" : @"NO");
NSLog(@"stderr: %@", diagnostics.captureStandardError ? @"YES" : @"NO");
NSLog(@"stored entries: %lu", (unsigned long)diagnostics.entryCount);
```

The bundled UIKit console also shows a compact diagnostics header and includes diagnostics in share/export text snapshots.

## Boundary

Diagnostics describe ConsoleDock's active configuration and current bounded in-memory store. Counts reflect currently retained entries, not all historical logs emitted during the process lifetime.

Diagnostics do not prove complete zero-intrusion capture of Swift `Logger`, `os_log`, Apple unified logging, other-process logs, sanitizer diagnostics, LLDB expressions, or Xcode-only output. Reliable in-app visibility for those paths still requires explicit forwarding through ConsoleDock APIs or adapters.
