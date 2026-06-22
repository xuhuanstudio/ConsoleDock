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
import time
from typing import NamedTuple
import urllib.error
import urllib.request


SEMVER_TAG_RE = re.compile(r"^v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$")
DEFAULT_WORKFLOW = "Release Validation"
DEFAULT_NETWORK_ATTEMPTS = 3
DEFAULT_RETRY_DELAY_SECONDS = 2.0
TRANSIENT_PROCESS_FAILURE_SNIPPETS = (
    "connection reset",
    "connection timed out",
    "could not resolve host",
    "eof",
    "network is unreachable",
    "operation timed out",
    "temporarily unavailable",
    "temporary failure",
    "the network connection was lost",
    "timed out",
    "tls handshake timeout",
)
REQUIRED_RELEASE_BODY_SNIPPETS = (
    "### Boundaries",
    "Not a full replacement for Xcode Console.",
    "Does not promise complete Swift Logger, os_log, or Apple unified logging capture.",
    "No default persistence, upload, network inspector, CocoaPods, or XCFramework distribution.",
    "### Validation",
    "Release Validation workflow passed:",
)


class URLCheckResult(NamedTuple):
    ok: bool
    message: str
    access_challenge: bool = False


def run(command: list[str], cwd: pathlib.Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def is_transient_process_failure(result: subprocess.CompletedProcess[str]) -> bool:
    if result.returncode == 0:
        return False

    combined_output = f"{result.stderr}\n{result.stdout}".lower()
    return any(snippet in combined_output for snippet in TRANSIENT_PROCESS_FAILURE_SNIPPETS)


def run_network(
    command: list[str],
    cwd: pathlib.Path | None = None,
    *,
    attempts: int = DEFAULT_NETWORK_ATTEMPTS,
    retry_delay_seconds: float = DEFAULT_RETRY_DELAY_SECONDS,
) -> subprocess.CompletedProcess[str]:
    last_result: subprocess.CompletedProcess[str] | None = None
    for attempt in range(1, attempts + 1):
        result = run(command, cwd)
        if result.returncode == 0 or not is_transient_process_failure(result) or attempt == attempts:
            if result.returncode != 0 and attempt > 1:
                return subprocess.CompletedProcess(
                    result.args,
                    result.returncode,
                    result.stdout,
                    f"{result.stderr.rstrip()}\nRetried {attempts} times for a transient network failure.".strip(),
                )
            return result

        last_result = result
        time.sleep(retry_delay_seconds)

    assert last_result is not None
    return last_result


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


def resolve_tag_commit_sha_from_ls_remote(output: str, tag: str) -> str | None:
    direct_ref = f"refs/tags/{tag}"
    peeled_ref = f"{direct_ref}^{{}}"
    direct_sha: str | None = None
    peeled_sha: str | None = None

    for line in output.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue

        sha, ref = parts
        if ref == peeled_ref:
            peeled_sha = sha
        elif ref == direct_ref:
            direct_sha = sha

    return peeled_sha or direct_sha


def remote_tag_commit_sha(repository_url: str, tag: str) -> tuple[str | None, list[str]]:
    tag_lookup = run_network(
        [
            "git",
            "ls-remote",
            "--exit-code",
            "--tags",
            repository_url,
            tag,
            f"{tag}^{{}}",
        ]
    )
    if tag_lookup.returncode != 0:
        return None, [f"remote tag {tag} was not found on {repository_url}"]

    tag_commit_sha = resolve_tag_commit_sha_from_ls_remote(tag_lookup.stdout, tag)
    if tag_commit_sha is None:
        return None, [f"remote tag {tag} was found on {repository_url}, but its commit SHA could not be resolved"]

    return tag_commit_sha, []


def validate_workflow_matches_tag(
    tag: str,
    workflow: str,
    workflow_head_sha: object,
    tag_commit_sha: str | None,
) -> list[str]:
    if tag_commit_sha is None:
        return []

    if not isinstance(workflow_head_sha, str) or not workflow_head_sha:
        return [
            f"{workflow} workflow for {tag} did not report headSha; "
            "cannot confirm it ran against the remote tag commit"
        ]

    if workflow_head_sha != tag_commit_sha:
        return [
            f"{workflow} workflow for {tag} ran at {workflow_head_sha}, "
            f"but the remote tag resolves to {tag_commit_sha}"
        ]

    return []


def release_validation_url_re(repository_slug: str) -> re.Pattern[str]:
    return re.compile(rf"https://github\.com/{re.escape(repository_slug)}/actions/runs/\d+", re.IGNORECASE)


def validate_release_body(body: str, repository_slug: str, expected_workflow_url: str | None = None) -> list[str]:
    errors: list[str] = []
    for snippet in REQUIRED_RELEASE_BODY_SNIPPETS:
        if snippet not in body:
            errors.append(f"GitHub Release notes must contain: {snippet}")

    workflow_urls = release_validation_url_re(repository_slug).findall(body)
    if not workflow_urls:
        errors.append(
            "GitHub Release notes must link to the passing Release Validation workflow run "
            f"for {repository_slug}"
        )
    elif expected_workflow_url is not None and expected_workflow_url not in workflow_urls:
        errors.append(
            "GitHub Release notes must link to the passing Release Validation workflow run for the verified tag: "
            f"{expected_workflow_url}"
        )

    return errors


def check_github_release(repository_slug: str, tag: str, workflow: str) -> list[str]:
    errors: list[str] = []
    release_body: str | None = None
    expected_workflow_url: str | None = None
    repository_url = f"https://github.com/{repository_slug}.git"
    tag_commit_sha: str | None = None

    repo = run_network(
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

    release = run_network(
        [
            "gh",
            "release",
            "view",
            tag,
            "--repo",
            repository_slug,
            "--json",
            "tagName,isDraft,isPrerelease,name,url,targetCommitish,body",
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
        release_body = release_payload.get("body") or ""

    tag_commit_sha, tag_errors = remote_tag_commit_sha(repository_url, tag)
    errors.extend(tag_errors)

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
    workflow_runs = run_network([*workflow_command, "--branch", tag])
    if workflow_runs.returncode != 0:
        errors.append(workflow_runs.stderr.strip() or workflow_runs.stdout.strip() or "unable to list workflow runs")
    else:
        runs = json.loads(workflow_runs.stdout)
        matching_runs = [item for item in runs if item.get("headBranch") == tag]
        if not matching_runs:
            fallback_runs = run_network(workflow_command)
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
            else:
                errors.extend(validate_workflow_matches_tag(tag, workflow, latest.get("headSha"), tag_commit_sha))
                expected_workflow_url = latest.get("url")

    if release_body is not None:
        errors.extend(validate_release_body(release_body, repository_slug, expected_workflow_url))

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

        resolve = run_network(["swift", "package", "resolve"], root)
        if resolve.returncode != 0:
            errors.append(resolve.stderr.strip() or resolve.stdout.strip() or "SwiftPM resolve failed")
            return errors

        build = run(["swift", "build"], root)
        if build.returncode != 0:
            errors.append(build.stderr.strip() or build.stdout.strip() or "SwiftPM consumer build failed")

    return errors


def is_access_challenge(error: urllib.error.HTTPError) -> bool:
    return error.code == 403 and error.headers.get("cf-mitigated", "").lower() == "challenge"


def check_url(url: str, attempts: int = DEFAULT_NETWORK_ATTEMPTS) -> URLCheckResult:
    request = urllib.request.Request(url, headers={"User-Agent": "ConsoleDock release verifier"})
    last_message = ""
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                status = getattr(response, "status", 200)
                if 200 <= status < 400:
                    return URLCheckResult(True, f"HTTP {status}")
                last_message = f"HTTP {status}"
        except urllib.error.HTTPError as error:
            if is_access_challenge(error):
                return URLCheckResult(False, "HTTP 403 access challenge", True)
            if error.code not in {408, 429, 500, 502, 503, 504}:
                return URLCheckResult(False, f"HTTP {error.code}")
            last_message = f"HTTP {error.code}"
        except urllib.error.URLError as error:
            last_message = str(error.reason)

        if attempt < attempts:
            time.sleep(DEFAULT_RETRY_DELAY_SECONDS)

    retry_suffix = f" after {attempts} attempts" if attempts > 1 else ""
    return URLCheckResult(False, f"{last_message}{retry_suffix}")


def check_spi(repository_slug: str, *, allow_access_challenge: bool) -> tuple[list[str], list[str]]:
    owner, repo = repository_slug.split("/", maxsplit=1)
    package_url = f"https://swiftpackageindex.com/{owner}/{repo}"
    docs_url = f"https://swiftpackageindex.com/{owner}/{repo}/documentation/consoledock"
    errors: list[str] = []
    warnings: list[str] = []

    result = check_url(package_url)
    if not result.ok:
        if result.access_challenge and allow_access_challenge:
            warnings.append(
                f"Swift Package Index package page could not be checked automatically at {package_url}: "
                f"{result.message}. Verify it manually in a browser."
            )
        else:
            errors.append(f"Swift Package Index package page is unavailable at {package_url}: {result.message}")

    result = check_url(docs_url)
    if not result.ok:
        if result.access_challenge and allow_access_challenge:
            warnings.append(
                f"Swift Package Index DocC page could not be checked automatically at {docs_url}: "
                f"{result.message}. Verify it manually in a browser."
            )
        else:
            errors.append(f"Swift Package Index DocC page is unavailable at {docs_url}: {result.message}")

    return errors, warnings


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

    errors.extend(self_test_transient_process_detection())
    errors.extend(self_test_tag_commit_resolution())
    errors.extend(self_test_workflow_tag_commit_validation())
    errors.extend(self_test_release_body_validation())
    errors.extend(self_test_swiftpm_v_tag_resolution())
    return errors


def self_test_transient_process_detection() -> list[str]:
    errors: list[str] = []
    transient = subprocess.CompletedProcess(["gh", "run", "view"], 1, "", "Get https://api.github.com/example: EOF")
    if not is_transient_process_failure(transient):
        errors.append("is_transient_process_failure should detect GitHub API EOF")

    timeout = subprocess.CompletedProcess(["gh", "api"], 1, "", "connect: operation timed out")
    if not is_transient_process_failure(timeout):
        errors.append("is_transient_process_failure should detect operation timed out")

    not_found = subprocess.CompletedProcess(["gh", "release", "view"], 1, "", "release not found")
    if is_transient_process_failure(not_found):
        errors.append("is_transient_process_failure should not retry permanent release-not-found errors")

    success = subprocess.CompletedProcess(["gh", "api"], 0, "{}", "")
    if is_transient_process_failure(success):
        errors.append("is_transient_process_failure should not retry successful commands")

    challenge = urllib.error.HTTPError(
        "https://swiftpackageindex.com/owner/Repo",
        403,
        "Forbidden",
        {"cf-mitigated": "challenge"},
        None,
    )
    if not is_access_challenge(challenge):
        errors.append("is_access_challenge should detect Cloudflare challenge responses")

    forbidden = urllib.error.HTTPError("https://example.com", 403, "Forbidden", {}, None)
    if is_access_challenge(forbidden):
        errors.append("is_access_challenge should not treat every HTTP 403 as an access challenge")

    return errors


def self_test_tag_commit_resolution() -> list[str]:
    errors: list[str] = []
    tag_object_sha = "a" * 40
    peeled_commit_sha = "b" * 40
    lightweight_commit_sha = "c" * 40

    annotated_output = (
        f"{tag_object_sha}\trefs/tags/v0.1.0\n"
        f"{peeled_commit_sha}\trefs/tags/v0.1.0^{{}}\n"
    )
    if resolve_tag_commit_sha_from_ls_remote(annotated_output, "v0.1.0") != peeled_commit_sha:
        errors.append("resolve_tag_commit_sha_from_ls_remote should prefer the peeled commit SHA for annotated tags")

    lightweight_output = f"{lightweight_commit_sha}\trefs/tags/v0.1.0\n"
    if resolve_tag_commit_sha_from_ls_remote(lightweight_output, "v0.1.0") != lightweight_commit_sha:
        errors.append("resolve_tag_commit_sha_from_ls_remote should use the direct SHA for lightweight tags")

    if resolve_tag_commit_sha_from_ls_remote("not-a-git-ref\n", "v0.1.0") is not None:
        errors.append("resolve_tag_commit_sha_from_ls_remote should ignore malformed ls-remote output")

    return errors


def self_test_workflow_tag_commit_validation() -> list[str]:
    errors: list[str] = []
    tag_commit_sha = "d" * 40

    if validate_workflow_matches_tag("v0.1.0", DEFAULT_WORKFLOW, tag_commit_sha, tag_commit_sha):
        errors.append("validate_workflow_matches_tag should accept matching workflow and tag SHAs")

    if not validate_workflow_matches_tag("v0.1.0", DEFAULT_WORKFLOW, "e" * 40, tag_commit_sha):
        errors.append("validate_workflow_matches_tag should reject a workflow SHA that does not match the tag")

    if not validate_workflow_matches_tag("v0.1.0", DEFAULT_WORKFLOW, None, tag_commit_sha):
        errors.append("validate_workflow_matches_tag should reject a successful workflow without headSha")

    if validate_workflow_matches_tag("v0.1.0", DEFAULT_WORKFLOW, None, None):
        errors.append("validate_workflow_matches_tag should not duplicate errors when the tag SHA is already unknown")

    return errors


def self_test_release_body_validation() -> list[str]:
    errors: list[str] = []
    valid_body = textwrap.dedent(
        """\
        ## ConsoleDock v0.1.0

        ### Highlights

        - In-app UIKit debug console for iOS test/debug use.

        ### Boundaries

        - Not a full replacement for Xcode Console.
        - Does not promise complete Swift Logger, os_log, or Apple unified logging capture.
        - No default persistence, upload, network inspector, CocoaPods, or XCFramework distribution.

        ### Validation

        - Release Validation workflow passed: https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406
        """
    )
    if validate_release_body(valid_body, "xuhuanstudio/ConsoleDock", "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406"):
        errors.append("validate_release_body should accept the documented release-notes shape")

    missing_boundaries = valid_body.replace("### Boundaries\n", "")
    if not validate_release_body(missing_boundaries, "xuhuanstudio/ConsoleDock"):
        errors.append("validate_release_body should reject release notes without the Boundaries section")

    missing_validation_url = valid_body.replace(
        "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406",
        "Release Validation workflow",
    )
    if not validate_release_body(missing_validation_url, "xuhuanstudio/ConsoleDock"):
        errors.append("validate_release_body should reject release notes without a workflow run URL")

    wrong_repository_url = valid_body.replace(
        "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406",
        "https://github.com/other/ConsoleDock/actions/runs/27929173406",
    )
    if not validate_release_body(wrong_repository_url, "xuhuanstudio/ConsoleDock"):
        errors.append("validate_release_body should reject workflow run URLs from another repository")

    wrong_workflow_url = valid_body.replace(
        "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406",
        "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173407",
    )
    if not validate_release_body(
        wrong_workflow_url,
        "xuhuanstudio/ConsoleDock",
        "https://github.com/xuhuanstudio/ConsoleDock/actions/runs/27929173406",
    ):
        errors.append("validate_release_body should reject a non-matching workflow run URL when the tag run is known")

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
    parser.add_argument(
        "--allow-spi-challenge",
        action="store_true",
        help="Allow Swift Package Index Cloudflare access challenges after manual browser verification.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and print the planned checks only.")
    parser.add_argument("--self-test", action="store_true", help="Run local verifier self-tests without network access.")
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []
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
        print(f"Swift Package Index access challenges allowed: {'yes' if args.allow_spi_challenge else 'no'}")
        print("Post-release verification dry run passed.")
        return 0

    if not args.skip_github:
        errors.extend(check_github_release(repository_slug, args.tag, args.workflow))

    if not args.skip_spm:
        errors.extend(check_spm_consumer(repository_url, args.tag))

    if args.check_spi:
        spi_errors, spi_warnings = check_spi(repository_slug, allow_access_challenge=args.allow_spi_challenge)
        errors.extend(spi_errors)
        warnings.extend(spi_warnings)

    if errors:
        print("Post-release verification failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)

    print("Post-release verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
