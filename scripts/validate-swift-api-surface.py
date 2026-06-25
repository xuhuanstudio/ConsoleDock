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
        "public struct Configuration: Equatable",
        "public var maximumEntries: Int",
        "public var maximumMessageLength: Int",
        "public var captureStandardOutput: Bool",
        "public var captureStandardError: Bool",
        "public var showsFloatingButton: Bool",
        "public var allowsReleaseBuilds: Bool",
        "public var redactor: ((String) -> String)?",
        "maximumEntries: Int = 2_000",
        "maximumMessageLength: Int = 8_192",
        "captureStandardOutput: Bool = true",
        "captureStandardError: Bool = true",
        "showsFloatingButton: Bool = true",
        "allowsReleaseBuilds: Bool = false",
        "redactor: ((String) -> String)? = nil",
        """
        public init(
            maximumEntries: Int = 2_000,
            maximumMessageLength: Int = 8_192,
            captureStandardOutput: Bool = true,
            captureStandardError: Bool = true,
            showsFloatingButton: Bool = true,
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
        "public let partial: Bool",
        "public let redacted: Bool",
        "public let truncated: Bool",
        "id: UInt64 = 0",
        "timestamp: Date",
        "level: LogLevel",
        "source: LogSource",
        "message: String",
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
            partial: Bool = false,
            redacted: Bool = false,
            truncated: Bool = false
        )
        """,
        "public struct Diagnostics: Equatable",
        "public let isRunning: Bool",
        "public let capturesStandardOutput: Bool",
        "public let capturesStandardError: Bool",
        "public let showsFloatingButton: Bool",
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
            allowsReleaseBuilds: Bool,
            maximumEntries: Int,
            maximumMessageLength: Int,
            entryCount: Int,
            redactedEntryCount: Int,
            truncatedEntryCount: Int,
            partialEntryCount: Int
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
        "public static let entriesDidChangeNotification",
        "public static let diagnosticsDidChangeNotification",
        "public static func clear()",
        "public static func showConsole()",
        "public static func hideConsole()",
        """
        public static func registerAction(
            id: String,
            title: String,
            group: String? = nil,
            detail: String? = nil,
            requiresConfirmation: Bool = false,
            handler: @escaping () throws -> Void
        )
        """,
        "public static func unregisterAction(id: String)",
        "public static func removeAllActions()",
        "public static func debug(_ message: String)",
        "public static func log(level: LogLevel, message: String)",
        "public static func info(_ message: String)",
        "public static func warning(_ message: String)",
        "public static func error(_ message: String)",
        "public static func fault(_ message: String)",
    ],
    UIKIT_FACADE: [
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
        "@objc(unregisterActionWithIdentifier:)",
        "public static func unregisterAction(identifier: String)",
        "@objc(removeAllActions)",
        "public static func removeAllActions()",
    ],
}

REQUIRED_SNIPPET_COUNTS = {
    SWIFT_FACADE: {
        "public init(": 4,
        "public let message: String": 2,
    },
}

DENIED_PUBLIC_SNIPPETS = {
    SWIFT_FACADE: [
        "public class",
        "public actor",
    ],
    UIKIT_FACADE: [
        "public var",
        "public let",
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
