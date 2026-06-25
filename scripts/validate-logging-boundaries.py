#!/usr/bin/env python3
"""Validate public technical-boundary documentation stays accurate."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile


REQUIRED_SNIPPETS = {
    "README.md": [
        "ConsoleDock must not be described as a full replacement for Xcode Console or Apple unified logging.",
        "ConsoleDock cannot promise complete, reliable, live, zero-intrusion capture of:",
        "Reliable complete logging should go through ConsoleDock's explicit API or an adapter for an existing logging framework.",
        "ConsoleDock's on-device panel reads from ConsoleDock's own in-memory store.",
        "ConsoleDock only stores, displays, and triggers actions registered by the host app. It does not discover screens, take over routing, bypass app permissions, receive remote commands, or act as an automation test framework.",
    ],
    "README.zh-CN.md": [
        "ConsoleDock 不能被描述成 Xcode Console 或 Apple unified logging 的完整替代品。",
        "ConsoleDock 不能承诺完整、稳定、实时、零侵入捕获：",
        "如果需要可靠完整的 App 内日志展示，推荐使用 ConsoleDock 的显式 API，或者在已有 logger 中增加 sink/appender 转发。",
        "ConsoleDock 只展示和触发 App 注册的动作；它不会自动发现页面、接管路由、绕过业务权限、远程下发命令，也不是自动化测试平台。",
    ],
    "docs/migration-existing-loggers.md": [
        "Do not depend on ConsoleDock reading Swift `Logger` or `os_log` entries back from Apple unified logging.",
        "Reliable in-app visibility needs an explicit forward.",
        "ConsoleDock does not currently ship packaged CocoaLumberjack, XCGLogger, or SwiftyBeaver adapters.",
    ],
    "docs/sample-app-walkthrough.md": [
        "Swift `Logger`, `os_log`, and Apple unified logging are not validated by these samples",
        "ConsoleDock does not promise complete zero-intrusion capture of those systems.",
        "Debug Actions are local, app-registered shortcuts. ConsoleDock does not discover pages, control routing, bypass app permissions, or receive remote commands.",
    ],
    "docs/product-brief.md": [
        "ConsoleDock only displays and triggers actions that the app registers. It should not discover routes, control app navigation automatically, bypass business permissions, or accept remote commands.",
        "Do not turn Debug Actions into a remote command system or automatic route discovery layer.",
    ],
    "docs/release-process.md": [
        "Do not describe ConsoleDock as a full Xcode Console, Swift `Logger`, `os_log`, or Apple unified logging replacement.",
    ],
    "Sources/ConsoleDock/Documentation.docc/ConsoleDock.md": [
        "ConsoleDock is not a full replacement for Xcode Console or Apple unified logging.",
        "It does not promise complete zero-intrusion capture of Swift `Logger`, `os_log`, system logs, other-process logs, debugger output, LLDB expressions, or sanitizer diagnostics.",
    ],
    "Sources/ConsoleDock/Documentation.docc/LoggingBoundaries.md": [
        "ConsoleDock does not read Apple unified logging back from inside the app.",
        "For logs that must appear in the in-app panel, call the explicit API or add an adapter in your existing logging stack.",
    ],
    "Sources/ConsoleDock/Documentation.docc/ExistingLoggerMigration.md": [
        "ConsoleDock does not promise complete zero-intrusion capture of Apple unified logging.",
        "Forward Swift `Logger` and `os_log` messages explicitly when they must appear in the panel.",
    ],
    "Sources/ConsoleDock/Documentation.docc/IntegrationDiagnostics.md": [
        "Diagnostics do not prove complete zero-intrusion capture of Swift `Logger`, `os_log`, Apple unified logging, other-process logs, sanitizer diagnostics, LLDB expressions, or Xcode-only output.",
    ],
    "Sources/ConsoleDock/Documentation.docc/DebugActions.md": [
        "ConsoleDock does not discover screens, take over routing, bypass business permissions, receive remote commands, or act as an automation test framework.",
    ],
}

FORBIDDEN_PATTERNS = [
    (
        re.compile(r"\bConsoleDock\s+is\s+(?:a\s+)?(?:full\s+)?replacement\s+for\s+Xcode\s+Console\b", re.IGNORECASE),
        "ConsoleDock must not be described as an Xcode Console replacement",
    ),
    (
        re.compile(r"\bConsoleDock\s+captures\s+(?:all\s+)?Swift\s+Logger\b", re.IGNORECASE),
        "ConsoleDock must not claim complete Swift Logger capture",
    ),
    (
        re.compile(r"\bConsoleDock\s+captures\s+(?:all\s+)?os_log\b", re.IGNORECASE),
        "ConsoleDock must not claim complete os_log capture",
    ),
    (
        re.compile(r"\bConsoleDock\s+captures\s+(?:all\s+)?Apple\s+unified\s+logging\b", re.IGNORECASE),
        "ConsoleDock must not claim complete Apple unified logging capture",
    ),
    (
        re.compile(r"\bzero-intrusion\s+(?:Swift\s+Logger|os_log|Apple\s+unified\s+logging)\s+capture\s+is\s+supported\b", re.IGNORECASE),
        "ConsoleDock must not promise zero-intrusion unified logging support",
    ),
    (
        re.compile(r"\bConsoleDock\s+(?:can\s+)?reads?\s+logs\s+from\s+other\s+(?:apps|processes)\b", re.IGNORECASE),
        "ConsoleDock must not claim other-process log access",
    ),
    (
        re.compile(
            r"\b(?:future\s+)?(?:implementation|adapter|api)\s+(?:may\s+)?(?:also\s+)?(?:write|forward)s?\s+to\s+Apple\s+unified\s+logging\b",
            re.IGNORECASE,
        ),
        "ConsoleDock must not frame Apple unified logging writes as a future public capability promise",
    ),
    (
        re.compile(r"\bfull\s+`?Logger`?\s*/\s*`?os_log`?\s+ingestion\b", re.IGNORECASE),
        "ConsoleDock roadmap language must not imply full Logger/os_log ingestion",
    ),
    (
        re.compile(r"\bDebug Actions?\s+(?:can\s+|will\s+)?(?:discover|auto-discover|automatically discover)\s+(?:screens|pages|routes)\b", re.IGNORECASE),
        "Debug Actions must not claim automatic screen or route discovery",
    ),
    (
        re.compile(r"\bDebug Actions?\s+(?:can\s+|will\s+)?(?:receive|accept|run)\s+remote\s+commands\b", re.IGNORECASE),
        "Debug Actions must not claim remote command support",
    ),
]


def iter_public_docs(root: pathlib.Path) -> list[pathlib.Path]:
    candidates: list[pathlib.Path] = []
    for relative in [
        "README.md",
        "README.zh-CN.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "docs",
        "Sources/ConsoleDock/Documentation.docc",
    ]:
        path = root / relative
        if path.is_file():
            candidates.append(path)
        elif path.is_dir():
            candidates.extend(sorted(path.rglob("*.md")))
    return sorted(set(candidates))


def validate_required_snippets(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required logging-boundary document is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required logging-boundary snippet: {snippet}")
    return errors


def validate_forbidden_claims(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for path in iter_public_docs(root):
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(root).as_posix()
        errors.extend(forbidden_claim_errors(relative_path, text))
    return errors


def forbidden_claim_errors(relative_path: str, text: str) -> list[str]:
    errors: list[str] = []
    for pattern, message in FORBIDDEN_PATTERNS:
        match = pattern.search(text)
        if match:
            errors.append(f"{relative_path}: {message}: {match.group(0)}")
    return errors


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    errors.extend(validate_required_snippets(root))
    errors.extend(validate_forbidden_claims(root))
    return errors


def write_text(root: pathlib.Path, relative_path: str, text: str) -> None:
    path = root / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def self_test() -> list[str]:
    errors: list[str] = []
    for index, bad_text in enumerate(
        [
            "ConsoleDock is a replacement for Xcode Console.",
            "ConsoleDock captures all Swift Logger messages.",
            "ConsoleDock captures os_log entries.",
            "ConsoleDock captures Apple unified logging.",
            "zero-intrusion os_log capture is supported.",
            "ConsoleDock reads logs from other apps.",
            "future adapter may also write to Apple unified logging.",
            "- full `Logger` / `os_log` ingestion.",
            "Debug Actions can discover routes.",
            "Debug Actions can receive remote commands.",
        ]
    ):
        if not forbidden_claim_errors(f"bad-{index}.md", bad_text):
            errors.append(f"forbidden_claim_errors should reject bad boundary claim: {bad_text}")

    allowed_text = (
        "ConsoleDock is not a full replacement for Xcode Console or Apple unified logging.\n"
        "It does not promise complete zero-intrusion capture of Swift `Logger`, `os_log`, "
        "or Apple unified logging.\n"
        "Later scope must keep the same technical boundary: reliable `Logger` and `os_log` "
        "visibility requires active integration through ConsoleDock APIs or adapters.\n"
    )
    if forbidden_claim_errors("allowed.md", allowed_text):
        errors.append("forbidden_claim_errors should allow explicit negative boundary language")

    with tempfile.TemporaryDirectory(prefix="consoledock-logging-boundary-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        for relative_path, snippets in REQUIRED_SNIPPETS.items():
            write_text(root, relative_path, "\n".join(snippets))

        write_text(root, "docs/roadmap.md", "Not included:\n- automatic Swift Logger / os_log ingestion.\n")
        if validate(root):
            errors.append("validate should accept required snippets plus non-promissory roadmap language")

        write_text(root, "docs/roadmap.md", "Future deliverables:\n- full `Logger` / `os_log` ingestion.\n")
        if not validate(root):
            errors.append("validate should reject full Logger/os_log ingestion language in public docs")

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
            print("Logging boundary validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Logging boundary validator self-test passed.")
        return 0

    root = args.root.resolve()
    errors = validate(root)
    if errors:
        print("Logging boundary validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Logging boundary validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
