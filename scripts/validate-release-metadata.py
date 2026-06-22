#!/usr/bin/env python3
"""Validate release tag shape and changelog readiness."""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import sys
import tempfile


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


def resolve_tag(explicit_tag: str | None, *, announce_skip: bool = True) -> str | None:
    if explicit_tag:
        return explicit_tag

    if os.environ.get("GITHUB_REF_TYPE") != "tag":
        if announce_skip:
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


def write_changelog(root: pathlib.Path, text: str) -> pathlib.Path:
    path = root / "CHANGELOG.md"
    path.write_text(text, encoding="utf-8")
    return path


def self_test() -> list[str]:
    errors: list[str] = []
    valid_changelog = """# Changelog

## Unreleased

No changes yet.

## v0.2.0 - 2026-06-22

### Added

- Release metadata validation.
"""

    if find_section(valid_changelog, "Unreleased") != "No changes yet.":
        errors.append("find_section should return the exact Unreleased section body")

    if not has_release_heading(valid_changelog, "v0.2.0"):
        errors.append("has_release_heading should accept plain release headings")

    bracketed_changelog = valid_changelog.replace("## v0.2.0 - 2026-06-22", "## [v0.2.0] - 2026-06-22")
    if not has_release_heading(bracketed_changelog, "v0.2.0"):
        errors.append("has_release_heading should accept bracketed release headings")

    saved_ref_type = os.environ.get("GITHUB_REF_TYPE")
    saved_ref_name = os.environ.get("GITHUB_REF_NAME")
    try:
        os.environ["GITHUB_REF_TYPE"] = "branch"
        os.environ["GITHUB_REF_NAME"] = "main"
        if resolve_tag(None, announce_skip=False) is not None:
            errors.append("resolve_tag should skip tag-specific checks outside tag workflows")

        os.environ["GITHUB_REF_TYPE"] = "tag"
        os.environ["GITHUB_REF_NAME"] = "v0.2.0"
        if resolve_tag(None, announce_skip=False) != "v0.2.0":
            errors.append("resolve_tag should read the GitHub tag name in tag workflows")
    finally:
        if saved_ref_type is None:
            os.environ.pop("GITHUB_REF_TYPE", None)
        else:
            os.environ["GITHUB_REF_TYPE"] = saved_ref_type

        if saved_ref_name is None:
            os.environ.pop("GITHUB_REF_NAME", None)
        else:
            os.environ["GITHUB_REF_NAME"] = saved_ref_name

    with tempfile.TemporaryDirectory(prefix="consoledock-release-metadata-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        changelog = write_changelog(root, valid_changelog)
        if validate(changelog, "v0.2.0"):
            errors.append("validate should accept a semver tag with a matching release heading and cleared Unreleased")

        invalid_tag_errors = validate(changelog, "release-0.2.0")
        if not invalid_tag_errors:
            errors.append("validate should reject non-semver release tags")

        missing_heading = write_changelog(
            root,
            valid_changelog.replace("## v0.2.0 - 2026-06-22", "## v0.3.0 - 2026-06-22"),
        )
        if not validate(missing_heading, "v0.2.0"):
            errors.append("validate should reject changelogs without a matching release heading")

        dirty_unreleased = write_changelog(root, valid_changelog.replace("No changes yet.", "### Added\n\n- Pending work."))
        if not validate(dirty_unreleased, "v0.2.0"):
            errors.append("validate should reject releases while Unreleased still contains pending entries")

        missing_unreleased = write_changelog(root, valid_changelog.replace("## Unreleased\n\nNo changes yet.\n\n", ""))
        if not validate(missing_unreleased, "v0.2.0"):
            errors.append("validate should reject changelogs without an Unreleased section")

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
    parser.add_argument("--self-test", action="store_true", help="Run local validator self-tests.")
    args = parser.parse_args()

    if args.self_test:
        errors = self_test()
        if errors:
            print("Release metadata validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Release metadata validator self-test passed.")
        return 0

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
