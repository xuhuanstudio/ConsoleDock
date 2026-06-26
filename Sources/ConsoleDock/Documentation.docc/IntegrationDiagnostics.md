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

## Integration Diagnosis

Integration Diagnosis is available in `v0.13.0` and later. Use it when an app has integrated ConsoleDock but expected logs, actions, context, or archives do not appear:

```swift
let diagnosis = ConsoleDock.integrationDiagnosisText()
print(diagnosis)
```

```objc
NSString *diagnosis = [CDKConsoleDockUIKit integrationDiagnosisText];
NSLog(@"%@", diagnosis);
```

The diagnosis is generated locally. It summarizes running state, stdout/stderr capture configuration, retained source and level counts, redacted/truncated/partial counts, Debug Action registration and execution counts, App Context provider status, Local Session Archive count, and practical recommendations.

The bundled `Context` tab also prepends a `ConsoleDock Health` section and provides `Copy Integration Diagnosis` for testers who need to send the current setup state to a developer.

## Observe Changes

Custom debug surfaces can observe diagnostics changes instead of polling:

```swift
NotificationCenter.default.addObserver(
    forName: ConsoleDock.diagnosticsDidChangeNotification,
    object: nil,
    queue: .main
) { _ in
    let diagnostics = ConsoleDock.diagnostics
    print("running: \(diagnostics.isRunning)")
}
```

```objc
[[NSNotificationCenter defaultCenter] addObserverForName:CDKConsoleDockDiagnosticsDidChangeNotification
                                                  object:CDKConsoleDock.class
                                                   queue:NSOperationQueue.mainQueue
                                              usingBlock:^(__unused NSNotification *notification) {
    CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
    NSLog(@"running: %@", diagnostics.isRunning ? @"YES" : @"NO");
}];
```

The notification is posted after start, stop, append, and clear operations when diagnostics values may have changed.

## Boundary

Diagnostics and Integration Diagnosis describe ConsoleDock's active configuration and current bounded in-memory store. Counts reflect currently retained entries, not all historical logs emitted during the process lifetime.

Diagnostics do not prove complete zero-intrusion capture of Swift `Logger`, `os_log`, Apple unified logging, other-process logs, sanitizer diagnostics, LLDB expressions, or Xcode-only output. Reliable in-app visibility for those paths still requires explicit forwarding through ConsoleDock APIs or adapters.
