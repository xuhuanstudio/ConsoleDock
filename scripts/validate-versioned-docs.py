#!/usr/bin/env python3
"""Validate public docs describe released APIs without stale main-only warnings."""

from __future__ import annotations

import argparse
import pathlib
import sys
import tempfile


REQUIRED_SNIPPETS = {
    "README.md": [
        "ConsoleDock `v0.8.0` is the current source-first Swift Package Manager preview release.",
        "Use the latest release tag from GitHub Releases. `v0.8.0` includes local Debug Action execution history, session-only recent parameter values for action forms, reproduction timeline issue reports, temporary `.txt` issue-report sharing, parameterized Debug Actions, App Context snapshots for issue reports and the bundled Context tab, configurable floating trigger controls, Logs jump actions, Actions search, logger forwarders for existing logger sinks, Test Session Reports, manual markers, Debug Actions, log detail, explicit visible/all/issue-report sharing and copying, runtime diagnostics, and release-validation hardening.",
        "Floating trigger configuration is available in `v0.6.0` and later.",
        "Logger forwarders are available in `v0.5.0` and later.",
        "Runtime diagnostics are available in `v0.2.0` and later.",
        "Debug Actions are available in `v0.3.0` and later.",
        "Parameterized Debug Actions and App Context are available in `v0.7.0` and later.",
        "Local Debug Action execution history and reproduction timeline issue reports are available in `v0.8.0` and later.",
        "Test Session Reports are available in `v0.4.0` and later.",
    ],
    "README.zh-CN.md": [
        "ConsoleDock `v0.8.0` 是当前 source-first Swift Package Manager 公开预览版本",
        "通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`v0.8.0` 已包含 local Debug Action execution history、action form session-only 最近参数值复用、reproduction timeline issue reports、临时 `.txt` issue-report 分享、parameterized Debug Actions、App Context、可配置 floating trigger、Logs Jump、Actions 搜索、logger forwarders、Test Session Reports、manual markers、Debug Actions、日志详情、visible/all/issue-report 分享和复制、runtime diagnostics 和当前 release validation 加固：",
        "Floating trigger 配置从 `v0.6.0` 开始属于已发布能力。",
        "`v0.5.0` 开始提供的 `ConsoleDock.LogForwarder` / `CDKLogForwarder` 就是为这个迁移路径准备的轻量工具。",
        "Runtime diagnostics 从 `v0.2.0` 开始属于已发布能力。",
        "Debug Actions 从 `v0.3.0` 开始属于已发布能力。",
        "Parameterized Debug Actions 和 App Context 从 `v0.7.0` 开始属于已发布能力。",
        "Local Debug Action execution history 和 reproduction timeline issue reports 从 `v0.8.0` 开始属于已发布能力。",
        "Test Session Reports 从 `v0.4.0` 开始属于已发布能力。",
    ],
}

DENIED_SNIPPETS = {
    "README.md": [
        "Runtime diagnostics are available on `main` after `v0.1.0`",
        "Debug Actions are available on `main`",
        "Parameterized Debug Actions are available on `main`",
        "upcoming `v0.3.0`",
        "skip this section until the next tag ships",
    ],
    "README.zh-CN.md": [
        "Runtime diagnostics 是 `v0.1.0` 之后在 `main` 上新增的能力",
        "Debug Actions 是 `main`",
        "Parameterized Debug Actions 是 `main`",
        "为后续 `v0.3.0`",
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
    english_required = "\n".join(REQUIRED_SNIPPETS["README.md"])
    chinese_required = "\n".join(REQUIRED_SNIPPETS["README.zh-CN.md"])
    english = f"""# ConsoleDock

{english_required}

### Check Runtime Diagnostics

Use `ConsoleDock.diagnostics` here.

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
```

### Start In Objective-C

Objective-C setup starts here.
"""
    chinese = f"""# ConsoleDock

{chinese_required}

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
            errors.append("validate should accept docs with released v0.8.0 guidance")

        missing_snippet_root = root / "missing-snippet"
        missing_snippet_root.mkdir()
        write_valid_docs(missing_snippet_root)
        readme = missing_snippet_root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8").replace(REQUIRED_SNIPPETS["README.md"][1], ""),
            encoding="utf-8",
        )
        if not validate(missing_snippet_root):
            errors.append("validate should reject docs without the required released-version snippets")

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
