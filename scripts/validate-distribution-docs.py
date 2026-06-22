#!/usr/bin/env python3
"""Validate distribution-channel documentation and shipped artifacts stay honest."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


REQUIRED_SNIPPETS = {
    "docs/distribution-strategy.md": [
        "SPM is the only supported public distribution channel today.",
        "No CocoaPods podspec is shipped yet.",
        "CocoaPods should be treated as a legacy compatibility bridge",
        "No XCFramework artifact is shipped yet.",
        "Release startup remains gated by both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`",
        "no default network upload, no default disk persistence, and no private API",
        "Distribution validation also rejects tracked CocoaPods podspecs",
        "Avoid these claims until they are true and validated",
    ],
    "README.md": [
        "For distribution channel boundaries, see [Distribution strategy](docs/distribution-strategy.md).",
        "distribution documentation and artifacts",
        "CocoaPods for older Objective-C or mixed projects",
        "XCFramework for manual or closed-source distribution",
    ],
    "README.zh-CN.md": [
        "分发策略",
        "CocoaPods",
        "XCFramework",
    ],
    "docs/open-source-readiness.md": [
        "[Distribution strategy](distribution-strategy.md)",
        "CocoaPods support should come after the SPM package is stable.",
        "XCFramework support should come after the core API is stable.",
    ],
    "docs/release-process.md": [
        "distribution strategy",
        "CocoaPods and XCFramework artifacts remain future distribution channels",
    ],
    "docs/roadmap.md": [
        "CocoaPods compatibility bridge",
        "binary XCFramework",
    ],
}

FORBIDDEN_PATTERNS = {
    "README.md": [
        re.compile(r"\bpod\s+['\"]ConsoleDock", re.IGNORECASE),
        re.compile(r"\bCocoaPods\s+supported\b", re.IGNORECASE),
        re.compile(r"\bDownload the XCFramework\b", re.IGNORECASE),
    ],
    "README.zh-CN.md": [
        re.compile(r"\bpod\s+['\"]ConsoleDock", re.IGNORECASE),
        re.compile(r"已支持\s*CocoaPods", re.IGNORECASE),
        re.compile(r"下载\s*XCFramework", re.IGNORECASE),
    ],
}

DENIED_TRACKED_ARTIFACT_PATTERNS = [
    (
        "CocoaPods podspec",
        re.compile(r"(^|/)[^/]+\.podspec(?:\.json)?$", re.IGNORECASE),
    ),
    (
        "CocoaPods install output",
        re.compile(r"(^|/)Pods(/|$)"),
    ),
    (
        "SwiftPM lock file",
        re.compile(r"(^|/)Package\.resolved$"),
    ),
    (
        "XCFramework artifact",
        re.compile(r"(^|/)[^/]+\.xcframework(/|$)", re.IGNORECASE),
    ),
    (
        "Apple framework artifact",
        re.compile(r"(^|/)[^/]+\.framework(/|$)", re.IGNORECASE),
    ),
    (
        "Xcode archive artifact",
        re.compile(r"(^|/)[^/]+\.xcarchive(/|$)", re.IGNORECASE),
    ),
    (
        "debug symbol artifact",
        re.compile(r"(^|/)[^/]+\.dSYM(/|$)", re.IGNORECASE),
    ),
    (
        "static library artifact",
        re.compile(r"(^|/)[^/]+\.a$", re.IGNORECASE),
    ),
    (
        "packaged binary/archive artifact",
        re.compile(r"(^|/)[^/]+\.(?:zip|tar|tgz|gz|dmg|pkg)$", re.IGNORECASE),
    ),
]


def tracked_files(root: pathlib.Path) -> list[str]:
    output = subprocess.check_output(["git", "ls-files", "-z"], cwd=root)
    return sorted(path.decode("utf-8") for path in output.split(b"\0") if path)


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required distribution document is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required distribution snippet: {snippet}")

        for pattern in FORBIDDEN_PATTERNS.get(relative_path, []):
            if pattern.search(text):
                errors.append(f"{relative_path}: contains premature distribution claim matching {pattern.pattern}")

    for relative_path in tracked_files(root):
        for label, pattern in DENIED_TRACKED_ARTIFACT_PATTERNS:
            if pattern.search(relative_path):
                errors.append(
                    f"{relative_path}: tracked {label} conflicts with current SPM-only distribution policy"
                )

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
        print("Distribution validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Distribution validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
