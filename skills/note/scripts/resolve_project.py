#!/usr/bin/env python3
"""resolve_project.py — resolve a project name to an absolute path.

Algorithm (per design.md "Project resolution"):
  1. Consult ~/.briskly/config.json first.
     - If `project_paths[<name>]` exists → use it.
     - Else for each root in `projects_roots`, check `<root>/<name>/`. First
       match wins; if multiple, treat as ambiguous between persisted roots.
  2. Otherwise probe the default candidate roots in order:
       ~/Projects, ~/projects, ~/Code, ~/code, ~/src, ~/dev, ~/work, ~/repos
     - One match → resolve silently.
     - Multiple matches → AMBIGUOUS.
     - Zero matches → NO_MATCH.

Prompt-and-persist semantics live in Claude (the calling agent), not in this
script. When ambiguity or no-match occurs, the script exits non-zero with a
structured stderr code that Claude parses, prompts the user inline, then
re-invokes the script with --persist-root or --persist-path to record the
choice and resolve.

Exit codes:
  0  — success; absolute path printed on stdout
  2  — AMBIGUOUS (multiple candidate roots contain <name>)
  3  — NO_MATCH (no candidate root contains <name>)
  1  — usage / IO error

Stderr contract (exit 2/3): single line starting with `AMBIGUOUS:` or
`NO_MATCH:` for machine parsing, followed by a human line.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

DEFAULT_ROOTS = [
    "~/Projects",
    "~/projects",
    "~/Code",
    "~/code",
    "~/src",
    "~/dev",
    "~/work",
    "~/repos",
]


def config_path() -> Path:
    return Path(os.path.expanduser("~/.briskly/config.json"))


def load_config() -> dict:
    p = config_path()
    if not p.is_file():
        return {}
    try:
        with p.open("r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {}
        return data
    except (json.JSONDecodeError, OSError) as e:
        print(f"warning: could not read {p}: {e}", file=sys.stderr)
        return {}


def save_config(data: dict) -> None:
    p = config_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")
    tmp.replace(p)


def expand_root(root: str) -> Path:
    return Path(os.path.expanduser(root))


def probe_roots(name: str, roots: list[str]) -> list[Path]:
    """Return absolute paths of <root>/<name>/ that exist as directories.

    Dedupes by inode so case-insensitive filesystems (default macOS APFS) don't
    return both `~/Projects/foo` and `~/projects/foo` as separate matches.
    """
    matches: list[Path] = []
    seen_inodes: set[tuple[int, int]] = set()
    for root in roots:
        expanded = expand_root(root)
        candidate = expanded / name
        if not candidate.is_dir():
            continue
        try:
            st = candidate.stat()
            key = (st.st_dev, st.st_ino)
        except OSError:
            key = None  # type: ignore[assignment]
        if key is not None and key in seen_inodes:
            continue
        if key is not None:
            seen_inodes.add(key)
        matches.append(candidate.resolve(strict=False))
    return matches


def resolve(name: str) -> tuple[int, str, str]:
    """Returns (exit_code, stdout, stderr)."""
    cfg = load_config()

    # 1a. Direct project_paths mapping.
    project_paths = cfg.get("project_paths", {}) if isinstance(cfg.get("project_paths"), dict) else {}
    direct = project_paths.get(name)
    if isinstance(direct, str) and direct:
        p = Path(os.path.expanduser(direct))
        if p.is_dir():
            return 0, str(p.resolve()), ""
        # Stale mapping — fall through to probing rather than silently using a
        # missing path.
        # Continue to roots.

    # 1b. Persisted roots first.
    persisted_roots = cfg.get("projects_roots", []) if isinstance(cfg.get("projects_roots"), list) else []
    persisted_roots = [r for r in persisted_roots if isinstance(r, str)]

    if persisted_roots:
        matches = probe_roots(name, persisted_roots)
        if len(matches) == 1:
            return 0, str(matches[0].resolve()), ""
        if len(matches) > 1:
            paths = ",".join(str(m.resolve()) for m in matches)
            return 2, "", (
                f"AMBIGUOUS:{paths}\n"
                f"Project '{name}' exists at multiple persisted roots: "
                + ", ".join(str(m.resolve()) for m in matches)
            )
        # 0 persisted matches → fall through to default roots.

    # 2. Default candidate roots, skipping any already covered by persisted roots.
    persisted_set = {str(expand_root(r).resolve(strict=False)) for r in persisted_roots}
    default_roots = [r for r in DEFAULT_ROOTS if str(expand_root(r).resolve(strict=False)) not in persisted_set]

    matches = probe_roots(name, default_roots)
    if len(matches) == 1:
        return 0, str(matches[0].resolve()), ""
    if len(matches) > 1:
        paths = ",".join(str(m.resolve()) for m in matches)
        return 2, "", (
            f"AMBIGUOUS:{paths}\n"
            f"Project '{name}' exists at multiple candidate roots: "
            + ", ".join(str(m.resolve()) for m in matches)
        )
    return 3, "", (
        f"NO_MATCH:{name}\n"
        f"No candidate root contains a directory named '{name}'."
    )


def persist_root(name: str, root: str) -> tuple[int, str, str]:
    """Add <root> to projects_roots and resolve <name> against it."""
    root_path = Path(os.path.expanduser(root))
    if not root_path.is_dir():
        return 1, "", f"--persist-root: {root_path} is not a directory"

    target = root_path / name
    if not target.is_dir():
        return 1, "", (
            f"--persist-root: {root_path} does not contain a directory named '{name}'"
        )

    cfg = load_config()
    roots = cfg.get("projects_roots") if isinstance(cfg.get("projects_roots"), list) else []
    roots = [r for r in roots if isinstance(r, str)]

    canonical_root = str(root_path.resolve())
    canonical_existing = {str(expand_root(r).resolve(strict=False)) for r in roots}
    if canonical_root not in canonical_existing:
        roots.append(canonical_root)
        cfg["projects_roots"] = roots
        try:
            save_config(cfg)
        except OSError as e:
            return 1, "", f"could not write {config_path()}: {e}"

    return 0, str(target.resolve()), ""


def persist_path(name: str, path: str) -> tuple[int, str, str]:
    """Add <name> → <path> to project_paths and return the resolved path."""
    p = Path(os.path.expanduser(path))
    if not p.is_dir():
        return 1, "", f"--persist-path: {p} is not a directory"

    cfg = load_config()
    project_paths = cfg.get("project_paths") if isinstance(cfg.get("project_paths"), dict) else {}
    project_paths[name] = str(p.resolve())
    cfg["project_paths"] = project_paths
    try:
        save_config(cfg)
    except OSError as e:
        return 1, "", f"could not write {config_path()}: {e}"
    return 0, str(p.resolve()), ""


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Resolve a project name to an absolute path for briskly:note.",
    )
    parser.add_argument("name", help="Project name to resolve")
    parser.add_argument(
        "--persist-root",
        metavar="ROOT",
        help=(
            "Persist ROOT to projects_roots and resolve <name> against it. "
            "Use after the user disambiguates between multiple candidate roots."
        ),
    )
    parser.add_argument(
        "--persist-path",
        metavar="PATH",
        help=(
            "Persist <name> -> PATH in project_paths and return PATH. "
            "Use after the user supplies an absolute path for a no-match name."
        ),
    )
    args = parser.parse_args(argv)

    if args.persist_root and args.persist_path:
        print("error: --persist-root and --persist-path are mutually exclusive", file=sys.stderr)
        return 1

    if args.persist_root:
        code, out, err = persist_root(args.name, args.persist_root)
    elif args.persist_path:
        code, out, err = persist_path(args.name, args.persist_path)
    else:
        code, out, err = resolve(args.name)

    if out:
        print(out)
    if err:
        print(err, file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
