#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tests/lib/assert.sh

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping marketplace tests"
  exit 0
fi

MANIFEST=".claude-plugin/marketplace.json"

assert_file_exists "$MANIFEST"

if [[ -f "$MANIFEST" ]]; then
  plugins_count=$(jq -r '.plugins | length' "$MANIFEST")
  first_name=$(jq -r '.plugins[0].name // empty' "$MANIFEST")
  first_source=$(jq -r '.plugins[0].source // empty' "$MANIFEST")
  assert_eq "$plugins_count" "1" "marketplace lists exactly one plugin"
  assert_eq "$first_name" "briskly" "first plugin is briskly"
  assert_contains "$first_source" "." "plugin source field present"
fi

test_summary
