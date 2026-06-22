#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

xcrun swift-format lint \
  --configuration .swift-format \
  --recursive \
  --parallel \
  --strict \
  Sources \
  Tests \
  Examples/SwiftSampleApp
