#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tests/lib/assert.sh

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping hook tests"
  exit 0
fi

SCRIPT="hooks/session-start"
assert_file_exists "$SCRIPT"
assert_file_exists "hooks/hooks.json"
assert_file_exists "hooks/run-hook.cmd"
[[ ! -f "$SCRIPT" ]] && { test_summary; exit; }

# Ensure using-briskly/SKILL.md exists for the hook to read; create a stub if missing
mkdir -p skills/using-briskly
if [[ ! -f skills/using-briskly/SKILL.md ]]; then
  echo "stub-content-for-hook-test" > skills/using-briskly/SKILL.md
  STUB_CREATED=1
else
  STUB_CREATED=0
fi

# Mode 1: CLAUDE_PLUGIN_ROOT set → expect hookSpecificOutput.additionalContext
output_a=$(CLAUDE_PLUGIN_ROOT="$PWD" COPILOT_CLI="" bash "$SCRIPT")
field_a=$(echo "$output_a" | jq -r '.hookSpecificOutput.additionalContext // empty')
event_a=$(echo "$output_a" | jq -r '.hookSpecificOutput.hookEventName // empty')
assert_eq "$event_a" "SessionStart" "claude-code mode emits hookEventName=SessionStart"
assert_contains "$field_a" "stub-content-for-hook-test" "claude-code mode injects skill content"

# Mode 2: CURSOR_PLUGIN_ROOT set → expect top-level additional_context
output_b=$(CURSOR_PLUGIN_ROOT="$PWD" bash "$SCRIPT")
field_b=$(echo "$output_b" | jq -r '.additional_context // empty')
assert_contains "$field_b" "stub-content-for-hook-test" "cursor mode injects skill content"

# Mode 3: COPILOT_CLI set → expect top-level additionalContext
output_c=$(CLAUDE_PLUGIN_ROOT="$PWD" COPILOT_CLI="1" bash "$SCRIPT")
field_c=$(echo "$output_c" | jq -r '.additionalContext // empty')
assert_contains "$field_c" "stub-content-for-hook-test" "copilot-cli mode injects skill content"

# Cleanup stub if we created it
if (( STUB_CREATED == 1 )); then rm -f skills/using-briskly/SKILL.md; rmdir skills/using-briskly 2>/dev/null || true; fi

test_summary
