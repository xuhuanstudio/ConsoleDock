#!/usr/bin/env python3
"""Validate local Markdown and DocC article links."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import urllib.parse


IGNORED_DIRS = {
    ".build",
    ".git",
    ".swiftpm",
    "DerivedData",
    "outputs",
    "work",
}

EXTERNAL_SCHEMES = {
    "app",
    "data",
    "file",
    "ftp",
    "http",
    "https",
    "mailto",
    "tel",
}

MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HTML_LINK_RE = re.compile(r"\b(?:href|src)=[\"']([^\"']+)[\"']", re.IGNORECASE)
DOCC_ARTICLE_RE = re.compile(r"<doc:([A-Za-z0-9_-]+)>")
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def iter_markdown_files(root: pathlib.Path) -> list[pathlib.Path]:
    files: list[pathlib.Path] = []
    for path in root.rglob("*.md"):
        if any(part in IGNORED_DIRS for part in path.relative_to(root).parts):
            continue
        files.append(path)
    return sorted(files)


def iter_content_lines(path: pathlib.Path) -> list[tuple[int, str]]:
    lines: list[tuple[int, str]] = []
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            lines.append((number, line))
    return lines


def is_external_target(target: str) -> bool:
    parsed = urllib.parse.urlparse(target)
    return parsed.scheme.lower() in EXTERNAL_SCHEMES


def split_link_target(target: str) -> tuple[str, str]:
    parsed = urllib.parse.urlparse(target)
    path = urllib.parse.unquote(parsed.path)
    return path, parsed.fragment


def validate_markdown_target(
    root: pathlib.Path,
    source: pathlib.Path,
    line_number: int,
    target: str,
    errors: list[str],
) -> None:
    target = target.strip()
    if not target or target.startswith("#") or is_external_target(target):
        return

    path_part, _fragment = split_link_target(target)
    if not path_part:
        return

    if pathlib.PurePosixPath(path_part).is_absolute():
        errors.append(format_error(root, source, line_number, f"absolute local link is not portable: {target}"))
        return

    resolved = (source.parent / path_part).resolve()
    try:
        resolved.relative_to(root)
    except ValueError:
        errors.append(format_error(root, source, line_number, f"link escapes repository root: {target}"))
        return

    if not resolved.exists():
        errors.append(format_error(root, source, line_number, f"missing linked file: {target}"))


def validate_docc_article(
    root: pathlib.Path,
    source: pathlib.Path,
    line_number: int,
    article_name: str,
    errors: list[str],
) -> None:
    catalog = next((parent for parent in source.parents if parent.suffix == ".docc"), None)
    if catalog is None:
        errors.append(format_error(root, source, line_number, f"DocC article reference outside a .docc catalog: {article_name}"))
        return

    expected = catalog / f"{article_name}.md"
    if not expected.exists():
        errors.append(format_error(root, source, line_number, f"missing DocC article: <doc:{article_name}>"))


def format_error(root: pathlib.Path, source: pathlib.Path, line_number: int, message: str) -> str:
    return f"{source.relative_to(root)}:{line_number}: {message}"


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for path in iter_markdown_files(root):
        for line_number, line in iter_content_lines(path):
            for match in MARKDOWN_LINK_RE.finditer(line):
                validate_markdown_target(root, path, line_number, match.group(1), errors)
            for match in HTML_LINK_RE.finditer(line):
                validate_markdown_target(root, path, line_number, match.group(1), errors)
            for match in DOCC_ARTICLE_RE.finditer(line):
                validate_docc_article(root, path, line_number, match.group(1), errors)
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
        print("Documentation link validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Documentation link validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
