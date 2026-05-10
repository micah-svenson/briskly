#!/usr/bin/env bash
# tests/test-note-scripts.sh — exercise the briskly:note bundled helpers.
#
# Each script is invoked with HOME pointed at an isolated temp dir so the
# user's real ~/.briskly/config.json is never touched.
#
# Pinned acceptance criteria (see .briskly/sessions/2026-05-10-note-skill/design.md):
#   AC 5  — single-match resolution is silent
#   AC 6  — ambiguous resolution exits non-zero with structured stderr
#   AC 7  — no-match resolution exits non-zero with structured stderr
#   AC 8  — persisted resolutions take precedence
#   AC 9  — target dir auto-created; refuse $HOME, /, /tmp
#   AC 10 — slug uniqueness via -2/-3 suffix
#   AC 13 — (covered by SKILL.md/Claude, not these scripts; noted here for traceability)
#   AC 16 — archive no-match: no empty .archive/ created on no-op
#   AC 20 — bundled scripts present, executable, and handle documented errors

set -euo pipefail
cd "$(dirname "$0")/.."
source tests/lib/assert.sh

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not installed; skipping note-scripts tests"
  exit 0
fi

REPO_ROOT="$PWD"
RESOLVE="$REPO_ROOT/skills/note/scripts/resolve_project.py"
WRITE="$REPO_ROOT/skills/note/scripts/write_note.py"
ARCHIVE="$REPO_ROOT/skills/note/scripts/archive_note.py"

assert_file_exists "$RESOLVE" "resolve_project.py exists (AC 20)"
assert_file_exists "$WRITE"   "write_note.py exists (AC 20)"
assert_file_exists "$ARCHIVE" "archive_note.py exists (AC 20)"

# Executable bit (AC 20)
[[ -x "$RESOLVE" ]] && rx=0 || rx=1; assert_exit_code "$rx" "0" "resolve_project.py is executable (AC 20)"
[[ -x "$WRITE"   ]] && wx=0 || wx=1; assert_exit_code "$wx" "0" "write_note.py is executable (AC 20)"
[[ -x "$ARCHIVE" ]] && ax=0 || ax=1; assert_exit_code "$ax" "0" "archive_note.py is executable (AC 20)"

# Per-test isolated HOME so the real ~/.briskly/config.json is untouched.
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/briskly-note.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT

# ---------------------------------------------------------------------------
# resolve_project.py
# ---------------------------------------------------------------------------

# AC 5: single-match resolution is silent (one root contains <name>).
home1="$tmp_root/h1"
mkdir -p "$home1/Projects/uniqproj"
out=$(HOME="$home1" "$RESOLVE" uniqproj 2>/dev/null)
code=$?
assert_exit_code "$code" "0" "AC 5: single-match resolves silently (exit 0)"
assert_eq "$out" "$(cd "$home1/Projects/uniqproj" && pwd -P)" "AC 5: stdout is absolute project path"

# AC 7: no-match → exit 3 with NO_MATCH stderr code.
home2="$tmp_root/h2"
mkdir -p "$home2"
set +e
err=$(HOME="$home2" "$RESOLVE" nothere 2>&1 >/dev/null)
code=$?
set -e
assert_exit_code "$code" "3" "AC 7: no-match exits 3"
assert_contains "$err" "NO_MATCH:nothere" "AC 7: stderr starts with NO_MATCH:<name>"

# AC 6: ambiguous match → exit 2 with AMBIGUOUS stderr code listing both paths.
home3="$tmp_root/h3"
mkdir -p "$home3/Projects/ambproj" "$home3/Code/ambproj"
set +e
err=$(HOME="$home3" "$RESOLVE" ambproj 2>&1 >/dev/null)
code=$?
set -e
assert_exit_code "$code" "2" "AC 6: ambiguous match exits 2"
assert_contains "$err" "AMBIGUOUS:" "AC 6: stderr starts with AMBIGUOUS:"
assert_contains "$err" "Projects/ambproj" "AC 6: stderr includes Projects candidate"
assert_contains "$err" "Code/ambproj"     "AC 6: stderr includes Code candidate"

# AC 8: persistence round-trip — --persist-root writes config, subsequent
# invocations resolve silently against the persisted root.
out=$(HOME="$home3" "$RESOLVE" --persist-root "$home3/Projects" ambproj 2>/dev/null)
code=$?
assert_exit_code "$code" "0" "AC 8: --persist-root resolves and persists"
assert_eq "$out" "$(cd "$home3/Projects/ambproj" && pwd -P)" "AC 8: --persist-root returns persisted match"
assert_file_exists "$home3/.briskly/config.json" "AC 8: ~/.briskly/config.json lazy-created"

# Subsequent silent resolve via the persisted root.
# Add a *new* project under the persisted root and resolve it silently.
mkdir -p "$home3/Projects/persisted-after"
out=$(HOME="$home3" "$RESOLVE" persisted-after 2>/dev/null)
code=$?
assert_exit_code "$code" "0" "AC 8: persisted root resolves new name silently"
assert_eq "$out" "$(cd "$home3/Projects/persisted-after" && pwd -P)" "AC 8: persisted-after stdout"

# --persist-path (no-match flow)
home4="$tmp_root/h4"
mkdir -p "$home4" "$tmp_root/weird/oddproj"
out=$(HOME="$home4" "$RESOLVE" --persist-path "$tmp_root/weird/oddproj" oddproj 2>/dev/null)
code=$?
assert_exit_code "$code" "0" "AC 7: --persist-path resolves and persists name->path"
assert_eq "$out" "$(cd "$tmp_root/weird/oddproj" && pwd -P)" "AC 7: --persist-path returns mapped path"
out2=$(HOME="$home4" "$RESOLVE" oddproj 2>/dev/null)
code2=$?
assert_exit_code "$code2" "0" "AC 8: persisted project_paths takes precedence on next run"
assert_eq "$out2" "$(cd "$tmp_root/weird/oddproj" && pwd -P)" "AC 8: persisted project_paths returns mapped path"

