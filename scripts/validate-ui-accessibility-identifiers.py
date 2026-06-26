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
        "consoledock.share-issue-report",
        "consoledock.copy-issue-report",
        "consoledock.save-session-archive",
        "consoledock.saved-session-archives",
        "consoledock.session-archives.table",
        "consoledock.session-archives.empty",
        "consoledock.session-archives.clear-all",
        "consoledock.session-archives.confirm-clear",
        "consoledock.session-archives.cancel-clear",
        "consoledock.session-archive-detail.text",
        "consoledock.session-archive-detail.copy",
        "consoledock.session-archive-detail.share",
        "consoledock.session-archive-detail.delete",
        "consoledock.session-archive-detail.confirm-delete",
        "consoledock.session-archive-detail.cancel-delete",
        "consoledock.mark",
        "consoledock.marker-text",
        "consoledock.add-marker",
        "consoledock.clear",
        "consoledock.jump",
        "consoledock.jump-latest-log",
        "consoledock.jump-first-error",
        "consoledock.jump-previous-error",
        "consoledock.jump-next-error",
        "consoledock.pause-live",
        "consoledock.resume-live",
        "consoledock.search",
        "consoledock.actions-search",
        "consoledock.level-filter",
        "consoledock.status",
        "consoledock.entries-table",
        "consoledock.empty-state",
        "consoledock.mode-control",
        "consoledock.timeline-table",
        "consoledock.timeline-empty-state",
        "consoledock.timeline-refresh",
        "consoledock.timeline-action-detail.text",
        "consoledock.timeline-action-detail.copy",
        "consoledock.actions-table",
        "consoledock.context-table",
        "consoledock.context-refresh",
        "consoledock.entry-detail.message",
        "consoledock.copy-message",
        "consoledock.copy-entry",
        "consoledock.confirm-action",
        "consoledock.cancel-action",
        "consoledock.action-parameters.form",
        "consoledock.action-parameters.run",
        "consoledock.action-parameters.cancel",
        "consoledock.action-parameters.error",
        "consoledock.action-parameters.string",
        "consoledock.action-parameters.number",
        "consoledock.action-parameters.bool",
        "consoledock.action-parameters.choice",
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
