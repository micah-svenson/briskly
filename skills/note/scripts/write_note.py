#!/usr/bin/env python3
"""write_note.py — write a note to <project-path>/.briskly/notes/.

Usage:
  write_note.py <project-path> <slug> <body-file>

  <project-path> — absolute path to the target project root
  <slug>         — already-derived filename slug, e.g. `2026-05-10-my-note`
                   (no `.md` extension, no path separators). Claude derives the
                   slug; this script only enforces uniqueness.
  <body-file>    — path to a file containing the full note body
                   (frontmatter + heading + markdown). Read-and-write,
                   verbatim — no rewriting. Pass `-` to read body from stdin.

Behavior (per design.md "Bundled scripts" + "Safety guards"):
  - Refuses target paths that resolve to $HOME, /, /tmp, /var/tmp.
  - Creates `<project-path>/.briskly/notes/` if absent.
  - On filename collision (`<slug>.md` already exists), appends `-2`, `-3`,
    etc. until a free name is found. Never overwrites silently.
  - Prints the absolute path of the written file on stdout.

Exit codes:
  0 — success
  1 — usage / IO error
  2 — refused target path (safety guard)
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Resolved-path values that the skill must refuse to write under.
# We compare against the canonical absolute path of <project-path>.
def forbidden_targets() -> set[str]:
    home = os.path.expanduser("~")
    targets = {"/", home, "/tmp", "/var/tmp"}
    # Also include canonicalized forms (macOS /tmp → /private/tmp etc.)
    canon: set[str] = set()
    for t in targets:
        canon.add(t)
        try:
            canon.add(str(Path(t).resolve(strict=False)))
        except OSError:
            pass
    return canon


def is_forbidden(project_path: Path) -> bool:
    try:
        canonical = str(project_path.resolve(strict=False))
    except OSError:
        canonical = str(project_path)
    raw = str(project_path)
    forbidden = forbidden_targets()
    return canonical in forbidden or raw in forbidden


def validate_slug(slug: str) -> str | None:
    """Returns an error message if slug is invalid, else None."""
    if not slug:
        return "slug is empty"
    if slug.endswith(".md"):
        return "slug must not include the .md extension"
    if "/" in slug or "\\" in slug:
        return "slug must not contain path separators"
    if slug in (".", ".."):
        return "slug must not be . or .."
    if slug.startswith("."):
        return "slug must not start with '.'"
    return None


def find_unique_path(notes_dir: Path, slug: str) -> Path:
    """First free path among <slug>.md, <slug>-2.md, <slug>-3.md, ..."""
    candidate = notes_dir / f"{slug}.md"
    if not candidate.exists():
        return candidate
    n = 2
    while True:
        candidate = notes_dir / f"{slug}-{n}.md"
        if not candidate.exists():
            return candidate
        n += 1


def read_body(body_arg: str) -> str:
    if body_arg == "-":
        return sys.stdin.read()
    p = Path(body_arg)
    if not p.is_file():
        raise FileNotFoundError(f"body file does not exist: {p}")
    with p.open("r", encoding="utf-8") as f:
        return f.read()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Write a note to <project-path>/.briskly/notes/ for briskly:note.",
    )
    parser.add_argument("project_path", help="Absolute path to the target project root")
    parser.add_argument("slug", help="Filename slug (no .md), e.g. 2026-05-10-my-note")
    parser.add_argument(
        "body_file",
        help="Path to a file containing the full note body (frontmatter + body), or '-' for stdin",
    )
    args = parser.parse_args(argv)

    project_path = Path(args.project_path).expanduser()
    if not project_path.is_absolute():
        print(
            f"error: project_path must be absolute: {project_path}",
            file=sys.stderr,
        )
        return 1

    if is_forbidden(project_path):
        print(
            f"error: refusing to write notes under {project_path} "
            "(matches a forbidden target: $HOME, /, /tmp, /var/tmp)",
            file=sys.stderr,
        )
        return 2

    if not project_path.is_dir():
        print(f"error: project_path is not a directory: {project_path}", file=sys.stderr)
        return 1

    slug_err = validate_slug(args.slug)
    if slug_err:
        print(f"error: invalid slug: {slug_err}", file=sys.stderr)
        return 1

    try:
        body = read_body(args.body_file)
    except (FileNotFoundError, OSError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    notes_dir = project_path / ".briskly" / "notes"
    try:
        notes_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"error: could not create {notes_dir}: {e}", file=sys.stderr)
        return 1

    target = find_unique_path(notes_dir, args.slug)
    try:
        # Use exclusive create — final defense against a race-condition overwrite.
        with open(target, "x", encoding="utf-8") as f:
            f.write(body)
    except FileExistsError:
        # Vanishingly unlikely after find_unique_path; recover by re-resolving.
        target = find_unique_path(notes_dir, args.slug)
        with open(target, "x", encoding="utf-8") as f:
            f.write(body)
    except OSError as e:
        print(f"error: could not write {target}: {e}", file=sys.stderr)
        return 1

    print(str(target.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
