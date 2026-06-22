#!/usr/bin/env python3
"""Validate Swift Package Index metadata for hosted DocC documentation."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys


EXPECTED_VERSION = "1"
EXPECTED_DOCUMENTATION_TARGETS = ["ConsoleDock"]
DOCUMENTATION_TARGETS_RE = re.compile(r"^\s*-\s*documentation_targets:\s*\[([^\]]*)\]\s*$")
VERSION_RE = re.compile(r"^\s*version:\s*(\S+)\s*$")
TARGET_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def package_targets(root: pathlib.Path) -> set[str]:
    output = subprocess.check_output(["swift", "package", "dump-package"], cwd=root)
    package = json.loads(output)
    return {target["name"] for target in package.get("targets", [])}


def parse_documentation_targets(text: str) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    matches = [DOCUMENTATION_TARGETS_RE.match(line) for line in text.splitlines()]
    raw_matches = [match.group(1) for match in matches if match]

    if len(raw_matches) != 1:
        errors.append(".spi.yml must declare exactly one inline documentation_targets list")
        return [], errors

    targets: list[str] = []
    for raw_target in raw_matches[0].split(","):
        target = raw_target.strip().strip("\"'")
        if not target:
            errors.append(".spi.yml documentation_targets must not contain empty entries")
            continue
        if not TARGET_NAME_RE.fullmatch(target):
            errors.append(f".spi.yml documentation target has invalid target name: {target}")
            continue
        targets.append(target)

    return targets, errors


def parse_version(text: str) -> str | None:
    for line in text.splitlines():
        match = VERSION_RE.match(line)
        if match:
            return match.group(1)
    return None


def validate(root: pathlib.Path, manifest_path: pathlib.Path) -> list[str]:
    errors: list[str] = []
    if not manifest_path.exists():
        return [f"{manifest_path}: missing Swift Package Index manifest"]

    text = manifest_path.read_text(encoding="utf-8")
    if "\t" in text:
        errors.append(".spi.yml must use spaces, not tabs")

    version = parse_version(text)
    if version != EXPECTED_VERSION:
        errors.append(f".spi.yml version must be {EXPECTED_VERSION}")

    if "builder:" not in text:
        errors.append(".spi.yml must contain a builder section")
    if "configs:" not in text:
        errors.append(".spi.yml must contain builder configs")

    documentation_targets, parse_errors = parse_documentation_targets(text)
    errors.extend(parse_errors)
    if documentation_targets != EXPECTED_DOCUMENTATION_TARGETS:
        errors.append(
            ".spi.yml documentation_targets must be "
            f"{EXPECTED_DOCUMENTATION_TARGETS}, got {documentation_targets}"
        )

    known_targets = package_targets(root)
    for target in documentation_targets:
        if target not in known_targets:
            errors.append(f".spi.yml documentation target does not exist in Package.swift: {target}")

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
    errors = validate(root, root / ".spi.yml")
    if errors:
        print("Swift Package Index manifest validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Swift Package Index manifest validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
