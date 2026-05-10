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
assert_contains "$field_a" "briskly:plan" "claude-code mode injects skill content"
absent_field_a_cursor=$(echo "$output_a" | jq -r '.additional_context // "absent"')
absent_field_a_top=$(echo "$output_a" | jq -r '.additionalContext // "absent"')
assert_eq "$absent_field_a_cursor" "absent" "claude-code mode does NOT emit top-level additional_context"
assert_eq "$absent_field_a_top" "absent" "claude-code mode does NOT emit top-level additionalContext"

# Mode 2: CURSOR_PLUGIN_ROOT set → expect top-level additional_context
output_b=$(CURSOR_PLUGIN_ROOT="$PWD" bash "$SCRIPT")
field_b=$(echo "$output_b" | jq -r '.additional_context // empty')
assert_contains "$field_b" "briskly:plan" "cursor mode injects skill content"
absent_field_b_hook=$(echo "$output_b" | jq -r '.hookSpecificOutput // "absent"')
absent_field_b_top=$(echo "$output_b" | jq -r '.additionalContext // "absent"')
assert_eq "$absent_field_b_hook" "absent" "cursor mode does NOT emit hookSpecificOutput"
assert_eq "$absent_field_b_top" "absent" "cursor mode does NOT emit top-level additionalContext"

# Mode 3: COPILOT_CLI set → expect top-level additionalContext
output_c=$(CLAUDE_PLUGIN_ROOT="$PWD" COPILOT_CLI="1" bash "$SCRIPT")
field_c=$(echo "$output_c" | jq -r '.additionalContext // empty')
assert_contains "$field_c" "briskly:plan" "copilot-cli mode injects skill content"
absent_field_c_cursor=$(echo "$output_c" | jq -r '.additional_context // "absent"')
absent_field_c_hook=$(echo "$output_c" | jq -r '.hookSpecificOutput // "absent"')
assert_eq "$absent_field_c_cursor" "absent" "copilot-cli mode does NOT emit additional_context"
assert_eq "$absent_field_c_hook" "absent" "copilot-cli mode does NOT emit hookSpecificOutput"

# Cleanup stub if we created it
if (( STUB_CREATED == 1 )); then rm -f skills/using-briskly/SKILL.md; rmdir skills/using-briskly 2>/dev/null || true; fi

test_summary
