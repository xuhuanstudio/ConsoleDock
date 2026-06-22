#!/usr/bin/env python3
"""Validate the public GitHub release preflight state before tagging."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys


DEFAULT_REMOTE = "origin"
DEFAULT_BRANCH = "main"


def run(
    command: list[str],
    root: pathlib.Path,
    *,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=check,
    )


def output(command: list[str], root: pathlib.Path) -> str:
    return run(command, root, check=True).stdout.strip()


def validate(
    root: pathlib.Path,
    tag: str,
    remote: str,
    branch: str,
    *,
    local_only: bool,
    allow_existing_local_tag: bool,
) -> list[str]:
    errors: list[str] = []

    status = output(["git", "status", "--short"], root)
    if status:
        errors.append("working tree must be clean before public release preflight")

    current_branch = output(["git", "branch", "--show-current"], root)
    if current_branch != branch:
        errors.append(f"current branch must be {branch}, got {current_branch or 'detached HEAD'}")

    metadata = run([sys.executable, "scripts/validate-release-metadata.py", "--tag", tag], root)
    if metadata.returncode != 0:
        errors.append(metadata.stderr.strip() or metadata.stdout.strip() or "release metadata validation failed")

    governance = run([sys.executable, "scripts/validate-governance-metadata.py"], root)
    if governance.returncode != 0:
        errors.append(governance.stderr.strip() or governance.stdout.strip() or "governance validation failed")

    content_audit = run([sys.executable, "scripts/audit-release-content.py"], root)
    if content_audit.returncode != 0:
        errors.append(content_audit.stderr.strip() or content_audit.stdout.strip() or "release content audit failed")

    local_tag = run(["git", "rev-parse", "-q", "--verify", f"refs/tags/{tag}"], root)
    if local_tag.returncode == 0 and not allow_existing_local_tag:
        errors.append(f"local tag {tag} already exists; do not overwrite a release tag")

    if local_only:
        return errors

    remote_url = run(["git", "remote", "get-url", remote], root)
    if remote_url.returncode != 0:
        errors.append(f"git remote {remote} is not configured")
        return errors

    remote_branch = run(["git", "ls-remote", "--exit-code", "--heads", remote, branch], root)
    if remote_branch.returncode != 0:
        errors.append(f"remote {remote} does not expose branch {branch}; push and validate CI before tagging")
    else:
        remote_branch_sha = remote_branch.stdout.split()[0]
        local_head_sha = output(["git", "rev-parse", "HEAD"], root)
        if remote_branch_sha != local_head_sha:
            errors.append(
                f"remote {remote}/{branch} is {remote_branch_sha}, "
                f"but local HEAD is {local_head_sha}; push the current commit and wait for CI before tagging"
            )

    remote_tag = run(["git", "ls-remote", "--exit-code", "--tags", remote, tag], root)
    if remote_tag.returncode == 0:
        errors.append(f"remote tag {tag} already exists; publish a new patch tag instead of moving it")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True, help="Release tag to validate, for example v0.1.0.")
    parser.add_argument("--remote", default=DEFAULT_REMOTE, help=f"Git remote name. Defaults to {DEFAULT_REMOTE}.")
    parser.add_argument("--branch", default=DEFAULT_BRANCH, help=f"Release branch name. Defaults to {DEFAULT_BRANCH}.")
    parser.add_argument(
        "--local-only",
        action="store_true",
        help="Skip remote checks. Useful before the public GitHub repository exists.",
    )
    parser.add_argument(
        "--allow-existing-local-tag",
        action="store_true",
        help="Allow the release tag to exist locally when rechecking after tag creation.",
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=pathlib.Path(__file__).resolve().parents[1],
        type=pathlib.Path,
        help="Repository root. Defaults to the parent of the scripts directory.",
    )
    args = parser.parse_args()

    errors = validate(
        args.root.resolve(),
        args.tag,
        args.remote,
        args.branch,
        local_only=args.local_only,
        allow_existing_local_tag=args.allow_existing_local_tag,
    )
    if errors:
        print("Public release preflight failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Public release preflight passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
