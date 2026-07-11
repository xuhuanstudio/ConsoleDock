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

output_directory="${CONSOLEDOCK_SCREENSHOT_OUTPUT_DIR:-$PWD/docs/assets}"
result_bundle="${CONSOLEDOCK_SCREENSHOT_RESULT_BUNDLE:-$PWD/.build/ConsoleDockScreenshots.xcresult}"
attachment_directory="$PWD/.build/ConsoleDockScreenshotAttachments"
mkdir -p "$output_directory"
rm -rf "$result_bundle" "$attachment_directory"
rm -f \
  "$output_directory/swift-sample-logs.png" \
  "$output_directory/swift-sample-report.png" \
  "$output_directory/swift-sample-actions.png" \
  "$output_directory/swift-sample-timeline.png" \
  "$output_directory/swift-sample-context.png" \
  "$output_directory/swift-sample-archive.png"

printf 'Swift sample screenshot destination: %s\n' "$destination"
printf 'Swift sample screenshot output: %s\n' "$output_directory"
printf 'Swift sample screenshot result bundle: %s\n' "$result_bundle"

xcodebuild test \
  -project Examples/SwiftSampleApp/SwiftSampleApp.xcodeproj \
  -scheme SwiftSampleApp \
  -destination "$destination" \
  -resultBundlePath "$result_bundle" \
  -only-testing:SwiftSampleAppUITests/ConsoleDockSwiftSampleUITests/testCaptureDocumentationScreenshots

xcrun xcresulttool export attachments \
  --path "$result_bundle" \
  --output-path "$attachment_directory"

ATTACHMENT_DIRECTORY="$attachment_directory" \
OUTPUT_DIRECTORY="$output_directory" \
  python3 - <<'PY'
import json
import os
import pathlib
import shutil
import sys

attachment_directory = pathlib.Path(os.environ["ATTACHMENT_DIRECTORY"])
output_directory = pathlib.Path(os.environ["OUTPUT_DIRECTORY"])
manifest_path = attachment_directory / "manifest.json"

required_names = {
    "swift-sample-logs": "swift-sample-logs.png",
    "swift-sample-report": "swift-sample-report.png",
    "swift-sample-actions": "swift-sample-actions.png",
    "swift-sample-timeline": "swift-sample-timeline.png",
    "swift-sample-context": "swift-sample-context.png",
    "swift-sample-archive": "swift-sample-archive.png",
}
found: dict[str, pathlib.Path] = {}

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
for test in manifest:
    for attachment in test.get("attachments", []):
        suggested = attachment.get("suggestedHumanReadableName", "")
        exported = attachment.get("exportedFileName", "")
        for key in required_names:
            if suggested.startswith(f"{key}_") and exported:
                found[key] = attachment_directory / exported

missing = sorted(set(required_names) - set(found))
if missing:
    sys.exit(f"missing screenshot attachments: {', '.join(missing)}")

for key, output_name in required_names.items():
    source = found[key]
    if not source.exists():
        sys.exit(f"exported screenshot is missing: {source}")
    shutil.copyfile(source, output_directory / output_name)
    print(f"Wrote {output_directory / output_name}")
PY

python3 scripts/validate-doc-assets.py
