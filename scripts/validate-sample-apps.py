#!/usr/bin/env python3
"""Validate sample app documentation and UI smoke automation stay in sync."""

from __future__ import annotations

import os
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj/xcshareddata/xcschemes/SwiftSampleApp.xcscheme",
    "Examples/SwiftSampleApp/SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests.swift",
    "Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj/xcshareddata/xcschemes/ObjCSampleApp.xcscheme",
    "Examples/ObjCSampleApp/ObjCSampleAppUITests/ConsoleDockObjCSampleUITests.swift",
    "scripts/validate-swift-sample-ui-smoke.sh",
    "scripts/validate-objc-sample-ui-smoke.sh",
]

EXECUTABLE_SCRIPTS = [
    "scripts/validate-swift-sample-ui-smoke.sh",
    "scripts/validate-objc-sample-ui-smoke.sh",
]

REQUIRED_SNIPPETS = {
    "Examples/SwiftSampleApp/README.md": [
        "scripts/validate-swift-sample-ui-smoke.sh",
        "`--consoledock-ui-smoke`",
        "CONSOLEDOCK_UI_SMOKE_DESTINATION",
        "ConsoleDock.LogForwarder",
        "structured Logs search",
        "level filtering",
        "Logs jump controls",
        "log detail",
        "markers",
        "Timeline rows and detail navigation",
        "issue report sharing",
        "Debug Actions",
        "Actions search",
        "parameterized Debug Actions",
        "session-only recent parameter values",
        "local action execution history",
        "Session Timeline building",
        "reproduction timeline",
        "App Context tab refresh",
        "Floating trigger controls",
    ],
    "Examples/ObjCSampleApp/README.md": [
        "scripts/validate-objc-sample-ui-smoke.sh",
        "`--consoledock-ui-smoke`",
        "CONSOLEDOCK_UI_SMOKE_DESTINATION",
        "CDKLogForwarder",
        "structured Logs search",
        "level filtering",
        "Logs jump controls",
        "log detail",
        "markers",
        "Timeline rows and detail navigation",
        "issue report sharing",
        "Debug Actions",
        "Actions search",
        "parameterized Debug Actions",
        "session-only recent parameter values",
        "local action execution history",
        "Session Timeline building",
        "reproduction timeline",
        "App Context tab refresh",
        "Floating trigger controls",
    ],
    "docs/sample-app-walkthrough.md": [
        "scripts/validate-swift-sample-ui-smoke.sh",
        "scripts/validate-objc-sample-ui-smoke.sh",
        "native-log-only UI automation mode",
        "structured Logs search",
        "level filtering",
        "Logs jump controls",
        "log detail",
        "marker creation",
        "Timeline rows and detail navigation",
        "issue-report share action availability",
        "issue-report copy action availability",
        "Debug Actions",
        "Actions search",
        "parameterized Debug Actions",
        "session-only recent parameter values",
        "local structured query parsing",
        "local Session Timeline building",
        "local action execution history",
        "reproduction timeline",
        "App Context tab refresh",
        "logger forwarder sink",
    ],
    "Examples/SwiftSampleApp/SwiftSampleApp/MainViewController.swift": [
        "ConsoleDock.LogForwarder(category:",
    ],
    "Examples/SwiftSampleApp/SwiftSampleApp/AppDelegate.swift": [
        "style: .destructive",
        "isEnabled: false",
        "floatingButtonPosition: .bottomLeading",
        "ConsoleDock.setAppContextProvider",
        "id: \"orderId\"",
    ],
    "Examples/ObjCSampleApp/ObjCSampleApp/MainViewController.m": [
        "CDKLogForwarder *SampleAppLogForwarder",
    ],
    "Examples/ObjCSampleApp/ObjCSampleApp/AppDelegate.m": [
        "CDKDebugActionStyleDestructive",
        "isEnabled:NO",
        "CDKFloatingButtonPositionBottomLeading",
        "setAppContextProvider",
        "stringParameterWithIdentifier:@\"orderId\"",
    ],
    "scripts/validate-release.sh": [
        "scripts/validate-swift-sample-ui-smoke.sh",
        "scripts/validate-objc-sample-ui-smoke.sh",
        "CONSOLEDOCK_RUN_UI_SMOKE",
    ],
    "Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj/project.pbxproj": [
        "SwiftSampleAppUITests",
        "ConsoleDockSwiftSampleUITests.swift",
    ],
    "Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj/project.pbxproj": [
        "ObjCSampleAppUITests",
        "ConsoleDockObjCSampleUITests.swift",
    ],
}


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        path = ROOT / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required sample app file is missing")

    for relative_path in EXECUTABLE_SCRIPTS:
        path = ROOT / relative_path
        if path.exists() and not os.access(path, os.X_OK):
            errors.append(f"{relative_path}: smoke validation script is not executable")

    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required sample app document is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required sample app snippet: {snippet}")

    if errors:
        print("Sample app validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Sample app validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
