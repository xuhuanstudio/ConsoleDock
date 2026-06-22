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
git push -u origin main
```

After the first push:

1. Confirm the `CI` workflow runs on `main`.
2. Confirm the workflow uses `scripts/validate-release.sh`.
3. Confirm the repository landing page shows the README screenshot.
4. Confirm all documentation links resolve on GitHub.
5. Confirm no generated `.build` files, derived data, private logs, secrets, or local screenshots were pushed.

If branch protection is enabled, require the `CI` workflow after it has run successfully once.

## First Tag And Release

Only after the first `main` workflow passes:

```sh
python3 scripts/validate-release-metadata.py --tag v0.1.0
scripts/validate-release.sh
git status --short
git push origin main
git tag -a v0.1.0 -m "ConsoleDock v0.1.0"
git push origin v0.1.0
```

Wait for the `Release Validation` workflow on the pushed tag. Do not publish a GitHub Release until it passes.

Use the `v0.1.0` changelog section as the release notes source. Keep the release source-only; CocoaPods and XCFramework artifacts are future distribution channels.

## Post-Release Verification

After publishing the GitHub Release:

1. Create a temporary iOS app or use a clean sample workspace.
2. Add the public repository URL through Swift Package Manager at tag `v0.1.0`.
3. Confirm both products resolve:
   - `ConsoleDock`
   - `ConsoleDockCore`
4. Build the package in an iOS Simulator target.
5. Confirm the README, release notes, and `SECURITY.md` still describe the shipped behavior accurately.
6. Leave the local working tree clean.
