#!/usr/bin/env bash
# Minimal bash assert helpers for briskly tests.
# Usage: source tests/lib/assert.sh; assert_eq "$got" "$want" "label"

set -euo pipefail

_RED=$'\033[0;31m'
_GREEN=$'\033[0;32m'
_RESET=$'\033[0m'

_test_count=0
_test_failed=0

assert_eq() {
  local got="$1"; local want="$2"; local label="${3:-}"
  _test_count=$((_test_count + 1))
  if [[ "$got" == "$want" ]]; then
    printf "  %sPASS%s %s\n" "$_GREEN" "$_RESET" "$label"
  else
    _test_failed=$((_test_failed + 1))
    printf "  %sFAIL%s %s\n    expected: %s\n    got: %s\n" "$_RED" "$_RESET" "$label" "$want" "$got"
  fi
}

assert_contains() {
  local haystack="$1"; local needle="$2"; local label="${3:-}"
  _test_count=$((_test_count + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    printf "  %sPASS%s %s\n" "$_GREEN" "$_RESET" "$label"
  else
    _test_failed=$((_test_failed + 1))
    printf "  %sFAIL%s %s\n    needle: %s\n    in: %s\n" "$_RED" "$_RESET" "$label" "$needle" "$haystack"
  fi
}

assert_file_exists() {
  local path="$1"; local label="${2:-file exists: $path}"
  _test_count=$((_test_count + 1))
  if [[ -f "$path" ]]; then
    printf "  %sPASS%s %s\n" "$_GREEN" "$_RESET" "$label"
  else
    _test_failed=$((_test_failed + 1))
    printf "  %sFAIL%s %s\n" "$_RED" "$_RESET" "$label"
  fi
}

assert_exit_code() {
  local got="$1"; local want="$2"; local label="${3:-}"
  _test_count=$((_test_count + 1))
  if [[ "$got" == "$want" ]]; then
    printf "  %sPASS%s %s\n" "$_GREEN" "$_RESET" "$label"
  else
    _test_failed=$((_test_failed + 1))
    printf "  %sFAIL%s %s (exit %s, wanted %s)\n" "$_RED" "$_RESET" "$label" "$got" "$want"
  fi
}

test_summary() {
  local passed=$((_test_count - _test_failed))
  printf "\n%d passed, %d failed of %d total\n" "$passed" "$_test_failed" "$_test_count"
  if (( _test_failed > 0 )); then exit 1; fi
}
