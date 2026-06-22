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
