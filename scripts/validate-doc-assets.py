#!/usr/bin/env python3
"""Validate public documentation image assets."""

from __future__ import annotations

import argparse
import pathlib
import struct
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MIN_WIDTH = 300
MIN_HEIGHT = 500

REQUIRED_SCREENSHOTS = [
    pathlib.PurePosixPath("docs/assets/swift-sample-logs.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-actions.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-timeline.png"),
    pathlib.PurePosixPath("docs/assets/swift-sample-archive.png"),
]

REQUIRED_REFERENCES = {
    pathlib.Path("README.md"): [
        "docs/assets/swift-sample-logs.png",
    ],
    pathlib.Path("docs/sample-app-walkthrough.md"): [
        "assets/swift-sample-logs.png",
        "assets/swift-sample-actions.png",
        "assets/swift-sample-timeline.png",
        "assets/swift-sample-archive.png",
        "scripts/capture-swift-sample-screenshots.sh",
    ],
    pathlib.Path("docs/release-process.md"): [
        "scripts/capture-swift-sample-screenshots.sh",
        "visual QA",
    ],
}

STALE_REFERENCES = [
    "swift-sample-console.png",
]


def png_dimensions(path: pathlib.Path) -> tuple[int, int] | None:
    content = path.read_bytes()
    if len(content) < 33 or not content.startswith(PNG_SIGNATURE):
        return None
    if content[12:16] != b"IHDR":
        return None
    return struct.unpack(">II", content[16:24])


def validate_required_screenshots(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path in REQUIRED_SCREENSHOTS:
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required screenshot is missing")
            continue
        if path.is_dir():
            errors.append(f"{relative_path}: expected a PNG file, found a directory")
            continue
        dimensions = png_dimensions(path)
        if dimensions is None:
            errors.append(f"{relative_path}: expected a valid PNG file")
            continue
        width, height = dimensions
        if width < MIN_WIDTH or height < MIN_HEIGHT:
            errors.append(
                f"{relative_path}: expected at least {MIN_WIDTH}x{MIN_HEIGHT}, got {width}x{height}"
            )
    return errors


def validate_document_references(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_REFERENCES.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required documentation file is missing")
            continue
        content = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in content:
                errors.append(f"{relative_path}: missing required documentation asset snippet: {snippet}")
    return errors


def validate_stale_references(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    tracked_text_files = [
        pathlib.Path("README.md"),
        pathlib.Path("README.zh-CN.md"),
        pathlib.Path("docs/sample-app-walkthrough.md"),
        pathlib.Path("docs/release-process.md"),
    ]
    for relative_path in tracked_text_files:
        path = root / relative_path
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8")
        for snippet in STALE_REFERENCES:
            if snippet in content:
                errors.append(f"{relative_path}: stale screenshot reference remains: {snippet}")
    return errors


def validate_release_audit_allowlist(root: pathlib.Path) -> list[str]:
    audit_script = root / "scripts/audit-release-content.py"
    if not audit_script.exists():
        return ["scripts/audit-release-content.py: release content audit script is missing"]

    content = audit_script.read_text(encoding="utf-8")
    errors: list[str] = []
    for relative_path in REQUIRED_SCREENSHOTS:
        snippet = f'pathlib.PurePosixPath("{relative_path.as_posix()}")'
        if snippet not in content:
            errors.append(
                "scripts/audit-release-content.py: missing binary allow-list entry for "
                f"{relative_path}"
            )
    return errors


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    errors.extend(validate_required_screenshots(root))
    errors.extend(validate_document_references(root))
    errors.extend(validate_stale_references(root))
    errors.extend(validate_release_audit_allowlist(root))
    return errors


def self_test() -> list[str]:
    with_png = (
        PNG_SIGNATURE
        + b"\x00\x00\x00\rIHDR"
        + struct.pack(">II", 390, 844)
        + b"\x08\x06\x00\x00\x00"
        + b"\x00\x00\x00\x00"
    )
    invalid = b"not a png"

    errors: list[str] = []
    temporary_root = ROOT / ".build" / "doc-assets-self-test"
    temporary_root.mkdir(parents=True, exist_ok=True)
    valid_path = temporary_root / "valid.png"
    invalid_path = temporary_root / "invalid.png"
    valid_path.write_bytes(with_png)
    invalid_path.write_bytes(invalid)

    if png_dimensions(valid_path) != (390, 844):
        errors.append("png_dimensions should parse PNG IHDR dimensions")
    if png_dimensions(invalid_path) is not None:
        errors.append("png_dimensions should reject invalid PNG content")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=ROOT,
        type=pathlib.Path,
        help="Repository root. Defaults to the parent of the scripts directory.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run local validator self-tests.")
    args = parser.parse_args()

    errors = self_test() if args.self_test else validate(args.root.resolve())
    if errors:
        print("Documentation asset validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Documentation asset validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
