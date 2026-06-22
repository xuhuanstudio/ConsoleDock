#!/usr/bin/env python3
"""Validate distribution-channel documentation and shipped artifacts stay honest."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys
import tempfile


REQUIRED_SNIPPETS = {
    "docs/distribution-strategy.md": [
        "SPM is the only supported public distribution channel today.",
        "No CocoaPods podspec is shipped yet.",
        "CocoaPods is not an active release target.",
        "No XCFramework artifact is shipped yet.",
        "XCFramework is not an active release target.",
        "demand-driven compatibility options, not active release targets",
        "Release startup remains gated by both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`",
        "no default network upload, no default disk persistence, and no private API",
        "Distribution validation also rejects tracked CocoaPods podspecs",
        "Avoid these claims until they are true and validated",
    ],
    "README.md": [
        "For distribution channel boundaries, see [Distribution strategy](docs/distribution-strategy.md).",
        "distribution documentation and artifacts",
        "Demand-driven compatibility channels, not active release targets",
        "CocoaPods only if real older Objective-C or mixed projects cannot adopt the Swift Package.",
        "XCFramework only if binary consumers need it after the public API is stable.",
    ],
    "README.zh-CN.md": [
        "分发策略",
        "当前唯一支持的公开分发渠道",
        "CocoaPods 和 XCFramework 不是当前主动发布目标",
    ],
    "docs/open-source-readiness.md": [
        "[Distribution strategy](distribution-strategy.md)",
        "CocoaPods support is not an active release target.",
        "XCFramework support is not an active release target.",
    ],
    "docs/release-process.md": [
        "distribution strategy",
        "CocoaPods and XCFramework artifacts remain unsupported demand-driven channels",
    ],
    "docs/roadmap.md": [
        "Demand-Driven Compatibility Candidates",
        "CocoaPods compatibility evaluation",
        "documented decision to keep CocoaPods and XCFramework out of scope unless real consumer demand justifies them",
    ],
}

FORBIDDEN_PATTERNS = {
    "README.md": [
        re.compile(r"\bpod\s+['\"]ConsoleDock", re.IGNORECASE),
        re.compile(r"\bCocoaPods\s+supported\b", re.IGNORECASE),
        re.compile(r"\bDownload the XCFramework\b", re.IGNORECASE),
        re.compile(r"\bSecondary distribution after the SPM package is stable\b", re.IGNORECASE),
    ],
    "README.zh-CN.md": [
        re.compile(r"\bpod\s+['\"]ConsoleDock", re.IGNORECASE),
        re.compile(r"已支持\s*CocoaPods", re.IGNORECASE),
        re.compile(r"下载\s*XCFramework", re.IGNORECASE),
        re.compile(r"CocoaPods，等 SPM package 稳定后再考虑", re.IGNORECASE),
        re.compile(r"XCFramework，等公开 API 稳定后再考虑", re.IGNORECASE),
    ],
    "docs/distribution-strategy.md": [
        re.compile(r"Planned compatibility channel", re.IGNORECASE),
        re.compile(r"Planned binary distribution channel", re.IGNORECASE),
    ],
}

DENIED_TRACKED_ARTIFACT_PATTERNS = [
    (
        "CocoaPods podspec",
        re.compile(r"(^|/)[^/]+\.podspec(?:\.json)?$", re.IGNORECASE),
    ),
    (
        "CocoaPods install output",
        re.compile(r"(^|/)Pods(/|$)"),
    ),
    (
        "SwiftPM lock file",
        re.compile(r"(^|/)Package\.resolved$"),
    ),
    (
        "XCFramework artifact",
        re.compile(r"(^|/)[^/]+\.xcframework(/|$)", re.IGNORECASE),
    ),
    (
        "Apple framework artifact",
        re.compile(r"(^|/)[^/]+\.framework(/|$)", re.IGNORECASE),
    ),
    (
        "Xcode archive artifact",
        re.compile(r"(^|/)[^/]+\.xcarchive(/|$)", re.IGNORECASE),
    ),
    (
        "debug symbol artifact",
        re.compile(r"(^|/)[^/]+\.dSYM(/|$)", re.IGNORECASE),
    ),
    (
        "static library artifact",
        re.compile(r"(^|/)[^/]+\.a$", re.IGNORECASE),
    ),
    (
        "packaged binary/archive artifact",
        re.compile(r"(^|/)[^/]+\.(?:zip|tar|tgz|gz|dmg|pkg)$", re.IGNORECASE),
    ),
]


def tracked_files(root: pathlib.Path) -> list[str]:
    output = subprocess.check_output(["git", "ls-files", "-z"], cwd=root)
    return sorted(path.decode("utf-8") for path in output.split(b"\0") if path)


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        if not path.exists():
            errors.append(f"{relative_path}: required distribution document is missing")
            continue

        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{relative_path}: missing required distribution snippet: {snippet}")

        for pattern in FORBIDDEN_PATTERNS.get(relative_path, []):
            if pattern.search(text):
                errors.append(f"{relative_path}: contains premature distribution claim matching {pattern.pattern}")

    for relative_path in tracked_files(root):
        for label, pattern in DENIED_TRACKED_ARTIFACT_PATTERNS:
            if pattern.search(relative_path):
                errors.append(
                    f"{relative_path}: tracked {label} conflicts with current SPM-only distribution policy"
                )

    return errors


def run_git(root: pathlib.Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def write_valid_distribution_docs(root: pathlib.Path) -> None:
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("\n".join(snippets) + "\n", encoding="utf-8")


def write_tracked_fixture(root: pathlib.Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    run_git(root, "init")
    write_valid_distribution_docs(root)
    run_git(root, "add", ".")


def self_test() -> list[str]:
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="consoledock-distribution-docs-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        write_tracked_fixture(root)
        if validate(root):
            errors.append("validate should accept the current SPM-only distribution documentation policy")

        missing_snippet_root = root / "missing-snippet"
        write_tracked_fixture(missing_snippet_root)
        strategy = missing_snippet_root / "docs/distribution-strategy.md"
        strategy.write_text(
            strategy.read_text(encoding="utf-8").replace(REQUIRED_SNIPPETS["docs/distribution-strategy.md"][0], ""),
            encoding="utf-8",
        )
        if not validate(missing_snippet_root):
            errors.append("validate should reject missing required distribution policy snippets")

        premature_claim_root = root / "premature-claim"
        write_tracked_fixture(premature_claim_root)
        readme = premature_claim_root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8") + "\npod 'ConsoleDock'\nCocoaPods supported\n",
            encoding="utf-8",
        )
        if not validate(premature_claim_root):
            errors.append("validate should reject premature CocoaPods support claims")

        tracked_artifact_root = root / "tracked-artifact"
        write_tracked_fixture(tracked_artifact_root)
        podspec = tracked_artifact_root / "ConsoleDock.podspec"
        podspec.write_text("Pod::Spec.new do |spec|\nend\n", encoding="utf-8")
        run_git(tracked_artifact_root, "add", "ConsoleDock.podspec")
        if not validate(tracked_artifact_root):
            errors.append("validate should reject tracked future distribution artifacts")

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
            print("Distribution validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Distribution validator self-test passed.")
        return 0

    root = args.root.resolve()
    errors = validate(root)
    if errors:
        print("Distribution validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Distribution validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
