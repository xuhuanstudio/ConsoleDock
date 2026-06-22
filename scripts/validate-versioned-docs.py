#!/usr/bin/env python3
"""Validate public docs describe v0.2.0 released APIs without stale main-only warnings."""

from __future__ import annotations

import argparse
import pathlib
import sys
import tempfile


REQUIRED_SNIPPETS = {
    "README.md": [
        "Use the latest release tag from GitHub Releases. `v0.2.0` includes runtime diagnostics and the current release-validation hardening.",
        "Runtime diagnostics are available in `v0.2.0` and later.",
    ],
    "README.zh-CN.md": [
        "通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`v0.2.0` 已包含 runtime diagnostics 和当前 release validation 加固：",
        "Runtime diagnostics 从 `v0.2.0` 开始属于已发布能力。",
    ],
}

DENIED_SNIPPETS = {
    "README.md": [
        "Runtime diagnostics are available on `main` after `v0.1.0`",
        "skip this section until the next tag ships",
    ],
    "README.zh-CN.md": [
        "Runtime diagnostics 是 `v0.1.0` 之后在 `main` 上新增的能力",
        "等下一个 tag 发布后再使用这些符号",
    ],
}


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

        for snippet in DENIED_SNIPPETS.get(relative_path, []):
            if snippet in text:
                errors.append(f"{relative_path}: stale main-only version warning remains: {snippet}")

    return errors


def write_valid_docs(root: pathlib.Path) -> None:
    english = f"""# ConsoleDock

{REQUIRED_SNIPPETS["README.md"][0]}
{REQUIRED_SNIPPETS["README.md"][1]}

### Check Runtime Diagnostics

Use `ConsoleDock.diagnostics` here.

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
```

### Start In Objective-C

Objective-C setup starts here.
"""
    chinese = f"""# ConsoleDock

{REQUIRED_SNIPPETS["README.zh-CN.md"][0]}
{REQUIRED_SNIPPETS["README.zh-CN.md"][1]}

## 运行诊断

这里可以使用 `ConsoleDock.diagnostics`。

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
```

## Objective-C 快速开始

Objective-C 接入从这里开始。
"""
    (root / "README.md").write_text(english, encoding="utf-8")
    (root / "README.zh-CN.md").write_text(chinese, encoding="utf-8")


def self_test() -> list[str]:
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="consoledock-versioned-docs-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        write_valid_docs(root)
        if validate(root):
            errors.append("validate should accept docs with v0.2.0 released diagnostics guidance")

        missing_snippet_root = root / "missing-snippet"
        missing_snippet_root.mkdir()
        write_valid_docs(missing_snippet_root)
        readme = missing_snippet_root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8").replace(REQUIRED_SNIPPETS["README.md"][1], ""),
            encoding="utf-8",
        )
        if not validate(missing_snippet_root):
            errors.append("validate should reject docs without the required v0.2.0 snippets")

        stale_warning_root = root / "stale-warning"
        stale_warning_root.mkdir()
        write_valid_docs(stale_warning_root)
        readme = stale_warning_root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8")
            + "\nRuntime diagnostics are available on `main` after `v0.1.0`.\n",
            encoding="utf-8",
        )
        if not validate(stale_warning_root):
            errors.append("validate should reject stale main-only diagnostics warnings")

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
    parser.add_argument("--self-test", action="store_true", help="Run local validator self-tests.")
    args = parser.parse_args()

    if args.self_test:
        errors = self_test()
        if errors:
            print("Versioned documentation validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Versioned documentation validator self-test passed.")
        return 0

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
