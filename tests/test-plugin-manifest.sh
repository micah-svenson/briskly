#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tests/lib/assert.sh

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping manifest tests"
  exit 0
fi

MANIFEST=".claude-plugin/plugin.json"

assert_file_exists "$MANIFEST"

if [[ -f "$MANIFEST" ]]; then
  name=$(jq -r '.name // empty' "$MANIFEST")
  version=$(jq -r '.version // empty' "$MANIFEST")
  description=$(jq -r '.description // empty' "$MANIFEST")
  assert_eq "$name" "briskly" "plugin name is briskly"
  assert_contains "$version" "." "version present and looks like semver"
  assert_contains "$description" "daily-driver" "description mentions daily-driver"
fi

test_summary
