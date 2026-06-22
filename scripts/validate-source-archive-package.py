#!/usr/bin/env python3
"""Build and test the SwiftPM source archive as an independent package."""

from __future__ import annotations

import argparse
import pathlib
import shutil
import subprocess
import sys
import tempfile
import zipfile


def archive_root(archive: zipfile.ZipFile) -> pathlib.PurePosixPath:
    roots = {
        pathlib.PurePosixPath(name).parts[0]
        for name in archive.namelist()
        if pathlib.PurePosixPath(name).parts
    }
    if len(roots) != 1:
        raise ValueError("archive should contain exactly one top-level directory")
    return pathlib.PurePosixPath(next(iter(roots)))


def validate_entry_names(archive: zipfile.ZipFile) -> None:
    for name in archive.namelist():
        path = pathlib.PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"archive entry is not a safe relative path: {name}")


def run(command: list[str], cwd: pathlib.Path) -> None:
    subprocess.run(command, cwd=cwd, check=True)


def validate_archive_package(archive_path: pathlib.Path) -> None:
    if not archive_path.exists():
        raise FileNotFoundError(f"{archive_path}: archive does not exist")
    if archive_path.stat().st_size == 0:
        raise ValueError(f"{archive_path}: archive is empty")

    temp_dir = pathlib.Path(tempfile.mkdtemp(prefix="consoledock-source-archive-"))
    try:
        with zipfile.ZipFile(archive_path) as archive:
            validate_entry_names(archive)
            root = archive_root(archive)
            archive.extractall(temp_dir)

        package_root = temp_dir / root
        if not (package_root / "Package.swift").exists():
            raise FileNotFoundError(f"{archive_path}: extracted archive does not contain Package.swift")

        run(["swift", "package", "dump-package"], cwd=package_root)
        run(["swift", "build"], cwd=package_root)
        run(["swift", "test"], cwd=package_root)
    finally:
        shutil.rmtree(temp_dir)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "archive",
        nargs="?",
        default=pathlib.Path(".build/ConsoleDock-source.zip"),
        type=pathlib.Path,
        help="Source archive path. Defaults to .build/ConsoleDock-source.zip.",
    )
    args = parser.parse_args()

    try:
        validate_archive_package(args.archive)
    except (OSError, ValueError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        print("Source archive package validation failed:", file=sys.stderr)
        print(f"- {error}", file=sys.stderr)
        return 1

    print("Source archive package validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
