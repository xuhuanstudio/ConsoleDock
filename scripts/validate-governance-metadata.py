#!/usr/bin/env python3
"""Validate open-source governance and GitHub metadata for public release."""

from __future__ import annotations

import argparse
import pathlib
import sys


REQUIRED_FILES = [
    "LICENSE",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "CONTRIBUTING.md",
    ".github/workflows/ci.yml",
    ".github/workflows/release-validation.yml",
    ".github/dependabot.yml",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
    ".github/pull_request_template.md",
]

REQUIRED_SNIPPETS = {
    "LICENSE": [
        "MIT License",
        "Copyright (c) 2026 ConsoleDock contributors",
    ],
    "CODE_OF_CONDUCT.md": [
        "Contributor Covenant",
        "Expected Behavior",
        "Unacceptable Behavior",
        "Enforcement",
    ],
    "SECURITY.md": [
        "ConsoleDock is a debug SDK",
        "Use GitHub private vulnerability reporting",
        "Do not include exploit details",
        "production logs",
        "accidental Release-build activation",
        "missing or bypassed redaction",
        "use of private APIs",
        "does not read logs from other processes",
    ],
    "CONTRIBUTING.md": [
        "scripts/validate-release.sh",
        "Keep Objective-C symbols prefixed with `CDK`",
        "Do not claim complete zero-intrusion capture of Swift `Logger` or `os_log`",
        "Release startup requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`",
        "Do not add network upload, persistence, or export behavior without privacy review",
    ],
    ".github/workflows/ci.yml": [
        "pull_request:",
        "branches:",
        "- main",
        "permissions:",
        "contents: read",
        "concurrency:",
        "cancel-in-progress: true",
        "timeout-minutes:",
        "actions/checkout@v6",
        "persist-credentials: false",
        "scripts/validate-release.sh",
    ],
    ".github/workflows/release-validation.yml": [
        'tags:',
        '"v*"',
        "permissions:",
        "contents: read",
        "concurrency:",
        "cancel-in-progress: false",
        "timeout-minutes:",
        "actions/checkout@v6",
        "persist-credentials: false",
        "python3 scripts/validate-release-metadata.py",
        "scripts/validate-release.sh",
    ],
    ".github/dependabot.yml": [
        "package-ecosystem: \"github-actions\"",
        "interval: \"weekly\"",
        "timezone: \"Asia/Shanghai\"",
    ],
    ".github/ISSUE_TEMPLATE/bug_report.yml": [
        "Do not include secrets, tokens, credentials, or production logs.",
        "vulnerability or sensitive-data exposure",
        "ConsoleDock version or commit",
        "Xcode, Swift, and platform",
        "Privacy and Release-build check",
    ],
    ".github/ISSUE_TEMPLATE/feature_request.yml": [
        "Do not include secrets, tokens, credentials, or production logs.",
        "vulnerability details or sensitive-data exposure",
        "Boundary check",
        "Swift Logger/os_log capture",
        "Safety and distribution impact",
    ],
    ".github/pull_request_template.md": [
        "Public API:",
        "Objective-C compatibility:",
        "Release-build behavior:",
        "Privacy/redaction:",
        "Logging boundary claims:",
        "Objective-C symbols use the `CDK` prefix",
        "Release startup still requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`",
    ],
}


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path in REQUIRED_FILES:
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required governance file is missing")
            continue

        text = path.read_text(encoding="utf-8")
        if not text.strip():
            errors.append(f"{relative_path}: required governance file is empty")
            continue

        for snippet in REQUIRED_SNIPPETS.get(relative_path, []):
            if snippet not in text:
                errors.append(f"{relative_path}: missing required governance snippet: {snippet}")

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
    args = parser.parse_args()

    root = args.root.resolve()
    errors = validate(root)
    if errors:
        print("Governance metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Governance metadata validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
