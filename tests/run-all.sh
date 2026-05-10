#!/usr/bin/env bash
# Discover and run every tests/test-*.sh

set -euo pipefail
cd "$(dirname "$0")/.."

failed=0
ran=0
for f in tests/test-*.sh; do
  [[ ! -f "$f" ]] && continue
  ran=$((ran + 1))
  echo "== $f"
  if bash "$f"; then
    :
  else
    failed=$((failed + 1))
  fi
done

if (( ran == 0 )); then
  echo "No tests found."
  exit 0
fi
if (( failed > 0 )); then
  echo "$failed test file(s) failed."
  exit 1
fi
echo "All $ran test file(s) passed."