# ---------------------------------------------------------------------------
# write_note.py
# ---------------------------------------------------------------------------

# AC 9: target dir auto-created; AC 10: slug uniqueness collision suffix.
proj="$tmp_root/proj1"
mkdir -p "$proj"
body="$tmp_root/body.md"
printf -- "---\ndate: 2026-05-10\n---\n\n# T\n\nBody.\n" > "$body"

out1=$("$WRITE" "$proj" "2026-05-10-collide" "$body")
out2=$("$WRITE" "$proj" "2026-05-10-collide" "$body")
out3=$("$WRITE" "$proj" "2026-05-10-collide" "$body")
assert_eq "$(basename "$out1")" "2026-05-10-collide.md"   "AC 10: first note uses bare slug"
assert_eq "$(basename "$out2")" "2026-05-10-collide-2.md" "AC 10: second note appends -2"
assert_eq "$(basename "$out3")" "2026-05-10-collide-3.md" "AC 10: third note appends -3"
assert_file_exists "$proj/.briskly/notes/2026-05-10-collide.md"   "AC 9 + 10: notes dir auto-created, file exists"
assert_file_exists "$proj/.briskly/notes/2026-05-10-collide-2.md" "AC 10: -2 file exists"
assert_file_exists "$proj/.briskly/notes/2026-05-10-collide-3.md" "AC 10: -3 file exists"

# AC 9: refuse forbidden targets ($HOME, /, /tmp, /var/tmp).
fake_home="$tmp_root/fakehome"
mkdir -p "$fake_home"
set +e
HOME="$fake_home" "$WRITE" "$fake_home" "x" "$body" >/dev/null 2>&1
code_home=$?
"$WRITE" "/" "x" "$body" >/dev/null 2>&1
code_root=$?
"$WRITE" "/tmp" "x" "$body" >/dev/null 2>&1
code_tmp=$?
"$WRITE" "/var/tmp" "x" "$body" >/dev/null 2>&1
code_vartmp=$?
set -e
assert_exit_code "$code_home"   "2" "AC 9: refuse \$HOME as target"
assert_exit_code "$code_root"   "2" "AC 9: refuse / as target"
assert_exit_code "$code_tmp"    "2" "AC 9: refuse /tmp as target"
assert_exit_code "$code_vartmp" "2" "AC 9: refuse /var/tmp as target"

# Stdin body path (`-`)
out_stdin=$(printf "stdin body\n" | "$WRITE" "$proj" "2026-05-10-stdin" -)
assert_eq "$(basename "$out_stdin")" "2026-05-10-stdin.md" "write_note: stdin body works"
assert_eq "$(cat "$out_stdin")" "stdin body" "write_note: stdin body content matches"

# Reject slug with .md extension or path separators.
set +e
"$WRITE" "$proj" "bad.md" "$body" >/dev/null 2>&1; code_ext=$?
"$WRITE" "$proj" "bad/slash" "$body" >/dev/null 2>&1; code_slash=$?
set -e
assert_exit_code "$code_ext"   "1" "write_note: rejects slug ending in .md"
assert_exit_code "$code_slash" "1" "write_note: rejects slug with path separator"

# ---------------------------------------------------------------------------
# archive_note.py
# ---------------------------------------------------------------------------

# Archive happy path: source moves into .archive/, .archive/ created lazily.
out_arch=$("$ARCHIVE" "$proj" "2026-05-10-collide-2")
assert_eq "$(basename "$out_arch")" "2026-05-10-collide-2.md" "archive: returns new path basename"
[[ -f "$proj/.briskly/notes/.archive/2026-05-10-collide-2.md" ]] && a1=0 || a1=1
assert_exit_code "$a1" "0" "archive: file moved into .archive/"
[[ ! -e "$proj/.briskly/notes/2026-05-10-collide-2.md" ]] && a2=0 || a2=1
assert_exit_code "$a2" "0" "archive: source removed from notes/"

# Archive accepts filename with explicit .md too.
out_arch2=$("$ARCHIVE" "$proj" "2026-05-10-collide-3.md")
assert_eq "$(basename "$out_arch2")" "2026-05-10-collide-3.md" "archive: accepts filename with .md"

# AC 16: archive missing-source — error, no empty .archive/ created on no-op.
proj2="$tmp_root/proj2"
mkdir -p "$proj2/.briskly/notes"
set +e
"$ARCHIVE" "$proj2" "missing-note" >/dev/null 2>&1
code_miss=$?
set -e
assert_exit_code "$code_miss" "3" "AC 16: archive missing source exits 3"
[[ ! -e "$proj2/.briskly/notes/.archive" ]] && a3=0 || a3=1
assert_exit_code "$a3" "0" "AC 16: no .archive/ created on no-op"

# Archive overwrite refusal: re-create the source after it's been archived,
# then attempt to archive again — destination already exists in .archive/.
cp "$proj/.briskly/notes/.archive/2026-05-10-collide-2.md" \
   "$proj/.briskly/notes/2026-05-10-collide-2.md"
set +e
"$ARCHIVE" "$proj" "2026-05-10-collide-2" >/dev/null 2>&1
code_ow=$?
set -e
assert_exit_code "$code_ow" "4" "archive: refuses silent overwrite when destination exists"
[[ -f "$proj/.briskly/notes/2026-05-10-collide-2.md" ]] && a4=0 || a4=1
assert_exit_code "$a4" "0" "archive: source preserved when overwrite refused"

test_summary
