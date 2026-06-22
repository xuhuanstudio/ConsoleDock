# Release Process

ConsoleDock releases are source-first Swift Package Manager releases. A public release is a git tag plus release notes; CocoaPods and XCFramework artifacts remain future distribution channels.

## Release Principles

- Ship small, verified releases.
- Keep Release builds disabled by default.
- Keep logs local and memory-first by default.
- Do not describe ConsoleDock as a full Xcode Console, Swift `Logger`, `os_log`, or Apple unified logging replacement.
- Do not move a public tag after consumers may have resolved it. Prefer a new patch release.

## Before Tagging

1. Decide the version, for example `v0.1.0`.
2. Move completed `CHANGELOG.md` entries from `Unreleased` into a heading that matches the tag, for example `## v0.1.0 - 2026-06-22`.
3. Confirm README, DocC, sample app walkthrough, release-build safety, logging boundaries, security policy, GitHub repository setup, and roadmap still describe the current shipped behavior.
4. Confirm the [distribution strategy](distribution-strategy.md) still says SPM is the supported channel unless CocoaPods or XCFramework support has actually been implemented and validated.
5. Confirm there are no secrets, production logs, credentials, tokens, or private screenshots in docs, examples, or screenshots. `scripts/audit-release-content.py` covers generated paths, private key blocks, common token shapes, and local absolute paths; review app-specific sensitive content manually.
6. Confirm the public repository remote, Actions, topics, and vulnerability reporting are configured as described in [GitHub repository setup](github-repository-setup.md).
7. Confirm public release preflight passes for the intended tag:

```sh
python3 scripts/validate-public-release-preflight.py --tag v0.1.0
```

8. Confirm `git status --short` is clean before the final validation run.

## Required Local Validation

Run these from the package root:

```sh
scripts/validate-release.sh
```

The script validates the working tree is clean, then validates the SwiftPM manifest, package identity, Swift Package Index metadata, Objective-C API surface, Swift API surface, sample app documentation and automation, Swift formatting, package build, package tests, Release safety gates, documentation links, versioned public documentation, logging boundary claims, governance metadata, distribution documentation claims and tracked distribution artifacts, release helper script dry-runs, release content audit, DocC conversion, iOS package build, Swift and Objective-C sample app builds, source archive creation, source archive contents, and source archive build/test from a temporary extraction. GitHub workflows set `CONSOLEDOCK_RUN_UI_SMOKE=1` so the focused Swift and Objective-C sample UI smoke tests also run in CI.

Release helper dry-runs use `CONSOLEDOCK_RELEASE_TAG` when set, use `GITHUB_REF_NAME` when the workflow is running on a tag, and otherwise default to `v0.1.0` for local main-branch validation.

## Manual Sample Smoke Check

GitHub release validation runs the focused Swift and Objective-C sample UI smoke tests automatically. For local release rehearsals, run at least one iOS Simulator smoke check before the first public release in a minor series:

1. Launch `SwiftSampleApp`.
2. Generate native, stdout, stderr, and `NSLog` entries.
3. Confirm generated `token=...` values are displayed as `token=<redacted>`.
4. Open the ConsoleDock panel.
5. Verify search, source filter, level filter, pause/resume, selected-entry copy, share, clear, stop, and restart behavior.
6. Run `scripts/validate-objc-sample-ui-smoke.sh` when Objective-C compatibility changed.

## Tag And Validate

Create an annotated tag only after local validation passes and `origin/main` points at the same commit as local `HEAD`:

```sh
python3 scripts/validate-public-release-preflight.py --tag v0.1.0
scripts/validate-release.sh
git tag -a v0.1.0 -m "ConsoleDock v0.1.0"
git push origin v0.1.0
```

The `Release Validation` GitHub Actions workflow runs on `v*` tags. It verifies:

- semantic version tag shape;
- matching `CHANGELOG.md` release heading;
- cleared `Unreleased` changelog section;
- the same release validation script used locally and by CI.

Do not publish a GitHub Release until the tag workflow passes.

## GitHub Release Notes

Use the matching changelog section as the source of truth. Keep release notes factual:

```markdown
## ConsoleDock v0.1.0

### Highlights

- In-app UIKit debug console for iOS test/debug use.
- Objective-C-compatible core plus Swift facade.
- stdout/stderr capture with pass-through and safe restore.
- Local in-memory storage with redaction before storage, copy, and share.
- Release builds disabled by default.

### Boundaries

- Not a full replacement for Xcode Console.
- Does not promise complete Swift Logger, os_log, or Apple unified logging capture.
- No default persistence, upload, network inspector, CocoaPods, or XCFramework distribution.

### Validation

- Link to the passing Release Validation workflow run.
```

## After Publishing

1. Run the post-release verifier:

```sh
python3 scripts/verify-public-release.py --repository <OWNER>/ConsoleDock --tag v0.1.0 --check-spi
```

The verifier retries transient network failures such as GitHub API EOFs and connection timeouts, but it still treats persistent missing releases, missing workflow runs, missing tags, and unavailable Swift Package Index pages as failures.
If Swift Package Index returns a Cloudflare access challenge to automated HTTP checks, manually open both the package and DocC pages in a browser. After that manual confirmation, rerun the verifier with `--allow-spi-challenge` to keep the rest of the automated checks strict while recording the SPI challenge as a warning:

```sh
python3 scripts/verify-public-release.py --repository <OWNER>/ConsoleDock --tag v0.1.0 --check-spi --allow-spi-challenge
```

2. Verify Xcode can add the repository URL as a Swift Package dependency at the tag.
3. Verify the `ConsoleDock` and `ConsoleDockCore` products resolve.
4. Open the generated DocC archive locally if documentation changed materially.
5. Run `CONSOLEDOCK_RUN_UI_SMOKE=1 scripts/validate-release.sh`, `scripts/validate-swift-sample-ui-smoke.sh`, or `scripts/validate-objc-sample-ui-smoke.sh` when validating a minor release on a machine with an available iOS Simulator.
6. Submit or verify the package on Swift Package Index after the public repository URL and release tag are available. Use Swift Package Index's current package request issue flow instead of opening a direct PackageList pull request.
7. Confirm Swift Package Index hosts DocC documentation for the `ConsoleDock` target declared in `.spi.yml`.
8. Leave the working tree clean.

## Patch Or Rollback

For public releases, prefer a new patch tag such as `v0.1.1` over changing or deleting `v0.1.0`.

Only delete or move a tag when it was never public, never announced, and no consumer could have resolved it.
