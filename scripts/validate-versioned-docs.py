#!/usr/bin/env python3
"""Validate public docs describe released APIs without stale main-only warnings."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile


VERSION_HEADING_RE = re.compile(r"^## (v\d+\.\d+\.\d+)\b", re.MULTILINE)

CURRENT_RELEASE_SNIPPETS = {
    "README.md": [
        "ConsoleDock `{tag}` is the current source-first Swift Package Manager preview release.",
        "Use the latest release tag from GitHub Releases. `{tag}` includes",
    ],
    "README.zh-CN.md": [
        "ConsoleDock `{tag}` 是当前 source-first Swift Package Manager 公开预览版本",
        "通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`{tag}` 已包含",
    ],
}

FEATURE_SNIPPETS = {
    "README.md": [
        "Support Reports are available in `v0.14.0` and later.",
        "Integration Diagnosis is available in `v0.13.0` and later.",
        "Local Session Archive is available in `v0.11.0` and later.",
        "Session Timeline is available in `v0.10.0` and later.",
        "Local structured Logs queries are available in `v0.9.0` and later.",
        "Floating trigger configuration is available in `v0.6.0` and later.",
        "Logger forwarders are available in `v0.5.0` and later.",
        "Runtime diagnostics are available in `v0.2.0` and later.",
        "Debug Actions are available in `v0.3.0` and later.",
        "Parameterized Debug Actions and App Context are available in `v0.7.0` and later.",
        "Local Debug Action execution history and reproduction timeline issue reports are available in `v0.8.0` and later.",
        "Test Session Reports are available in `v0.4.0` and later.",
    ],
    "README.zh-CN.md": [
        "Support Report 从 `v0.14.0` 开始属于已发布能力。",
        "Integration Diagnosis 从 `v0.13.0` 开始属于已发布能力。",
        "Local Session Archive 从 `v0.11.0` 开始属于已发布能力。",
        "Session Timeline 从 `v0.10.0` 开始属于已发布能力。",
        "Logs 本地结构化查询从 `v0.9.0` 开始属于已发布能力。",
        "Floating trigger 配置从 `v0.6.0` 开始属于已发布能力。",
        "`v0.5.0` 开始提供的 `ConsoleDock.LogForwarder` / `CDKLogForwarder` 就是为这个迁移路径准备的轻量工具。",
        "Runtime diagnostics 从 `v0.2.0` 开始属于已发布能力。",
        "Debug Actions 从 `v0.3.0` 开始属于已发布能力。",
        "Parameterized Debug Actions 和 App Context 从 `v0.7.0` 开始属于已发布能力。",
        "Local Debug Action execution history 和 reproduction timeline issue reports 从 `v0.8.0` 开始属于已发布能力。",
        "Test Session Reports 从 `v0.4.0` 开始属于已发布能力。",
    ],
}

STATIC_DENIED_SNIPPETS = {
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


def released_tags(root: pathlib.Path) -> list[str]:
    changelog = root / "CHANGELOG.md"
    if not changelog.exists():
        return ["v0.14.0"]
    return VERSION_HEADING_RE.findall(changelog.read_text(encoding="utf-8")) or ["v0.14.0"]


def current_release_tag(root: pathlib.Path) -> str:
    return released_tags(root)[0]


def required_snippets(root: pathlib.Path) -> dict[str, list[str]]:
    tag = current_release_tag(root)
    required: dict[str, list[str]] = {}
    for path, snippets in CURRENT_RELEASE_SNIPPETS.items():
        required[path] = [snippet.format(tag=tag) for snippet in snippets]
    for path, snippets in FEATURE_SNIPPETS.items():
        required.setdefault(path, []).extend(snippets)
    return required


def denied_snippets(root: pathlib.Path) -> dict[str, list[str]]:
    current_tag = current_release_tag(root)
    previous_tags = [tag for tag in released_tags(root) if tag != current_tag]
    denied: dict[str, list[str]] = {path: list(snippets) for path, snippets in STATIC_DENIED_SNIPPETS.items()}
    for tag in previous_tags:
        denied.setdefault("README.md", []).extend(
            [
                f"ConsoleDock `{tag}` is the current source-first Swift Package Manager preview release.",
                f"Use the latest release tag from GitHub Releases. `{tag}` includes",
            ]
        )
        denied.setdefault("README.zh-CN.md", []).extend(
            [
                f"ConsoleDock `{tag}` 是当前 source-first Swift Package Manager 公开预览版本",
                f"通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`{tag}` 已包含",
            ]
        )
    return denied


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    required = required_snippets(root)
    denied = denied_snippets(root)
    for relative_path, snippets in required.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required public documentation is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required versioned-doc snippet: {snippet}")

        for snippet in denied.get(relative_path, []):
            if snippet in text:
                errors.append(f"{relative_path}: stale main-only version warning remains: {snippet}")

    return errors


def write_valid_docs(root: pathlib.Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    (root / "CHANGELOG.md").write_text(
        "## Unreleased\n\nNo changes yet.\n\n## v0.14.0 - 2026-06-27\n\n- Released.\n",
        encoding="utf-8",
    )
    required = required_snippets(root)
    english_required = "\n".join(required["README.md"])
    chinese_required = "\n".join(required["README.zh-CN.md"])
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
            errors.append("validate should accept docs with released v0.14.0 guidance")

        missing_snippet_root = root / "missing-snippet"
        missing_snippet_root.mkdir()
        write_valid_docs(missing_snippet_root)
        readme = missing_snippet_root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8").replace(required_snippets(missing_snippet_root)["README.md"][1], ""),
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

        stale_release_root = root / "stale-release"
        write_valid_docs(stale_release_root)
        (stale_release_root / "CHANGELOG.md").write_text(
            "## Unreleased\n\nNo changes yet.\n\n"
            "## v0.15.0 - 2026-06-28\n\n- Released.\n\n"
            "## v0.14.0 - 2026-06-27\n\n- Released.\n",
            encoding="utf-8",
        )
        if not validate(stale_release_root):
            errors.append("validate should reject docs that keep an older current release tag")

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
