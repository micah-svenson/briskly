#!/usr/bin/env python3
"""archive_note.py — move a note to .briskly/notes/.archive/.

Usage:
  archive_note.py <project-path> <filename>

  <project-path> — absolute path to the target project root
  <filename>     — base filename of the note (with or without `.md`)

Behavior (per design.md "Bundled scripts" + AC 14, 16):
  - Moves <project-path>/.briskly/notes/<filename> →
          <project-path>/.briskly/notes/.archive/<filename>
  - Lazy-creates `.archive/` on first use.
  - Errors if the source file does not exist.
  - Errors if the destination already exists (no silent overwrite).
  - Prints the new absolute path on stdout.

Exit codes:
  0 — success
  1 — usage / IO error
  3 — source missing
  4 — destination already exists
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path


def normalize_filename(filename: str) -> str:
    """Accept `note` or `note.md`; reject path separators."""
    if "/" in filename or "\\" in filename:
        raise ValueError("filename must not contain path separators")
    if not filename or filename in (".", ".."):
        raise ValueError("filename must be a real basename")
    if filename.startswith("."):
        raise ValueError("filename must not start with '.'")
    if not filename.endswith(".md"):
        filename = f"{filename}.md"
    return filename


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Move a note from .briskly/notes/ to .briskly/notes/.archive/.",
    )
    parser.add_argument("project_path", help="Absolute path to the target project root")
    parser.add_argument("filename", help="Note filename (with or without .md)")
    args = parser.parse_args(argv)

    project_path = Path(args.project_path).expanduser()
    if not project_path.is_absolute():
        print(f"error: project_path must be absolute: {project_path}", file=sys.stderr)
        return 1
    if not project_path.is_dir():
        print(f"error: project_path is not a directory: {project_path}", file=sys.stderr)
        return 1

    try:
        filename = normalize_filename(args.filename)
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    notes_dir = project_path / ".briskly" / "notes"
    src = notes_dir / filename
    if not src.is_file():
        print(f"error: source note does not exist: {src}", file=sys.stderr)
        return 3

    archive_dir = notes_dir / ".archive"
    dst = archive_dir / filename
    if dst.exists():
        print(
            f"error: destination already exists: {dst} "
            "(refusing silent overwrite)",
            file=sys.stderr,
        )
        return 4

    try:
        archive_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"error: could not create {archive_dir}: {e}", file=sys.stderr)
        return 1

    try:
        shutil.move(str(src), str(dst))
    except OSError as e:
        print(f"error: could not move {src} -> {dst}: {e}", file=sys.stderr)
        return 1

    print(str(dst.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
