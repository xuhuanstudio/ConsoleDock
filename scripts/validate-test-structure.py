#!/usr/bin/env python3
"""Validate focused test file structure for the Swift facade target."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile


TEST_ROOT = pathlib.Path("Tests/ConsoleDockTests")
REMOVED_MONOLITH = TEST_ROOT / "ConsoleDockTests.swift"
MAX_TEST_FILE_LINES = 800
MIN_TEST_METHODS = 120

REQUIRED_FILES = {
    "ConsoleDockTestCase.swift",
    "ConsoleDockFacadeTests.swift",
    "ConsoleDockSnapshotTimelineTests.swift",
    "ConsoleDockReportTests.swift",
    "ConsoleDockFilteringTests.swift",
    "ConsoleDockIntegrationContextTests.swift",
    "ConsoleDockDebugActionTests.swift",
    "ConsoleDockObserverArchiveTests.swift",
}

TEST_CLASS_RE = re.compile(r"final\s+class\s+(\w+Tests)\s*:\s*(\w+)")
TEST_METHOD_RE = re.compile(r"^\s+func\s+test\w+\(", re.MULTILINE)


def line_count(path: pathlib.Path) -> int:
    return len(path.read_text(encoding="utf-8").splitlines())


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    test_root = root / TEST_ROOT
    if not test_root.exists():
        return [f"{TEST_ROOT}: missing test directory"]

    present_files = {path.name for path in test_root.glob("*.swift")}
    missing = sorted(REQUIRED_FILES - present_files)
    if missing:
        errors.append(f"{TEST_ROOT}: missing focused test files: {', '.join(missing)}")

    if (root / REMOVED_MONOLITH).exists():
        errors.append(f"{REMOVED_MONOLITH}: split focused tests must not regress to the old monolithic file")

    test_method_count = 0
    for path in sorted(test_root.glob("*.swift")):
        text = path.read_text(encoding="utf-8")
        if path.name != "ConsoleDockTestCase.swift":
            count = line_count(path)
            if count > MAX_TEST_FILE_LINES:
                errors.append(f"{path.relative_to(root)}: {count} lines exceeds limit {MAX_TEST_FILE_LINES}")

            class_match = TEST_CLASS_RE.search(text)
            if class_match is None:
                errors.append(f"{path.relative_to(root)}: focused test file must declare a final *Tests class")
            elif class_match.group(2) != "ConsoleDockTestCase":
                errors.append(
                    f"{path.relative_to(root)}: {class_match.group(1)} must inherit ConsoleDockTestCase"
                )

        test_method_count += len(TEST_METHOD_RE.findall(text))

    if test_method_count < MIN_TEST_METHODS:
        errors.append(
            f"{TEST_ROOT}: expected at least {MIN_TEST_METHODS} Swift facade test methods, got {test_method_count}"
        )

    return errors


def write_file(root: pathlib.Path, relative: str, lines: int, body: str | None = None) -> None:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    if body is not None:
        path.write_text(body, encoding="utf-8")
        return
    path.write_text("\n".join(f"// line {index}" for index in range(lines)) + "\n", encoding="utf-8")


def write_valid_tree(root: pathlib.Path) -> None:
    write_file(
        root,
        "Tests/ConsoleDockTests/ConsoleDockTestCase.swift",
        1,
        body="import XCTest\nclass ConsoleDockTestCase: XCTestCase {}\n",
    )
    for index, filename in enumerate(sorted(REQUIRED_FILES - {"ConsoleDockTestCase.swift"}), start=1):
        methods = "\n".join(f"    func testExample{index}_{method}() {{}}" for method in range(18))
        write_file(
            root,
            f"Tests/ConsoleDockTests/{filename}",
            1,
            body=f"final class {filename.removesuffix('.swift')}: ConsoleDockTestCase {{\n{methods}\n}}\n",
        )


def self_test() -> list[str]:
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="consoledock-test-structure-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        write_valid_tree(root)
        if validate(root):
            errors.append("validate should accept the focused test file layout")

        write_file(root, "Tests/ConsoleDockTests/ConsoleDockTests.swift", 1)
        if not validate(root):
            errors.append("validate should reject the old monolithic ConsoleDockTests.swift file")
        (root / "Tests/ConsoleDockTests/ConsoleDockTests.swift").unlink()

        oversized = root / "Tests/ConsoleDockTests/ConsoleDockFacadeTests.swift"
        original = oversized.read_text(encoding="utf-8")
        write_file(root, "Tests/ConsoleDockTests/ConsoleDockFacadeTests.swift", MAX_TEST_FILE_LINES + 1)
        if not validate(root):
            errors.append("validate should reject oversized focused test files")
        oversized.write_text(original, encoding="utf-8")

        wrong_base = root / "Tests/ConsoleDockTests/ConsoleDockReportTests.swift"
        wrong_base.write_text("final class ConsoleDockReportTests: XCTestCase {\n    func testExample() {}\n}\n")
        if not validate(root):
            errors.append("validate should reject focused tests that bypass ConsoleDockTestCase")

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
    parser.add_argument("--self-test", action="store_true", help="Run validator self-tests.")
    args = parser.parse_args()

    if args.self_test:
        errors = self_test()
        if errors:
            print("Test structure validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1
        print("Test structure validator self-test passed.")
        return 0

    errors = validate(args.root.resolve())
    if errors:
        print("Test structure validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Test structure validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
