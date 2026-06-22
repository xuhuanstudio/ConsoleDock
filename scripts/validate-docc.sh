#!/usr/bin/env bash
set -euo pipefail

archive_path="${1:-.build/ConsoleDock.doccarchive}"

rm -rf "$archive_path"

swift package dump-symbol-graph --minimum-access-level public --skip-synthesized-members

symbol_graph_dir="$(find .build -type d -name symbolgraph | head -n 1)"
if [[ -z "$symbol_graph_dir" ]]; then
  echo "error: SwiftPM did not emit a symbolgraph directory" >&2
  exit 1
fi

xcrun docc convert Sources/ConsoleDock/Documentation.docc \
  --additional-symbol-graph-dir "$symbol_graph_dir" \
  --output-dir "$archive_path" \
  --fallback-display-name ConsoleDock \
  --fallback-bundle-identifier io.github.consoledock.ConsoleDock \
  --fallback-default-module-kind framework \
  --default-code-listing-language swift \
  --warnings-as-errors
