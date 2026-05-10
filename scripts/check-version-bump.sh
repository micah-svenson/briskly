#!/usr/bin/env bash
# Fails (exit 1) when skills/** or hooks/** changed between two git refs
# but .claude-plugin/plugin.json's "version" did not.
#
# Usage: check-version-bump.sh <base_ref> <head_ref>

set -euo pipefail

BASE="${1:-origin/main}"
HEAD="${2:-HEAD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required" >&2
  exit 2
fi

# Files changed between BASE and HEAD
changed=$(git diff --name-only "$BASE" "$HEAD" 2>/dev/null || true)
if [[ -z "$changed" ]]; then
  echo "No changes between $BASE and $HEAD"
  exit 0
fi

needs_bump=0
while IFS= read -r f; do
  case "$f" in
    skills/*|hooks/*) needs_bump=1; break ;;
  esac
done <<< "$changed"

if (( needs_bump == 0 )); then
  echo "No skill/hook changes; version bump not required."
  exit 0
fi

# Compare versions across the diff
get_version() {
  local ref="$1"
  git show "$ref:.claude-plugin/plugin.json" 2>/dev/null | jq -r '.version // empty' || true
}

base_v=$(get_version "$BASE")
head_v=$(get_version "$HEAD")

if [[ -z "$head_v" ]]; then
  echo "ERROR: cannot read version from $HEAD:.claude-plugin/plugin.json" >&2
  exit 2
fi

if [[ "$base_v" == "$head_v" ]]; then
  echo "ERROR: skills/ or hooks/ changed but plugin.json version not bumped (still $head_v)" >&2
  echo "Bump the 'version' field in .claude-plugin/plugin.json before merging." >&2
  exit 1
fi

echo "Version bumped: $base_v -> $head_v"
exit 0
