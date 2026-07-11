#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

destination="${CONSOLEDOCK_UI_SMOKE_DESTINATION:-}"
if [[ -z "$destination" ]]; then
  destination="$(
    python3 - <<'PY'
import json
import subprocess
import sys

devices = json.loads(
    subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
)

for runtime in sorted(devices.get("devices", {}).keys(), reverse=True):
    for device in devices["devices"][runtime]:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            print(f"platform=iOS Simulator,id={device['udid']}")
            sys.exit(0)

sys.exit("no available iPhone simulator found")
PY
  )"
fi

printf 'Swift sample UI smoke destination: %s\n' "$destination"
iterations="${CONSOLEDOCK_UI_SMOKE_TEST_ITERATIONS:-2}"
if [[ ! "$iterations" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: CONSOLEDOCK_UI_SMOKE_TEST_ITERATIONS must be a positive integer." >&2
  exit 1
fi
printf 'Swift sample UI smoke test iterations: %s\n' "$iterations"

defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false || true

xcodebuild_arguments=(
  test
  -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj
  -scheme SwiftSampleApp
  -destination "$destination"
  -only-testing:SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests/testConsoleDockPanelSmokeFlow
  -only-testing:SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests/testSessionArchiveSharePresentationKeepsAppRunning
  -only-testing:SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests/testSupportReportComposerRemainsAvailableWithEmptyStore
  -only-testing:SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests/testSupportReportSharePresentationKeepsAppRunning
)
if ((iterations > 1)); then
  xcodebuild_arguments+=(
    -test-iterations "$iterations"
    -retry-tests-on-failure
  )
fi

xcodebuild "${xcodebuild_arguments[@]}"
