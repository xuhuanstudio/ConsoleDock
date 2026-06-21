# AGENTS.md

## Collaboration Rules

- 任何时候都先理解用户描述的内容，然后再进入下一步。
- 任何时候都要先对用户描述的内容进行思考分析，要有自己的判断能力，而不是一味地执行或附和。
- 任何用户对话都需要进行优化、补充、强化，然后以处理过后的目标继续下一步，确保内容准确、清晰。
- 任何时候都要结合项目实际情况分析，在了解项目实际情况的前提下再讨论和实现。
- 不要自作聪明调整意图外的内容；如果有额外想法，先表达并确认。
- 考虑真实链路，避免现实不存在的理论链路。
- 对发现的真实问题，要举一反三分析类似情况，确认无误后再一起处理。

## Project Context

Project name: `ConsoleDock`

Positioning:

> In-app debug console for iOS testing.

ConsoleDock is an iOS debug SDK, not an Xcode plugin and not a system-level log reader. It should help testers inspect logs on device without connecting Xcode.

## Technical Boundaries

- Do not claim full zero-intrusion capture of Swift `Logger` or `os_log`.
- Zero-intrusion capture should be framed as stdout/stderr capture, covering Swift `print`, C `printf`, and many `NSLog` outputs.
- Reliable complete logging requires either ConsoleDock's own logging API or adapters for existing logging frameworks.
- Avoid using product names that imply Apple endorsement, such as `AppleConsoleKit`, `XcodeConsoleKit`, or similar.

## Implementation Preferences

- Prefer a small Objective-C/C-compatible core where it improves compatibility with older Objective-C projects.
- Provide Swift-friendly APIs on top.
- Keep debug SDK code out of release builds by default or provide explicit safeguards.
- Treat privacy and sensitive data redaction as core design concerns, not later polish.

