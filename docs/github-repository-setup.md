# GitHub Repository Setup

Use this checklist when turning the local ConsoleDock repository into the public source repository.

Do not create a public release until local validation, GitHub Actions, and the tag validation workflow have passed.

## Repository Identity

Recommended repository settings:

- Repository name: `ConsoleDock`
- Description: `In-app debug console for iOS testing`
- Visibility: public only after the local release checklist passes
- Default branch: `main`
- License: MIT, using the repository `LICENSE`

Recommended topics:

- `ios`
- `swift`
- `objective-c`
- `uikit`
- `debugging`
- `logging`
- `swift-package-manager`
- `spm`

Topics make the repository easier to discover by subject area.

Swift Package Index should use the checked-in `.spi.yml` file to build hosted DocC documentation with `ConsoleDock` as the landing target after the public repository and first tag are available.

## Repository Features

Enable:

- Issues, using the checked-in issue templates.
- Pull requests, using the checked-in pull request template.
- GitHub Actions, using the checked-in CI and release validation workflows.
- Private vulnerability reporting, if available for the repository.

Keep disabled unless there is a clear reason:

- Wiki, because project documentation lives in `README.md`, DocC, and `docs/`.
- Packages, because the first release is source-first Swift Package Manager.

Discussions are optional. Enable them only if you want a public support channel separate from issues.

## Security Settings

Before announcing the repository:

1. Confirm `SECURITY.md` renders correctly.
2. Enable private vulnerability reporting when GitHub offers it for the repository.
3. If private vulnerability reporting is not available, keep the fallback process in `SECURITY.md`: public issues may request coordination but must not include vulnerability details or sensitive logs.
4. Confirm issue templates warn users not to paste secrets, production logs, credentials, tokens, cookies, or customer data.

ConsoleDock is a debug SDK, so accidental sensitive data exposure, unsafe export behavior, Release-build activation, or private API usage should be treated as security-relevant.

## First Push

Create an empty GitHub repository without adding a README, license, or gitignore in the GitHub UI. Those files already exist locally.

Then add the remote and push:

```sh
git remote add origin <REMOTE_URL>
python3 scripts/validate-public-release-preflight.py --tag v0.1.0 --local-only
git push -u origin main
```

After the first push:

1. Confirm the `CI` workflow runs on `main`.
2. Confirm the workflow uses `scripts/validate-release.sh`.
3. Confirm the repository landing page shows the README screenshot.
4. Confirm all documentation links resolve on GitHub.
5. Confirm `scripts/audit-release-content.py` passes and no generated `.build` files, derived data, private logs, secrets, or local screenshots were pushed.

If branch protection is enabled, require the `CI` workflow after it has run successfully once.

## First Tag And Release

Only after the current local `HEAD` has been pushed to `origin/main` and that exact commit's `main` workflow has passed:

```sh
python3 scripts/validate-public-release-preflight.py --tag v0.1.0
python3 scripts/validate-release-metadata.py --tag v0.1.0
python3 scripts/audit-release-content.py
scripts/validate-release.sh
python3 scripts/audit-source-archive.py .build/ConsoleDock-source.zip
git status --short
git tag -a v0.1.0 -m "ConsoleDock v0.1.0"
git push origin v0.1.0
```

Wait for the `Release Validation` workflow on the pushed tag. Do not publish a GitHub Release until it passes.

Use the `v0.1.0` changelog section as the release notes source. Keep the release source-only; CocoaPods and XCFramework artifacts are future distribution channels.

## Post-Release Verification

After publishing the GitHub Release:

1. Run the automated public release verifier:

```sh
python3 scripts/verify-public-release.py --repository <OWNER>/ConsoleDock --tag v0.1.0 --check-spi
```

The verifier checks the GitHub repository, remote tag, GitHub Release, `Release Validation` workflow, a clean external SwiftPM consumer build, and Swift Package Index package/DocC pages when `--check-spi` is supplied.

2. Create a temporary iOS app or use a clean sample workspace when you need a manual Xcode UI check.
3. Add the public repository URL through Swift Package Manager at tag `v0.1.0`.
4. Confirm both products resolve:
   - `ConsoleDock`
   - `ConsoleDockCore`
5. Build the package in an iOS Simulator target.
6. Confirm the README, release notes, and `SECURITY.md` still describe the shipped behavior accurately.
7. Submit or verify the package on Swift Package Index after the public repository URL and release tag are available.
8. Confirm Swift Package Index builds the package and hosts DocC documentation for the `ConsoleDock` target.
9. Leave the local working tree clean.
