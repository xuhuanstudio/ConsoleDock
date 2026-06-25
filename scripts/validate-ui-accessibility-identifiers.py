#!/usr/bin/env python3
"""Validate stable accessibility identifiers used by UI smoke automation."""

from __future__ import annotations

import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]

REQUIRED_IDENTIFIERS = {
    pathlib.Path("Sources/ConsoleDock/ConsoleDockUIShared.swift"): [
        "consoledock.dock-button",
        "consoledock.close",
        "consoledock.share",
        "consoledock.share-visible-logs",
        "consoledock.share-all-logs",
        "consoledock.clear",
        "consoledock.pause-live",
        "consoledock.resume-live",
        "consoledock.search",
        "consoledock.level-filter",
        "consoledock.status",
        "consoledock.entries-table",
        "consoledock.empty-state",
        "consoledock.mode-control",
        "consoledock.actions-table",
        "consoledock.entry-detail.message",
        "consoledock.copy-message",
        "consoledock.copy-entry",
        "consoledock.confirm-action",
        "consoledock.cancel-action",
    ],
    pathlib.Path("Examples/SwiftSampleApp/SwiftSampleApp/MainViewController.swift"): [
        "swift-sample.",
        "swift-sample.status",
    ],
    pathlib.Path("Examples/ObjCSampleApp/ObjCSampleApp/MainViewController.m"): [
        "objc-sample.",
        "objc-sample.status",
    ],
}


def main() -> int:
    errors: list[str] = []
    for relative_path, identifiers in REQUIRED_IDENTIFIERS.items():
        path = ROOT / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: missing file")
            continue
        text = path.read_text(encoding="utf-8")
        for identifier in identifiers:
            if identifier not in text:
                errors.append(f"{relative_path}: missing accessibility identifier {identifier!r}")

    if errors:
        print("UI accessibility identifier validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("UI accessibility identifier validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
