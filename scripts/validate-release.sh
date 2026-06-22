#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

archive_path="${CONSOLEDOCK_SOURCE_ARCHIVE:-.build/ConsoleDock-source.zip}"

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

section "Validate Swift formatting"
scripts/validate-swift-format.sh

section "Build Swift package"
swift build

section "Run Swift package tests"
swift test

section "Test Release safety defaults"
swift test -c release --filter ConsoleDockCoreTests/testReleaseBuild

section "Test Release explicit opt-in gate"
swift test -c release -Xcc -DCONSOLEDOCK_ENABLE_RELEASE -Xswiftc -DCONSOLEDOCK_ENABLE_RELEASE --filter ConsoleDockCoreTests/testReleaseBuild

section "Validate documentation links"
python3 scripts/validate-doc-links.py

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

section "Validate source archive"
rm -f "$archive_path"
swift package archive-source --output "$archive_path"
test -s "$archive_path"
python3 scripts/audit-source-archive.py "$archive_path"
ls -lh "$archive_path"

section "Release validation passed"
