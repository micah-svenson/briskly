#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tests/lib/assert.sh

if ! command -v git >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "git/jq not installed; skipping version-bump tests"
  exit 0
fi

SCRIPT="./scripts/check-version-bump.sh"
assert_file_exists "$SCRIPT"
[[ ! -f "$SCRIPT" ]] && { test_summary; exit; }

# Build a synthetic git repo in tests/.tmp for each scenario
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/briskly-vbump.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT

setup_repo() {
  local repo="$1"
  rm -rf "$repo"
  mkdir -p "$repo/.claude-plugin" "$repo/skills/dummy" "$repo/hooks"
  cd "$repo"
  git init -q
  git config user.email "t@t"; git config user.name "t"
  echo '{"name":"x","version":"0.1.0","description":"x"}' > .claude-plugin/plugin.json
  echo "stub" > skills/dummy/SKILL.md
  echo "stub" > hooks/hooks.json
  git add . && git commit -q -m "base"
  cd - >/dev/null
}

# Scenario A: skill changed, no version bump → script must fail
repoA="$tmp_root/A"
setup_repo "$repoA"
( cd "$repoA"
  echo "edit" >> skills/dummy/SKILL.md
  git add skills/dummy/SKILL.md && git commit -q -m "edit skill"
)
set +e
( cd "$repoA" && bash "$OLDPWD/$SCRIPT" HEAD~1 HEAD ) > /dev/null 2>&1
codeA=$?
set -e
assert_exit_code "$codeA" "1" "scenario A: skill change without version bump fails"

# Scenario B: skill changed AND version bumped → script must pass
repoB="$tmp_root/B"
setup_repo "$repoB"
( cd "$repoB"
  echo "edit" >> skills/dummy/SKILL.md
  jq '.version = "0.2.0"' .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp
  mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json
  git add . && git commit -q -m "edit skill + bump"
)
set +e
( cd "$repoB" && bash "$OLDPWD/$SCRIPT" HEAD~1 HEAD ) > /dev/null 2>&1
codeB=$?
set -e
assert_exit_code "$codeB" "0" "scenario B: skill change with version bump passes"

# Scenario C: docs-only change, no skill/hook changes → script must pass
repoC="$tmp_root/C"
setup_repo "$repoC"
( cd "$repoC"
  echo "doc" > README.md
  git add README.md && git commit -q -m "doc only"
)
set +e
( cd "$repoC" && bash "$OLDPWD/$SCRIPT" HEAD~1 HEAD ) > /dev/null 2>&1
codeC=$?
set -e
assert_exit_code "$codeC" "0" "scenario C: docs-only change passes (no version bump needed)"

# Scenario D: hook changed, no version bump → script must fail
repoD="$tmp_root/D"
setup_repo "$repoD"
( cd "$repoD"
  echo "edit" >> hooks/hooks.json
  git add hooks/hooks.json && git commit -q -m "edit hook"
)
set +e
( cd "$repoD" && bash "$OLDPWD/$SCRIPT" HEAD~1 HEAD ) > /dev/null 2>&1
codeD=$?
set -e
assert_exit_code "$codeD" "1" "scenario D: hook change without version bump fails"

test_summary
