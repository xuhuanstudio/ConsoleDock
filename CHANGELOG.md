# Changelog

All notable changes to ConsoleDock will be documented in this file.

The project follows Semantic Versioning after public releases begin.

## Unreleased

- Added Swift Package skeleton.
- Added `ConsoleDockCore` Objective-C-compatible stub API.
- Added `ConsoleDock` Swift facade stub API.
- Added minimal unit tests for lifecycle and configuration behavior.
- Added open-source governance files.
- Refined Swift start failure handling to preserve core error details.
- Added core log entry model, bounded in-memory Native API storage, basic redaction, message truncation, and read/clear APIs.
- Added isolated core line framing for byte chunks, partial flushes, CRLF normalization, invalid UTF-8 replacement, and stdout/stderr line event storage normalization.
- Added core stdout/stderr file-descriptor capture lifecycle with pass-through, restore, line framing, partial flush on stop, and capture configuration support.
- Added entries-changed notification for append and clear operations as a snapshot refresh foundation.
- Added UIKit console foundation with floating button, live snapshot panel, clear, close, and lifecycle teardown.
- Added a Swift UIKit sample app that imports the local package and validates Native API, stdout, stderr, `NSLog`, redaction, clear, stop, and restart behavior on Simulator.
- Added `CDKConsoleDockUIKit` for Objective-C access to the bundled UIKit console and an Objective-C UIKit sample app that validates Native API, stdout, stderr, direct descriptor writes, `NSLog`, redaction, clear, stop, and restart behavior on Simulator.
- Expanded CI to build the package for iOS Simulator and build both Swift and Objective-C sample apps.
