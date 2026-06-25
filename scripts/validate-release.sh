#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

archive_path="${CONSOLEDOCK_SOURCE_ARCHIVE:-.build/ConsoleDock-source.zip}"
release_tag="${CONSOLEDOCK_RELEASE_TAG:-}"
if [[ -z "$release_tag" && "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
  release_tag="${GITHUB_REF_NAME:-}"
fi
if [[ -z "$release_tag" ]]; then
  release_tag="$(
    python3 - <<'PY'
import pathlib
import re

changelog = pathlib.Path("CHANGELOG.md").read_text(encoding="utf-8")
release_heading = re.compile(r"^## \[?(v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)\]?(?:\s|-|$)")
for line in changelog.splitlines():
    match = release_heading.match(line)
    if match:
        print(match.group(1))
        break
PY
  )"
fi
if [[ -z "$release_tag" ]]; then
  echo "error: could not resolve release tag; set CONSOLEDOCK_RELEASE_TAG." >&2
  exit 1
fi

section() {
  printf '\n==> %s\n' "$1"
}

section "Show Swift version"
swift --version

section "Validate clean working tree"
if [[ -n "$(git status --short)" ]]; then
  echo "error: release validation requires a clean working tree because source archive creation uses Git state." >&2
  git status --short >&2
  exit 1
fi

section "Validate package manifest"
swift package dump-package

section "Validate package identity"
python3 scripts/validate-package-identity.py

section "Validate Swift Package Index metadata"
python3 scripts/validate-spi-manifest.py

section "Validate Objective-C API surface"
python3 scripts/validate-objc-api-surface.py --self-test
python3 scripts/validate-objc-api-surface.py

section "Validate Swift API surface"
python3 scripts/validate-swift-api-surface.py --self-test
python3 scripts/validate-swift-api-surface.py

section "Validate UI accessibility identifiers"
python3 scripts/validate-ui-accessibility-identifiers.py

section "Validate sample app documentation and automation"
python3 scripts/validate-sample-apps.py

section "Validate Swift formatting"
scripts/validate-swift-format.sh

section "Build Swift package"
swift build

section "Run Swift package tests"
swift test

section "Test Release safety defaults"
swift test -c release --filter testReleaseBuild

section "Test Release explicit opt-in gate"
swift test -c release -Xcc -DCONSOLEDOCK_ENABLE_RELEASE -Xswiftc -DCONSOLEDOCK_ENABLE_RELEASE --filter testReleaseBuild

section "Validate documentation links"
python3 scripts/validate-doc-links.py

section "Validate versioned public documentation"
python3 scripts/validate-versioned-docs.py --self-test
python3 scripts/validate-versioned-docs.py

section "Validate logging boundary documentation"
python3 scripts/validate-logging-boundaries.py --self-test
python3 scripts/validate-logging-boundaries.py

section "Validate governance metadata"
python3 scripts/validate-governance-metadata.py

section "Validate distribution documentation and artifacts"
python3 scripts/validate-distribution-docs.py --self-test
python3 scripts/validate-distribution-docs.py

section "Validate release helper scripts"
printf 'Release helper tag: %s\n' "$release_tag"
python3 scripts/validate-release-metadata.py --self-test
python3 scripts/validate-public-release-preflight.py --self-test
python3 scripts/validate-public-release-preflight.py --tag "$release_tag" --local-only --dry-run
python3 scripts/verify-public-release.py --self-test
python3 scripts/verify-public-release.py --repository example/ConsoleDock --tag "$release_tag" --dry-run --check-spi

section "Audit release content"
python3 scripts/audit-release-content.py

section "Build DocC documentation"
scripts/validate-docc.sh

section "Build package for iOS Simulator"
xcodebuild -scheme ConsoleDock-Package -destination 'generic/platform=iOS Simulator' build

section "Build Swift sample app"
xcodebuild -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj \
  -scheme SwiftSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build

section "Build Objective-C sample app"
xcodebuild -project Examples/ObjCSampleApp/ObjCSampleApp.xcodeproj \
  -scheme ObjCSampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build

if [[ "${CONSOLEDOCK_RUN_UI_SMOKE:-0}" == "1" ]]; then
  section "Run Swift sample UI smoke test"
  scripts/validate-swift-sample-ui-smoke.sh
  section "Run Objective-C sample UI smoke test"
  scripts/validate-objc-sample-ui-smoke.sh
else
  section "Skip sample UI smoke tests"
  echo "Set CONSOLEDOCK_RUN_UI_SMOKE=1 to run the simulator UI smoke tests."
fi

section "Validate source archive"
rm -f "$archive_path"
swift package archive-source --output "$archive_path"
test -s "$archive_path"
python3 scripts/audit-source-archive.py "$archive_path"
python3 scripts/validate-source-archive-package.py "$archive_path"
ls -lh "$archive_path"

section "Release validation passed"
