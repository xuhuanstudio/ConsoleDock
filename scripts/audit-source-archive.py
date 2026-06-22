#!/usr/bin/env python3
"""Audit a SwiftPM source archive before publishing a release."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import zipfile


DENIED_COMPONENTS = {
    ".build",
    ".git",
    ".swiftpm",
    ".xcuserdata",
    "DerivedData",
    "Pods",
    "xcuserdata",
}

DENIED_FILE_NAMES = {
    ".DS_Store",
    "Package.resolved",
}

ALLOWED_BINARY_PATHS = {
    pathlib.PurePosixPath("docs/assets/swift-sample-console.png"),
}

REQUIRED_ARCHIVE_PATHS = {
    pathlib.PurePosixPath(".spi.yml"),
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


def strip_archive_root(path: pathlib.PurePosixPath) -> pathlib.PurePosixPath:
    parts = path.parts
    if len(parts) <= 1:
        return pathlib.PurePosixPath("")
    return pathlib.PurePosixPath(*parts[1:])


def is_binary(content: bytes) -> bool:
    return b"\0" in content


def audit_archive(archive_path: pathlib.Path) -> list[str]:
    errors: list[str] = []
    if not archive_path.exists():
        return [f"{archive_path}: archive does not exist"]
    if archive_path.stat().st_size == 0:
        return [f"{archive_path}: archive is empty"]

    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        if not names:
            errors.append(f"{archive_path}: archive contains no entries")

        roots = {pathlib.PurePosixPath(name).parts[0] for name in names if pathlib.PurePosixPath(name).parts}
        if len(roots) != 1:
            errors.append(f"{archive_path}: archive should contain exactly one top-level directory")

        normalized_paths = {
            strip_archive_root(pathlib.PurePosixPath(name))
            for name in names
            if not name.endswith("/")
        }
        for required_path in REQUIRED_ARCHIVE_PATHS:
            if required_path not in normalized_paths:
                errors.append(f"{archive_path}: archive is missing required file {required_path}")

        for info in archive.infolist():
            name = info.filename
            path = pathlib.PurePosixPath(name)
            normalized = strip_archive_root(path)
            display_path = name.rstrip("/")

            if path.is_absolute() or ".." in path.parts:
                errors.append(f"{display_path}: archive entry is not a safe relative path")

            if any(component in DENIED_COMPONENTS for component in normalized.parts):
                errors.append(f"{display_path}: generated or local-only path is archived")

            if normalized.name in DENIED_FILE_NAMES:
                errors.append(f"{display_path}: local-only file is archived")

            if info.is_dir():
                continue

            content = archive.read(info)
            if is_binary(content):
                if normalized not in ALLOWED_BINARY_PATHS:
                    errors.append(f"{display_path}: binary file is archived but not allow-listed")
                continue

            if len(content) > MAX_TEXT_BYTES:
                errors.append(f"{display_path}: text file is unexpectedly large for source archive audit")
                continue

            for label, pattern in SENSITIVE_PATTERNS:
                if pattern.search(content):
                    errors.append(f"{display_path}: contains {label}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "archive",
        nargs="?",
        default=pathlib.Path(".build/ConsoleDock-source.zip"),
        type=pathlib.Path,
        help="Source archive path. Defaults to .build/ConsoleDock-source.zip.",
    )
    args = parser.parse_args()

    errors = audit_archive(args.archive)
    if errors:
        print("Source archive audit failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Source archive audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
