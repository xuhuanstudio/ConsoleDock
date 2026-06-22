#!/usr/bin/env python3
"""Verify a published ConsoleDock GitHub release and SwiftPM package."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import tempfile
import textwrap
import urllib.error
import urllib.request


SEMVER_TAG_RE = re.compile(r"^v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$")
DEFAULT_WORKFLOW = "Release Validation"


def run(command: list[str], cwd: pathlib.Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def normalize_repository(repository: str) -> tuple[str, str]:
    value = repository.strip()
    if value.endswith(".git"):
        value = value[:-4]

    if value.startswith("git@github.com:"):
        slug = value.removeprefix("git@github.com:")
    elif value.startswith("https://github.com/"):
        slug = value.removeprefix("https://github.com/")
    elif value.startswith("http://github.com/"):
        slug = value.removeprefix("http://github.com/")
    else:
        slug = value

    parts = [part for part in slug.strip("/").split("/") if part]
    if len(parts) != 2:
        raise ValueError("repository must be OWNER/REPO or a GitHub repository URL")

    normalized_slug = f"{parts[0]}/{parts[1]}"
    return normalized_slug, f"https://github.com/{normalized_slug}.git"


def package_version(tag: str) -> str:
    match = SEMVER_TAG_RE.fullmatch(tag)
    if match is None:
        raise ValueError(f"tag must be semantic version form like v0.1.0 or 0.1.0, got {tag}")
    return match.group(1)


def check_github_release(repository_slug: str, tag: str, workflow: str) -> list[str]:
    errors: list[str] = []

    repo = run(
        [
            "gh",
            "repo",
            "view",
            repository_slug,
            "--json",
            "name,owner,visibility,url,defaultBranchRef",
        ]
    )
    if repo.returncode != 0:
        return [repo.stderr.strip() or repo.stdout.strip() or f"unable to view repository {repository_slug}"]

    release = run(
        [
            "gh",
            "release",
            "view",
            tag,
            "--repo",
            repository_slug,
            "--json",
            "tagName,isDraft,isPrerelease,name,url,targetCommitish",
        ]
    )
    if release.returncode != 0:
        errors.append(release.stderr.strip() or release.stdout.strip() or f"unable to view release {tag}")
    else:
        release_payload = json.loads(release.stdout)
        if release_payload.get("tagName") != tag:
            errors.append(f"GitHub Release tagName must be {tag}, got {release_payload.get('tagName')}")
        if release_payload.get("isDraft"):
            errors.append(f"GitHub Release {tag} must not be a draft")

    tag_lookup = run(["git", "ls-remote", "--exit-code", "--tags", f"https://github.com/{repository_slug}.git", tag])
    if tag_lookup.returncode != 0:
        errors.append(f"remote tag {tag} was not found on https://github.com/{repository_slug}.git")

    workflow_fields = "conclusion,status,headBranch,headSha,url,workflowName,createdAt"
    workflow_command = [
        "gh",
        "run",
        "list",
        "--repo",
        repository_slug,
        "--workflow",
        workflow,
        "--event",
        "push",
        "--json",
        workflow_fields,
        "--limit",
        "20",
    ]
    workflow_runs = run([*workflow_command, "--branch", tag])
    if workflow_runs.returncode != 0:
        errors.append(workflow_runs.stderr.strip() or workflow_runs.stdout.strip() or "unable to list workflow runs")
    else:
        runs = json.loads(workflow_runs.stdout)
        matching_runs = [item for item in runs if item.get("headBranch") == tag]
        if not matching_runs:
            fallback_runs = run(workflow_command)
            if fallback_runs.returncode == 0:
                runs = json.loads(fallback_runs.stdout)
                matching_runs = [item for item in runs if item.get("headBranch") == tag]
        if not matching_runs:
            errors.append(f"no {workflow} workflow run found for tag {tag}")
        else:
            latest = matching_runs[0]
            if latest.get("status") != "completed" or latest.get("conclusion") != "success":
                errors.append(
                    f"{workflow} workflow for {tag} must be completed/success, "
                    f"got status={latest.get('status')} conclusion={latest.get('conclusion')}"
                )

    return errors


def check_spm_consumer(repository_url: str, tag: str) -> list[str]:
    errors: list[str] = []
    version = package_version(tag)
    with tempfile.TemporaryDirectory(prefix="consoledock-release-check-") as raw_directory:
        root = pathlib.Path(raw_directory)
        package_swift = root / "Package.swift"
        source_directory = root / "Sources" / "ConsumerCheck"
        source_directory.mkdir(parents=True)
        package_swift.write_text(
            textwrap.dedent(
                f"""\
                // swift-tools-version: 5.9
                import PackageDescription

                let package = Package(
                    name: "ConsoleDockConsumerCheck",
                    platforms: [
                        .iOS(.v12),
                        .macOS(.v12)
                    ],
                    products: [
                        .executable(name: "ConsumerCheck", targets: ["ConsumerCheck"])
                    ],
                    dependencies: [
                        .package(url: "{repository_url}", exact: "{version}")
                    ],
                    targets: [
                        .executableTarget(
                            name: "ConsumerCheck",
                            dependencies: [
                                .product(name: "ConsoleDock", package: "ConsoleDock"),
                                .product(name: "ConsoleDockCore", package: "ConsoleDock")
                            ]
                        )
                    ]
                )
                """
            ),
            encoding="utf-8",
        )
        (source_directory / "main.swift").write_text(
            textwrap.dedent(
                """\
                import ConsoleDock
                import ConsoleDockCore

                _ = ConsoleDock.Configuration(
                    captureStandardOutput: false,
                    captureStandardError: false,
                    showsFloatingButton: false
                )
                print("ConsoleDock products resolved")
                """
            ),
            encoding="utf-8",
        )

        resolve = run(["swift", "package", "resolve"], root)
        if resolve.returncode != 0:
            errors.append(resolve.stderr.strip() or resolve.stdout.strip() or "SwiftPM resolve failed")
            return errors

        build = run(["swift", "build"], root)
        if build.returncode != 0:
            errors.append(build.stderr.strip() or build.stdout.strip() or "SwiftPM consumer build failed")

    return errors


def check_url(url: str) -> tuple[bool, str]:
    request = urllib.request.Request(url, headers={"User-Agent": "ConsoleDock release verifier"})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            status = getattr(response, "status", 200)
            return 200 <= status < 400, f"HTTP {status}"
    except urllib.error.HTTPError as error:
        return False, f"HTTP {error.code}"
    except urllib.error.URLError as error:
        return False, str(error.reason)


def check_spi(repository_slug: str) -> list[str]:
    owner, repo = repository_slug.split("/", maxsplit=1)
    package_url = f"https://swiftpackageindex.com/{owner}/{repo}"
    docs_url = f"https://swiftpackageindex.com/{owner}/{repo}/documentation/consoledock"
    errors: list[str] = []

    ok, message = check_url(package_url)
    if not ok:
        errors.append(f"Swift Package Index package page is unavailable at {package_url}: {message}")

    ok, message = check_url(docs_url)
    if not ok:
        errors.append(f"Swift Package Index DocC page is unavailable at {docs_url}: {message}")

    return errors


def self_test() -> list[str]:
    errors: list[str] = []

    repository_cases = {
        "owner/Repo": ("owner/Repo", "https://github.com/owner/Repo.git"),
        "https://github.com/owner/Repo": ("owner/Repo", "https://github.com/owner/Repo.git"),
        "https://github.com/owner/Repo.git": ("owner/Repo", "https://github.com/owner/Repo.git"),
        "git@github.com:owner/Repo.git": ("owner/Repo", "https://github.com/owner/Repo.git"),
    }
    for raw_repository, expected in repository_cases.items():
        try:
            actual = normalize_repository(raw_repository)
        except ValueError as error:
            errors.append(f"normalize_repository({raw_repository!r}) failed: {error}")
            continue
        if actual != expected:
            errors.append(f"normalize_repository({raw_repository!r}) returned {actual}, expected {expected}")

    version_cases = {
        "v0.1.0": "0.1.0",
        "0.1.0": "0.1.0",
        "v1.2.3-beta.1": "1.2.3-beta.1",
    }
    for raw_tag, expected in version_cases.items():
        try:
            actual = package_version(raw_tag)
        except ValueError as error:
            errors.append(f"package_version({raw_tag!r}) failed: {error}")
            continue
        if actual != expected:
            errors.append(f"package_version({raw_tag!r}) returned {actual}, expected {expected}")

    try:
        package_version("release-0.1.0")
        errors.append("package_version('release-0.1.0') should reject non-semver tags")
    except ValueError:
        pass

    errors.extend(self_test_swiftpm_v_tag_resolution())
    return errors


def self_test_swiftpm_v_tag_resolution() -> list[str]:
    with tempfile.TemporaryDirectory(prefix="consoledock-verifier-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        library_root = root / "TagProbe"
        consumer_root = root / "Consumer"
        (library_root / "Sources" / "TagProbe").mkdir(parents=True)
        (consumer_root / "Sources" / "Consumer").mkdir(parents=True)

        (library_root / "Package.swift").write_text(
            textwrap.dedent(
                """\
                // swift-tools-version: 5.9
                import PackageDescription

                let package = Package(
                    name: "TagProbe",
                    products: [
                        .library(name: "TagProbe", targets: ["TagProbe"])
                    ],
                    targets: [
                        .target(name: "TagProbe")
                    ]
                )
                """
            ),
            encoding="utf-8",
        )
        (library_root / "Sources" / "TagProbe" / "TagProbe.swift").write_text(
            "public enum TagProbe { public static let ok = true }\n",
            encoding="utf-8",
        )

        commands = [
            ["git", "init", "-q"],
            ["git", "config", "user.email", "release-verifier@example.com"],
            ["git", "config", "user.name", "ConsoleDock Release Verifier"],
            ["git", "add", "."],
            ["git", "commit", "-q", "-m", "Initial tag probe"],
            ["git", "tag", "v0.1.0"],
        ]
        for command in commands:
            result = run(command, library_root)
            if result.returncode != 0:
                return [result.stderr.strip() or result.stdout.strip() or f"{' '.join(command)} failed"]

        (consumer_root / "Package.swift").write_text(
            textwrap.dedent(
                f"""\
                // swift-tools-version: 5.9
                import PackageDescription

                let package = Package(
                    name: "TagProbeConsumer",
                    dependencies: [
                        .package(url: "{library_root.as_posix()}", exact: "0.1.0")
                    ],
                    targets: [
                        .executableTarget(name: "Consumer", dependencies: ["TagProbe"])
                    ]
                )
                """
            ),
            encoding="utf-8",
        )
        (consumer_root / "Sources" / "Consumer" / "main.swift").write_text(
            "import TagProbe\nprint(TagProbe.ok)\n",
            encoding="utf-8",
        )

        result = run(["swift", "package", "resolve"], consumer_root)
        if result.returncode != 0:
            return [result.stderr.strip() or result.stdout.strip() or "SwiftPM v-prefixed tag resolve self-test failed"]

    return []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", help="GitHub repository as OWNER/REPO or URL.")
    parser.add_argument("--tag", help="Release tag, for example v0.1.0.")
    parser.add_argument(
        "--workflow",
        default=DEFAULT_WORKFLOW,
        help=f"Tag validation workflow name. Defaults to {DEFAULT_WORKFLOW}.",
    )
    parser.add_argument("--skip-github", action="store_true", help="Skip GitHub repo, release, tag, and Actions checks.")
    parser.add_argument("--skip-spm", action="store_true", help="Skip external SwiftPM consumer resolve/build check.")
    parser.add_argument("--check-spi", action="store_true", help="Check Swift Package Index package and DocC pages.")
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and print the planned checks only.")
    parser.add_argument("--self-test", action="store_true", help="Run local verifier self-tests without network access.")
    args = parser.parse_args()

    errors: list[str] = []
    if args.self_test:
        errors = self_test()
        if errors:
            print("Post-release verifier self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Post-release verifier self-test passed.")
        return 0

    if args.repository is None or args.tag is None:
        parser.error("--repository and --tag are required unless --self-test is used")

    try:
        repository_slug, repository_url = normalize_repository(args.repository)
        version = package_version(args.tag)
    except ValueError as error:
        print(f"Post-release verification failed:\n- {error}", file=sys.stderr)
        return 1

    if args.dry_run:
        print(f"Repository: {repository_slug}")
        print(f"Repository URL: {repository_url}")
        print(f"Tag: {args.tag}")
        print(f"SwiftPM version: {version}")
        print(f"GitHub checks: {'no' if args.skip_github else 'yes'}")
        print(f"SwiftPM consumer check: {'no' if args.skip_spm else 'yes'}")
        print(f"Swift Package Index checks: {'yes' if args.check_spi else 'no'}")
        print("Post-release verification dry run passed.")
        return 0

    if not args.skip_github:
        errors.extend(check_github_release(repository_slug, args.tag, args.workflow))

    if not args.skip_spm:
        errors.extend(check_spm_consumer(repository_url, args.tag))

    if args.check_spi:
        errors.extend(check_spi(repository_slug))

    if errors:
        print("Post-release verification failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Post-release verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
