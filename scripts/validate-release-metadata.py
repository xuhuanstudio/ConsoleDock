#!/usr/bin/env python3
"""Validate release tag shape and changelog readiness."""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import sys


SEMVER_TAG_RE = re.compile(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?")
SECTION_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)


def find_section(markdown: str, title: str) -> str | None:
    matches = list(SECTION_RE.finditer(markdown))
    for index, match in enumerate(matches):
        section_title = match.group(1).strip()
        if section_title != title:
            continue
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(markdown)
        return markdown[start:end].strip()
    return None


def has_release_heading(markdown: str, tag: str) -> bool:
    heading = re.compile(rf"^## \[?{re.escape(tag)}\]?(?:\s|-|$)", re.MULTILINE)
    return heading.search(markdown) is not None


def resolve_tag(explicit_tag: str | None) -> str | None:
    if explicit_tag:
        return explicit_tag

    if os.environ.get("GITHUB_REF_TYPE") != "tag":
        print("Manual release metadata validation run; skipping tag-specific checks.")
        return None

    return os.environ.get("GITHUB_REF_NAME", "")


def validate(changelog_path: pathlib.Path, tag: str | None) -> list[str]:
    errors: list[str] = []
    resolved_tag = resolve_tag(tag)
    if resolved_tag is None:
        return errors

    if not SEMVER_TAG_RE.fullmatch(resolved_tag):
        errors.append(f"release tag must use semantic version form like v0.1.0, got {resolved_tag}")

    changelog = changelog_path.read_text(encoding="utf-8")
    if not has_release_heading(changelog, resolved_tag):
        errors.append(f"{changelog_path} must contain a release heading for {resolved_tag}")

    unreleased = find_section(changelog, "Unreleased")
    if unreleased is None:
        errors.append(f"{changelog_path} must contain an Unreleased section")
    elif unreleased != "No changes yet.":
        errors.append(f"{changelog_path} Unreleased section must be cleared before tagging {resolved_tag}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", help="Release tag to validate, for example v0.1.0.")
    parser.add_argument(
        "--changelog",
        default=pathlib.Path("CHANGELOG.md"),
        type=pathlib.Path,
        help="Path to CHANGELOG.md. Defaults to CHANGELOG.md in the current directory.",
    )
    args = parser.parse_args()

    errors = validate(args.changelog, args.tag)
    if errors:
        print("Release metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Release metadata validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
