# Roadmap

This roadmap is intentionally conservative. ConsoleDock should ship small, verified releases rather than over-promising Xcode-level logging behavior.

## v0.1 - MVP Capture and Console

Goal: prove the basic product value.

Deliverables:

- Swift Package Manager package.
- `ConsoleDockCore` Objective-C/C-compatible core.
- `ConsoleDock` Swift facade.
- stdout/stderr capture with pass-through.
- in-memory ring buffer.
- default redaction.
- UIKit floating dock and log panel.
- Swift and Objective-C setup examples.
- unit tests for storage, line framing, and redaction.
- integration tests for stdout/stderr capture.
- Release default no-op behavior.

Not included:

- CocoaPods.
- XCFramework.
- remote upload.
- network inspector.
- crash reporting.
- full `Logger` / `os_log` ingestion.

## v0.2 - Developer Experience

Goal: make the SDK comfortable for real project trials.

Many developer-experience items may land before the first public tag when they reduce release risk.

Deliverables:

- Swift sample app.
- Objective-C sample app.
- README quick start with screenshots.
- DocC for public Swift APIs.
- better search and filtering in UI.
- share/export redacted log snapshot.
- integration diagnostics for runtime state, capture configuration, store counts, and snapshot context.
- GitHub Actions build and test workflow.
- `LICENSE`, `CONTRIBUTING`, `SECURITY`, `CHANGELOG`, and issue templates.

Not included:

- binary XCFramework release automation.
- large third-party adapter suite.
- network request inspection.

## v0.3 - Compatibility and Adapters

Goal: improve adoption in existing apps.

Deliverables:

- CocoaLumberjack adapter.
- XCGLogger or SwiftyBeaver adapter, selected by real adoption demand.
- CocoaPods compatibility bridge if the SPM package has stabilized and a podspec validation path is available.
- packaged adapter examples based on the existing logger migration guide.
- improved Objective-C documentation.
- optional disk export file generation, still local-only and user-initiated.

Not included:

- default persistent logging.
- automatic network upload.
- system log reading.

## v1.0 - Stable Public SDK

Goal: provide a stable, documented debug SDK for broad open-source use.

Deliverables:

- stable public API.
- semantic versioning policy enforced through changelog.
- SPM tagged release.
- CI coverage for package, sample apps, and focused UI smoke tests.
- complete privacy/redaction documentation.
- release-build safety tests.
- optional binary XCFramework build pipeline.
- maintained migration guide from `print`, `NSLog`, and common logger frameworks.

Not included:

- promises of complete Swift `Logger` / `os_log` zero-intrusion capture.
- private API usage.
- reading logs from other processes.
- debugger features such as breakpoints or LLDB expression evaluation.

## Post-1.0 Ideas

Future features should be driven by real user demand:

- network request panel;
- crash breadcrumbs;
- richer adapter ecosystem;
- remote issue attachment workflow;
- advanced log sharing formats;
- SwiftUI-specific presentation helpers.

Each post-1.0 feature should preserve the default local-only, debug-first safety model.
