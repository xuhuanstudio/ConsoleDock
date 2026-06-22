#!/usr/bin/env python3
"""Validate public docs keep released-tag guidance separate from main-only APIs."""

from __future__ import annotations

import argparse
import pathlib
import sys


MAIN_ONLY_API_TOKENS = [
    "ConsoleDock.diagnostics",
    "CDKDiagnostics",
    "diagnosticsDidChangeNotification",
]

REQUIRED_SNIPPETS = {
    "README.md": [
        "Runtime diagnostics are available on `main` after `v0.1.0` and will be included in the next release tag.",
        "If your package dependency is pinned to `v0.1.0`, skip this section until the next tag ships.",
    ],
    "README.zh-CN.md": [
        "Runtime diagnostics 是 `v0.1.0` 之后在 `main` 上新增的能力，会进入下一个 release tag。",
        "如果你的依赖固定在 `v0.1.0`，请先跳过本节，等下一个 tag 发布后再使用这些符号。",
    ],
}

MAIN_ONLY_API_SECTIONS = {
    "README.md": ("### Check Runtime Diagnostics", "### Start In Objective-C"),
    "README.zh-CN.md": ("## 运行诊断", "## Objective-C 快速开始"),
}


def line_number_for_offset(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def allowed_section_range(text: str, start_heading: str, end_heading: str) -> tuple[int, int] | None:
    start = text.find(start_heading)
    if start == -1:
        return None

    end = text.find(end_heading, start + len(start_heading))
    if end == -1:
        return None

    return start, end


def find_token_offsets(text: str, token: str) -> list[int]:
    offsets: list[int] = []
    start = 0
    while True:
        offset = text.find(token, start)
        if offset == -1:
            return offsets
        offsets.append(offset)
        start = offset + len(token)


def validate_main_only_api_tokens(
    relative_path: str,
    text: str,
    errors: list[str],
) -> None:
    section = MAIN_ONLY_API_SECTIONS.get(relative_path)
    if section is None:
        return

    allowed_range = allowed_section_range(text, *section)
    if allowed_range is None:
        errors.append(f"{relative_path}: missing main-only API section bounded by {section[0]} and {section[1]}")
        return

    allowed_start, allowed_end = allowed_range
    for token in MAIN_ONLY_API_TOKENS:
        for offset in find_token_offsets(text, token):
            if not (allowed_start <= offset < allowed_end):
                line_number = line_number_for_offset(text, offset)
                errors.append(
                    f"{relative_path}:{line_number}: main-only API token `{token}` must stay inside the guarded diagnostics section"
                )


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required public documentation is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required versioned-doc snippet: {snippet}")

        validate_main_only_api_tokens(relative_path, text, errors)

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

    errors = validate(args.root.resolve())
    if errors:
        print("Versioned documentation validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Versioned documentation validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
