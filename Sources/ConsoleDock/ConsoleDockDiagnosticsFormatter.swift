import Foundation

struct ConsoleDockDiagnosticsFormatter {
    static func statusText(
        diagnostics: ConsoleDock.Diagnostics,
        visibleEntryCount: Int,
        isPaused: Bool
    ) -> String {
        [
            "Running: \(stateLabel(diagnostics.isRunning))  Entries: \(diagnostics.entryCount) visible \(visibleEntryCount)  stdout: \(captureLabel(diagnostics.capturesStandardOutput))  stderr: \(captureLabel(diagnostics.capturesStandardError))",
            "Limits: entries=\(diagnostics.maximumEntries) messageLength=\(diagnostics.maximumMessageLength)  redacted=\(diagnostics.redactedEntryCount) truncated=\(diagnostics.truncatedEntryCount) partial=\(diagnostics.partialEntryCount)  live: \(isPaused ? "paused" : "following")"
        ].joined(separator: "\n")
    }

    static func snapshotLines(diagnostics: ConsoleDock.Diagnostics) -> [String] {
        [
            "Diagnostics:",
            "  Running: \(diagnostics.isRunning)",
            "  stdout: \(diagnostics.capturesStandardOutput ? "enabled" : "disabled")",
            "  stderr: \(diagnostics.capturesStandardError ? "enabled" : "disabled")",
            "  Floating Button: \(diagnostics.showsFloatingButton ? "enabled" : "disabled")",
            "  Release Builds: \(diagnostics.allowsReleaseBuilds ? "allowed by runtime config" : "disabled by runtime config")",
            "  Limits: entries=\(diagnostics.maximumEntries) messageLength=\(diagnostics.maximumMessageLength)",
            "  Redacted: \(diagnostics.redactedEntryCount)",
            "  Truncated: \(diagnostics.truncatedEntryCount)",
            "  Partial: \(diagnostics.partialEntryCount)"
        ]
    }

    private static func stateLabel(_ value: Bool) -> String {
        value ? "on" : "off"
    }

    private static func captureLabel(_ value: Bool) -> String {
        value ? "on" : "off"
    }
}
