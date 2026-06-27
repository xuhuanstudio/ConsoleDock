#!/usr/bin/env python3
"""Validate the Swift public API surface used by app integrations."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile


SWIFT_FACADE = pathlib.Path("Sources/ConsoleDock/ConsoleDock.swift")
UIKIT_FACADE = pathlib.Path("Sources/ConsoleDock/ConsoleDockUIKit.swift")
SWIFT_SOURCE_ROOT = pathlib.Path("Sources/ConsoleDock")

ALLOWED_PUBLIC_SWIFT_FILES = {
    SWIFT_FACADE,
    UIKIT_FACADE,
}

REQUIRED_SNIPPETS = {
    SWIFT_FACADE: [
        "public enum ConsoleDock",
        "public struct Configuration",
        "public var maximumEntries: Int",
        "public var maximumMessageLength: Int",
        "public var captureStandardOutput: Bool",
        "public var captureStandardError: Bool",
        "public var showsFloatingButton: Bool",
        "public var floatingButtonPosition: FloatingButtonPosition",
        "public var allowsReleaseBuilds: Bool",
        "public var redactor: ((String) -> String)?",
        "maximumEntries: Int = 2_000",
        "maximumMessageLength: Int = 8_192",
        "captureStandardOutput: Bool = true",
        "captureStandardError: Bool = true",
        "showsFloatingButton: Bool = true",
        "floatingButtonPosition: FloatingButtonPosition = .bottomTrailing",
        "allowsReleaseBuilds: Bool = false",
        "redactor: ((String) -> String)? = nil",
        """
        public init(
            maximumEntries: Int = 2_000,
            maximumMessageLength: Int = 8_192,
            captureStandardOutput: Bool = true,
            captureStandardError: Bool = true,
            showsFloatingButton: Bool = true,
            floatingButtonPosition: FloatingButtonPosition = .bottomTrailing,
            allowsReleaseBuilds: Bool = false,
            redactor: ((String) -> String)? = nil
        )
        """,
        "public static let `default` = Configuration()",
        "public enum LogLevel: Equatable",
        "case debug",
        "case info",
        "case warning",
        "case error",
        "case fault",
        "public enum DebugActionStyle: Equatable",
        "case normal",
        "case destructive",
        "public enum DebugActionExecutionOutcome: Equatable",
        "case completed",
        "case failed",
        "case skipped",
        "public struct DebugActionExecution: Equatable, Identifiable",
        "public let actionID: String",
        "public let group: String?",
        "public let startedAt: Date",
        "public let completedAt: Date",
        "public let outcome: DebugActionExecutionOutcome",
        "public let parameterSummary: String?",
        "public let message: String?",
        """
        public init(
            id: UInt64,
            actionID: String,
            title: String,
            group: String?,
            startedAt: Date,
            completedAt: Date,
            outcome: DebugActionExecutionOutcome,
            parameterSummary: String? = nil,
            message: String? = nil
        )
        """,
        "public struct DebugActionChoice: Equatable",
        "public let id: String",
        "public let title: String",
        "public init(id: String, title: String)",
        "public enum DebugActionParameterValue: Equatable",
        "case string(String)",
        "case number(Double)",
        "case bool(Bool)",
        "case choice(String)",
        "public struct DebugActionParameter: Equatable",
        "public enum Kind: Equatable",
        "case string",
        "case number",
        "case bool",
        "case choice([DebugActionChoice])",
        "public let detail: String?",
        "public let isRequired: Bool",
        "public let defaultValue: DebugActionParameterValue?",
        "public let kind: Kind",
        """
        public static func string(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: String? = nil
        ) -> DebugActionParameter
        """,
        """
        public static func number(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: Double? = nil
        ) -> DebugActionParameter
        """,
        """
        public static func bool(
            id: String,
            title: String,
            detail: String? = nil,
            isRequired: Bool = false,
            defaultValue: Bool? = nil
        ) -> DebugActionParameter
        """,
        """
        public static func choice(
            id: String,
            title: String,
            choices: [DebugActionChoice],
            detail: String? = nil,
            isRequired: Bool = false,
            defaultChoiceID: String? = nil
        ) -> DebugActionParameter
        """,
        "public struct DebugActionParameters: Equatable",
        "public init(_ values: [String: DebugActionParameterValue] = [:])",
        "public func value(_ id: String) -> DebugActionParameterValue?",
        "public func string(_ id: String) -> String?",
        "public func number(_ id: String) -> Double?",
        "public func bool(_ id: String) -> Bool?",
        "public func choice(_ id: String) -> String?",
        "public struct AppContextItem: Equatable",
        "public let key: String",
        "public let value: String",
        "public init(key: String, value: String)",
        "public struct AppContextSection: Equatable",
        "public let items: [AppContextItem]",
        "public init(title: String, items: [AppContextItem])",
        "public enum FloatingButtonPosition: Equatable",
        "case topLeading",
        "case topTrailing",
        "case bottomLeading",
        "case bottomTrailing",
        "public enum LogSource: Equatable",
        "case native",
        "case stdout",
        "case stderr",
        "public struct LogEntry: Equatable, Identifiable",
        "public let id: UInt64",
        "public let timestamp: Date",
        "public let level: LogLevel",
        "public let source: LogSource",
        "public let message: String",
        "public let isMarker: Bool",
        "public let partial: Bool",
        "public let redacted: Bool",
        "public let truncated: Bool",
        "id: UInt64 = 0",
        "timestamp: Date",
        "level: LogLevel",
        "source: LogSource",
        "message: String",
        "isMarker: Bool = false",
        "partial: Bool = false",
        "redacted: Bool = false",
        "truncated: Bool = false",
        """
        public init(
            id: UInt64 = 0,
            timestamp: Date,
            level: LogLevel,
            source: LogSource,
            message: String,
            isMarker: Bool = false,
            partial: Bool = false,
            redacted: Bool = false,
            truncated: Bool = false
        )
        """,
        "public struct LogForwarder",
        "public let category: String?",
        "public let minimumLevel: LogLevel",
        "public init(category: String? = nil, minimumLevel: LogLevel = .debug)",
        "public func log(level: LogLevel, message: String)",
        "public func debug(_ message: String)",
        "public func info(_ message: String)",
        "public func warning(_ message: String)",
        "public func error(_ message: String)",
        "public func fault(_ message: String)",
        "public struct Diagnostics: Equatable",
        "public let isRunning: Bool",
        "public let capturesStandardOutput: Bool",
        "public let capturesStandardError: Bool",
        "public let showsFloatingButton: Bool",
        "public let floatingButtonPosition: FloatingButtonPosition",
        "public let allowsReleaseBuilds: Bool",
        "public let maximumEntries: Int",
        "public let maximumMessageLength: Int",
        "public let entryCount: Int",
        "public let redactedEntryCount: Int",
        "public let truncatedEntryCount: Int",
        "public let partialEntryCount: Int",
        """
        public init(
            isRunning: Bool,
            capturesStandardOutput: Bool,
            capturesStandardError: Bool,
            showsFloatingButton: Bool,
            floatingButtonPosition: FloatingButtonPosition = .bottomTrailing,
            allowsReleaseBuilds: Bool,
            maximumEntries: Int,
            maximumMessageLength: Int,
            entryCount: Int,
            redactedEntryCount: Int,
            truncatedEntryCount: Int,
            partialEntryCount: Int
        )
        """,
        "public struct SessionMetadata: Equatable",
        "public let sessionIdentifier: String",
        "public let startedAt: Date?",
        "public let generatedAt: Date",
        "public let bundleIdentifier: String?",
        "public let appVersion: String?",
        "public let appBuild: String?",
        "public let processName: String",
        "public let operatingSystemVersion: String",
        "public let deviceModel: String",
        "public let localeIdentifier: String",
        "public let timeZoneIdentifier: String",
        """
        public init(
            sessionIdentifier: String,
            startedAt: Date?,
            generatedAt: Date,
            bundleIdentifier: String?,
            appVersion: String?,
            appBuild: String?,
            processName: String,
            operatingSystemVersion: String,
            deviceModel: String,
            localeIdentifier: String,
            timeZoneIdentifier: String
        )
        """,
        "public struct SessionArchive: Equatable, Identifiable",
        "public let sourceSessionIdentifier: String",
        "public let sourceSessionStartedAt: Date?",
        "public let note: String?",
        "public let entryCount: Int",
        "public let reportCharacterCount: Int",
        "public let isReportTruncated: Bool",
        "public let reportText: String",
        """
        public init(
            id: String,
            createdAt: Date,
            sourceSessionIdentifier: String,
            sourceSessionStartedAt: Date?,
            title: String,
            note: String? = nil,
            entryCount: Int,
            reportCharacterCount: Int,
            isReportTruncated: Bool,
            reportText: String
        )
        """,
        "public enum SupportReportTimeRange: Equatable",
        "case allRetained",
        "case last(minutes: Int)",
        "case range(from: Date, to: Date)",
        "public struct SupportReportOptions: Equatable",
        "public static let defaultMaximumReportCharacterCount = 256_000",
        "public var timeRange: SupportReportTimeRange",
        "public var maximumReportCharacterCount: Int",
        "public var includesAppContext: Bool",
        "public var includesIntegrationHealth: Bool",
        """
        public init(
            timeRange: SupportReportTimeRange = .last(minutes: 10),
            maximumReportCharacterCount: Int = SupportReportOptions.defaultMaximumReportCharacterCount,
            includesAppContext: Bool = true,
            includesIntegrationHealth: Bool = true
        )
        """,
        "public static let last5Minutes = SupportReportOptions(timeRange: .last(minutes: 5))",
        "public static let last10Minutes = SupportReportOptions(timeRange: .last(minutes: 10))",
        "public static let last30Minutes = SupportReportOptions(timeRange: .last(minutes: 30))",
        "public static let last60Minutes = SupportReportOptions(timeRange: .last(minutes: 60))",
        """
        public static func last(
            minutes: Int,
            maximumReportCharacterCount: Int = SupportReportOptions.defaultMaximumReportCharacterCount
        ) -> SupportReportOptions
        """,
        "public struct SupportReport: Equatable",
        "public let generatedAt: Date",
        "public let timeRangeDescription: String",
        "public let includedEntryCount: Int",
        "public let omittedEntryCount: Int",
        "public let includedActionExecutionCount: Int",
        "public let omittedActionExecutionCount: Int",
        "public let isReportTruncated: Bool",
        "public let text: String",
        """
        public init(
            generatedAt: Date,
            timeRangeDescription: String,
            includedEntryCount: Int,
            omittedEntryCount: Int,
            includedActionExecutionCount: Int,
            omittedActionExecutionCount: Int,
            reportCharacterCount: Int,
            isReportTruncated: Bool,
            text: String
        )
        """,
        "public enum StartResult: Equatable",
        "case started",
        "case alreadyRunning",
        "case disabled",
        "case failed(StartFailure)",
        "public struct StartFailure: Equatable",
        "public let domain: String",
        "public let code: Int",
        "public let message: String",
        "public init(domain: String, code: Int, message: String)",
        "public static func start(configuration: Configuration = .default) -> StartResult",
        "public static func stop()",
        "public static var isRunning: Bool",
        "public static var entries: [LogEntry]",
        "public static var diagnostics: Diagnostics",
        "public static var sessionMetadata: SessionMetadata",
        "public static var appContext: [AppContextSection]",
        "public static var actionExecutionHistory: [DebugActionExecution]",
        "public static let entriesDidChangeNotification",
        "public static let diagnosticsDidChangeNotification",
        "public static func clear()",
        "public static func issueReportText() -> String",
        "public static func supportReport(options: SupportReportOptions = .default) -> SupportReport",
        "public static func makeTemporarySupportReportFile(options: SupportReportOptions = .default) throws -> URL",
        "public static func integrationDiagnosisText() -> String",
        "public static func saveSessionArchive(note: String? = nil) throws -> SessionArchive",
        "public static func sessionArchives() throws -> [SessionArchive]",
        "public static func deleteSessionArchive(id: String) throws",
        "public static func clearSessionArchives() throws",
        "public static func setAppContextProvider(_ provider: @escaping () -> [AppContextSection])",
        "public static func clearAppContextProvider()",
        "public static func showConsole()",
        "public static func hideConsole()",
        "public static func showFloatingButton()",
        "public static func hideFloatingButton()",
        """
        public static func registerAction(
            id: String,
            title: String,
            group: String? = nil,
            detail: String? = nil,
            requiresConfirmation: Bool = false,
            isEnabled: Bool = true,
            style: DebugActionStyle = .normal,
            handler: @escaping () throws -> Void
        )
        """,
        """
        public static func registerAction(
            id: String,
            title: String,
            group: String? = nil,
            detail: String? = nil,
            requiresConfirmation: Bool = false,
            isEnabled: Bool = true,
            style: DebugActionStyle = .normal,
            parameters: [DebugActionParameter],
            handler: @escaping (DebugActionParameters) throws -> Void
        )
        """,
        "public static func unregisterAction(id: String)",
        "public static func removeAllActions()",
        "public static func clearActionExecutionHistory()",
        "public static func debug(_ message: String)",
        "public static func log(level: LogLevel, message: String)",
        "public static func mark(_ message: String)",
        "public static func info(_ message: String)",
        "public static func warning(_ message: String)",
        "public static func error(_ message: String)",
        "public static func fault(_ message: String)",
    ],
    UIKIT_FACADE: [
        "@objc(CDKDebugActionStyle)",
        "public enum ConsoleDockDebugActionStyle: Int",
        "case normal = 0",
        "case destructive = 1",
        "@objc(CDKDebugActionChoice)",
        "public final class ConsoleDockDebugActionChoice: NSObject",
        "@objc public let identifier: String",
        "@objc public let title: String",
        "@objc(initWithIdentifier:title:)",
        "public init(identifier: String, title: String)",
        "@objc(choiceWithIdentifier:title:)",
        "public static func choice(identifier: String, title: String) -> ConsoleDockDebugActionChoice",
        "@objc(CDKDebugActionParameter)",
        "public final class ConsoleDockDebugActionParameter: NSObject",
        "@objc public let detail: String?",
        "@objc public let isRequired: Bool",
        "@objc(stringParameterWithIdentifier:title:detail:isRequired:defaultValue:)",
        """
        public static func stringParameter(
            identifier: String,
            title: String,
            detail: String?,
            isRequired: Bool,
            defaultValue: String?
        ) -> ConsoleDockDebugActionParameter
        """,
        "@objc(numberParameterWithIdentifier:title:detail:isRequired:defaultValue:)",
        """
        public static func numberParameter(
            identifier: String,
            title: String,
            detail: String?,
            isRequired: Bool,
            defaultValue: NSNumber?
        ) -> ConsoleDockDebugActionParameter
        """,
        "@objc(boolParameterWithIdentifier:title:detail:isRequired:defaultValue:)",
        """
        public static func boolParameter(
            identifier: String,
            title: String,
            detail: String?,
            isRequired: Bool,
            defaultValue: NSNumber?
        ) -> ConsoleDockDebugActionParameter
        """,
        "@objc(choiceParameterWithIdentifier:title:detail:isRequired:choices:defaultChoiceIdentifier:)",
        """
        public static func choiceParameter(
            identifier: String,
            title: String,
            detail: String?,
            isRequired: Bool,
            choices: [ConsoleDockDebugActionChoice],
            defaultChoiceIdentifier: String?
        ) -> ConsoleDockDebugActionParameter
        """,
        "@objc(CDKAppContextItem)",
        "public final class ConsoleDockAppContextItem: NSObject",
        "@objc public let key: String",
        "@objc public let value: String",
        "@objc(initWithKey:value:)",
        "public init(key: String, value: String)",
        "@objc(itemWithKey:value:)",
        "public static func item(key: String, value: String) -> ConsoleDockAppContextItem",
        "@objc(CDKAppContextSection)",
        "public final class ConsoleDockAppContextSection: NSObject",
        "@objc public let items: [ConsoleDockAppContextItem]",
        "@objc(initWithTitle:items:)",
        "public init(title: String, items: [ConsoleDockAppContextItem])",
        "@objc(sectionWithTitle:items:)",
        "public static func section(title: String, items: [ConsoleDockAppContextItem]) -> ConsoleDockAppContextSection",
        "@objc(CDKSessionArchive)",
        "public final class ConsoleDockSessionArchive: NSObject",
        "@objc public let sourceSessionIdentifier: String",
        "@objc public let sourceSessionStartedAt: Date?",
        "@objc public let note: String?",
        "@objc public let entryCount: Int",
        "@objc public let reportCharacterCount: Int",
        "@objc public let isReportTruncated: Bool",
        "@objc public let reportText: String",
        """
        @objc(
            initWithIdentifier:createdAt:sourceSessionIdentifier:sourceSessionStartedAt:title:note:entryCount:
            reportCharacterCount:isReportTruncated:reportText:
        )
        """,
        """
        public init(
            identifier: String,
            createdAt: Date,
            sourceSessionIdentifier: String,
            sourceSessionStartedAt: Date?,
            title: String,
            note: String?,
            entryCount: Int,
            reportCharacterCount: Int,
            isReportTruncated: Bool,
            reportText: String
        )
        """,
        "@objc(CDKSupportReport)",
        "public final class ConsoleDockSupportReport: NSObject",
        "@objc public let generatedAt: Date",
        "@objc public let timeRangeDescription: String",
        "@objc public let includedEntryCount: Int",
        "@objc public let omittedEntryCount: Int",
        "@objc public let includedActionExecutionCount: Int",
        "@objc public let omittedActionExecutionCount: Int",
        "@objc public let isReportTruncated: Bool",
        "@objc public let text: String",
        """
        @objc(
            initWithGeneratedAt:timeRangeDescription:includedEntryCount:omittedEntryCount:
            includedActionExecutionCount:omittedActionExecutionCount:reportCharacterCount:isReportTruncated:text:
        )
        """,
        """
        public init(
            generatedAt: Date,
            timeRangeDescription: String,
            includedEntryCount: Int,
            omittedEntryCount: Int,
            includedActionExecutionCount: Int,
            omittedActionExecutionCount: Int,
            reportCharacterCount: Int,
            isReportTruncated: Bool,
            text: String
        )
        """,
        "@objc(CDKConsoleDockUIKit)",
        "public final class ConsoleDockUIKit: NSObject",
        "@objc(startWithConfiguration:error:)",
        "public static func start(configuration: CDKConfiguration?, error: NSErrorPointer) -> CDKStartResult",
        "@objc(stop)",
        "public static func stop()",
        "@objc(isRunning)",
        "public static func isRunning() -> Bool",
        "@objc(showConsole)",
        "public static func showConsole()",
        "@objc(hideConsole)",
        "public static func hideConsole()",
        "@objc(showFloatingButton)",
        "public static func showFloatingButton()",
        "@objc(hideFloatingButton)",
        "public static func hideFloatingButton()",
        "@objc(issueReportText)",
        "public static func issueReportText() -> String",
        "@objc(supportReportWithLastMinutes:maximumReportCharacterCount:)",
        """
        public static func supportReport(
            lastMinutes: Int,
            maximumReportCharacterCount: Int
        ) -> ConsoleDockSupportReport
        """,
        "@objc(supportReportFromDate:toDate:maximumReportCharacterCount:)",
        """
        public static func supportReport(
            from fromDate: Date,
            to toDate: Date,
            maximumReportCharacterCount: Int
        ) -> ConsoleDockSupportReport
        """,
        "@objc(makeTemporarySupportReportFileWithLastMinutes:maximumReportCharacterCount:error:)",
        """
        public static func makeTemporarySupportReportFile(
            lastMinutes: Int,
            maximumReportCharacterCount: Int,
            error errorPointer: NSErrorPointer
        ) -> URL?
        """,
        "@objc(makeTemporarySupportReportFileFromDate:toDate:maximumReportCharacterCount:error:)",
        """
        public static func makeTemporarySupportReportFile(
            from fromDate: Date,
            to toDate: Date,
            maximumReportCharacterCount: Int,
            error errorPointer: NSErrorPointer
        ) -> URL?
        """,
        "@objc(integrationDiagnosisText)",
        "public static func integrationDiagnosisText() -> String",
        "@objc(saveSessionArchiveWithNote:error:)",
        """
        public static func saveSessionArchive(
            note: String?,
            error errorPointer: NSErrorPointer
        ) -> ConsoleDockSessionArchive?
        """,
        "@objc(sessionArchivesWithError:)",
        "public static func sessionArchives(error errorPointer: NSErrorPointer) -> [ConsoleDockSessionArchive]?",
        "@objc(deleteSessionArchiveWithIdentifier:error:)",
        """
        public static func deleteSessionArchive(
            identifier: String,
            error errorPointer: NSErrorPointer
        ) -> Bool
        """,
        "@objc(clearSessionArchivesWithError:)",
        "public static func clearSessionArchives(error errorPointer: NSErrorPointer) -> Bool",
        "@objc(setAppContextProvider:)",
        "public static func setAppContextProvider(_ provider: @escaping () -> [ConsoleDockAppContextSection])",
        "@objc(clearAppContextProvider)",
        "public static func clearAppContextProvider()",
        "@objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:handler:)",
        """
        public static func registerAction(
            identifier: String,
            title: String,
            group: String?,
            detail: String?,
            requiresConfirmation: Bool,
            handler: @escaping () -> Void
        )
        """,
        "@objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:parameters:handler:)",
        """
        public static func registerAction(
            identifier: String,
            title: String,
            group: String?,
            detail: String?,
            requiresConfirmation: Bool,
            parameters: [ConsoleDockDebugActionParameter],
            handler: @escaping ([String: Any]) -> Void
        )
        """,
        "@objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:isEnabled:style:handler:)",
        """
        public static func registerAction(
            identifier: String,
            title: String,
            group: String?,
            detail: String?,
            requiresConfirmation: Bool,
            isEnabled: Bool,
            style: ConsoleDockDebugActionStyle,
            handler: @escaping () -> Void
        )
        """,
        "@objc(registerActionWithIdentifier:title:group:detail:requiresConfirmation:isEnabled:style:parameters:handler:)",
        """
        public static func registerAction(
            identifier: String,
            title: String,
            group: String?,
            detail: String?,
            requiresConfirmation: Bool,
            isEnabled: Bool,
            style: ConsoleDockDebugActionStyle,
            parameters: [ConsoleDockDebugActionParameter],
            handler: @escaping ([String: Any]) -> Void
        )
        """,
        "@objc(unregisterActionWithIdentifier:)",
        "public static func unregisterAction(identifier: String)",
        "@objc(removeAllActions)",
        "public static func removeAllActions()",
        "@objc(clearActionExecutionHistory)",
        "public static func clearActionExecutionHistory()",
    ],
}

REQUIRED_SNIPPET_COUNTS = {
    SWIFT_FACADE: {
        "public init(": 14,
        "public let message: String": 3,
    },
}

DENIED_PUBLIC_SNIPPETS = {
    SWIFT_FACADE: [
        "public class",
        "public actor",
        "public struct Configuration: Equatable",
    ],
    UIKIT_FACADE: [
        "public var",
    ],
}

PUBLIC_DECLARATION_RE = re.compile(r"^\s*(?:open|public)\s+", re.MULTILINE)


def normalized(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def validate_required_snippets(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required Swift API file is missing")
            continue

        text = path.read_text(encoding="utf-8")
        compact_text = normalized(text)
        for snippet in snippets:
            if normalized(snippet) not in compact_text:
                errors.append(f"{relative_path}: missing required Swift API snippet: {snippet}")

        for snippet, expected_count in REQUIRED_SNIPPET_COUNTS.get(relative_path, {}).items():
            actual_count = compact_text.count(normalized(snippet))
            if actual_count != expected_count:
                errors.append(
                    f"{relative_path}: expected {expected_count} occurrences of Swift API snippet "
                    f"{snippet!r}, found {actual_count}"
                )

        for snippet in DENIED_PUBLIC_SNIPPETS.get(relative_path, []):
            if snippet in text:
                errors.append(f"{relative_path}: forbidden public API shape: {snippet}")

    return errors


def validate_public_declaration_locations(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    source_root = root / SWIFT_SOURCE_ROOT
    if not source_root.exists():
        return [f"{SWIFT_SOURCE_ROOT}: Swift source root is missing"]

    for path in sorted(source_root.rglob("*.swift")):
        relative_path = path.relative_to(root)
        if relative_path in ALLOWED_PUBLIC_SWIFT_FILES:
            continue

        text = path.read_text(encoding="utf-8")
        if PUBLIC_DECLARATION_RE.search(text):
            errors.append(
                f"{relative_path}: public Swift declarations must stay in "
                f"{SWIFT_FACADE} or {UIKIT_FACADE}"
            )

    return errors


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    errors.extend(validate_required_snippets(root))
    errors.extend(validate_public_declaration_locations(root))
    return errors


def write_valid_api_files(root: pathlib.Path) -> None:
    swift_root = root / SWIFT_SOURCE_ROOT
    swift_root.mkdir(parents=True)
    (root / SWIFT_FACADE).write_text(
        "\n".join(REQUIRED_SNIPPETS[SWIFT_FACADE]) + "\n",
        encoding="utf-8",
    )
    (root / UIKIT_FACADE).write_text(
        "\n".join(REQUIRED_SNIPPETS[UIKIT_FACADE]) + "\n",
        encoding="utf-8",
    )
    (swift_root / "ConsoleDockEntryFilter.swift").write_text(
        "struct InternalEntryFilter {}\n",
        encoding="utf-8",
    )


def self_test() -> list[str]:
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="consoledock-swift-api-surface-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        write_valid_api_files(root)
        if validate(root):
            errors.append("validate should accept the expected Swift public API surface")

        missing_required_root = root / "missing-required"
        write_valid_api_files(missing_required_root)
        facade = missing_required_root / SWIFT_FACADE
        facade.write_text(
            facade.read_text(encoding="utf-8").replace(
                "public static func fault(_ message: String)\n",
                "",
            ),
            encoding="utf-8",
        )
        if not validate(missing_required_root):
            errors.append("validate should reject missing required Swift facade APIs")

        leaked_public_root = root / "leaked-public"
        write_valid_api_files(leaked_public_root)
        (leaked_public_root / SWIFT_SOURCE_ROOT / "ConsoleDockEntryFilter.swift").write_text(
            "public enum LeakedPublicAPI {}\n",
            encoding="utf-8",
        )
        if not validate(leaked_public_root):
            errors.append("validate should reject public declarations outside approved Swift facade files")

        forbidden_shape_root = root / "forbidden-shape"
        write_valid_api_files(forbidden_shape_root)
        forbidden_facade = forbidden_shape_root / SWIFT_FACADE
        forbidden_facade.write_text(
            forbidden_facade.read_text(encoding="utf-8") + "public class AccidentalReferenceType {}\n",
            encoding="utf-8",
        )
        if not validate(forbidden_shape_root):
            errors.append("validate should reject forbidden public Swift API shapes")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=pathlib.Path(__file__).resolve().parents[1],
        type=pathlib.Path,
        help="Repository root. Defaults to the parent of the scripts directory.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run local validator self-tests.")
    args = parser.parse_args()

    if args.self_test:
        errors = self_test()
        if errors:
            print("Swift API surface validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Swift API surface validator self-test passed.")
        return 0

    root = args.root.resolve()
    errors = validate(root)
    if errors:
        print("Swift API surface validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Swift API surface validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
