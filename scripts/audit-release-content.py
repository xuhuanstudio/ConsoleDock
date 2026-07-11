#!/usr/bin/env python3
"""Audit tracked repository content for public-release hygiene."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


DENIED_TRACKED_PATHS = [
    re.compile(r"(^|/)\.DS_Store$"),
    re.compile(r"(^|/)\.build(/|$)"),
    re.compile(r"(^|/)DerivedData(/|$)"),
    re.compile(r"\.xcuserdata(/|$)"),
    re.compile(r"\.xcuserstate$"),
    re.compile(r"(^|/)Pods(/|$)"),
]

ALLOWED_BINARY_PATHS = {
    pathlib.PurePosixPath("docs/assets/swift-sample-actions.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-archive.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-context.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-logs.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-report.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-timeline.png"),
}

SENSITIVE_PATTERNS = [
    (
        "private key block",
        re.compile(rb"-----BEGIN (?:RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----"),
    ),
    (
        "GitHub token",
        re.compile(rb"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    ),
    (
        "AWS access key id",
        re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    ),
    (
        "Slack token",
        re.compile(rb"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    ),
    (
        "absolute local user path",
        re.compile(rb"/Users/[A-Za-z0-9._-]+/"),
    ),
    (
        "Xcode DerivedData path",
        re.compile(b"/Library/Developer/Xcode/" + b"DerivedData/"),
    ),
]

MAX_TEXT_BYTES = 2_000_000


def tracked_files(root: pathlib.Path) -> list[pathlib.Path]:
    output = subprocess.check_output(["git", "ls-files", "-z"], cwd=root)
    files: list[pathlib.Path] = []
    for raw_path in output.split(b"\0"):
        if not raw_path:
            continue
        files.append(pathlib.Path(raw_path.decode("utf-8")))
    return sorted(files)


def is_denied_tracked_path(path: pathlib.Path) -> bool:
    text = path.as_posix()
    return any(pattern.search(text) for pattern in DENIED_TRACKED_PATHS)


def is_binary(content: bytes) -> bool:
    return b"\0" in content


def audit(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path in tracked_files(root):
        posix_path = pathlib.PurePosixPath(relative_path.as_posix())
        display_path = relative_path.as_posix()

        if is_denied_tracked_path(relative_path):
            errors.append(f"{display_path}: generated or local-only path is tracked")

        absolute_path = root / relative_path
        if not absolute_path.exists():
            errors.append(f"{display_path}: tracked file is missing from the working tree")
            continue

        content = absolute_path.read_bytes()
        if is_binary(content):
            if posix_path not in ALLOWED_BINARY_PATHS:
                errors.append(f"{display_path}: binary file is tracked but not allow-listed")
            continue

        if len(content) > MAX_TEXT_BYTES:
            errors.append(f"{display_path}: text file is unexpectedly large for source release audit")
            continue

        for label, pattern in SENSITIVE_PATTERNS:
            if pattern.search(content):
                errors.append(f"{display_path}: contains {label}")

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
    errors = audit(root)
    if errors:
        print("Release content audit failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Release content audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
