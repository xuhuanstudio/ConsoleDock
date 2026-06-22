#!/usr/bin/env python3
"""Validate ConsoleDock's Swift Package identity and public product shape."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
from typing import Any


EXPECTED_TOOLS_VERSION = "5.9"
EXPECTED_PACKAGE_NAME = "ConsoleDock"
EXPECTED_PLATFORMS = {
    "ios": "12.0",
    "macos": "12.0",
}
EXPECTED_PRODUCTS = {
    "ConsoleDock": ["ConsoleDock"],
    "ConsoleDockCore": ["ConsoleDockCore"],
}
EXPECTED_TARGETS = {
    "ConsoleDockCore": {
        "type": "regular",
        "dependencies": [],
    },
    "ConsoleDock": {
        "type": "regular",
        "dependencies": ["ConsoleDockCore"],
    },
    "ConsoleDockCoreTests": {
        "type": "test",
        "dependencies": ["ConsoleDockCore"],
    },
    "ConsoleDockTests": {
        "type": "test",
        "dependencies": ["ConsoleDock", "ConsoleDockCore"],
    },
}


def package_manifest(root: pathlib.Path) -> dict[str, Any]:
    output = subprocess.check_output(["swift", "package", "dump-package"], cwd=root)
    return json.loads(output)


def tools_version(root: pathlib.Path) -> str | None:
    package_swift = root / "Package.swift"
    first_line = package_swift.read_text(encoding="utf-8").splitlines()[0]
    match = re.fullmatch(r"// swift-tools-version:\s*([0-9]+(?:\.[0-9]+)*)", first_line.strip())
    if match is None:
        return None
    return match.group(1)


def dependency_name(dependency: dict[str, Any]) -> str | None:
    by_name = dependency.get("byName")
    if isinstance(by_name, list) and by_name:
        return by_name[0]
    return None


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    manifest = package_manifest(root)

    actual_tools_version = tools_version(root)
    if actual_tools_version != EXPECTED_TOOLS_VERSION:
        errors.append(f"Package.swift tools version must be {EXPECTED_TOOLS_VERSION}, got {actual_tools_version}")

    if manifest.get("name") != EXPECTED_PACKAGE_NAME:
        errors.append(f"package name must be {EXPECTED_PACKAGE_NAME}, got {manifest.get('name')}")

    if manifest.get("dependencies"):
        errors.append("package must not introduce external package dependencies for the source-first MVP")

    platforms = {platform["platformName"]: platform["version"] for platform in manifest.get("platforms", [])}
    if platforms != EXPECTED_PLATFORMS:
        errors.append(f"platforms must be {EXPECTED_PLATFORMS}, got {platforms}")

    products = {product["name"]: product for product in manifest.get("products", [])}
    if set(products) != set(EXPECTED_PRODUCTS):
        errors.append(f"products must be {sorted(EXPECTED_PRODUCTS)}, got {sorted(products)}")
    for product_name, expected_targets in EXPECTED_PRODUCTS.items():
        product = products.get(product_name)
        if product is None:
            continue
        product_type = product.get("type")
        if product_type != {"library": ["automatic"]}:
            errors.append(f"{product_name} must be an automatic library product, got {product_type}")
        if product.get("targets") != expected_targets:
            errors.append(f"{product_name} product targets must be {expected_targets}, got {product.get('targets')}")

    targets = {target["name"]: target for target in manifest.get("targets", [])}
    if set(targets) != set(EXPECTED_TARGETS):
        errors.append(f"targets must be {sorted(EXPECTED_TARGETS)}, got {sorted(targets)}")
    for target_name, expected in EXPECTED_TARGETS.items():
        target = targets.get(target_name)
        if target is None:
            continue
        if target.get("type") != expected["type"]:
            errors.append(f"{target_name} target type must be {expected['type']}, got {target.get('type')}")
        dependencies = [name for name in (dependency_name(item) for item in target.get("dependencies", [])) if name]
        if dependencies != expected["dependencies"]:
            errors.append(f"{target_name} dependencies must be {expected['dependencies']}, got {dependencies}")

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
        print("Package identity validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Package identity validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
