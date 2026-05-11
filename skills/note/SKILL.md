---
name: note
description: Capture a note, issue, idea, or piece of feedback to a project's .briskly/notes/ directory — current project (cwd) or another (`to:<name>` or "note for briskly that..."). Triggers on "leave a note", "capture this", "remember this for later", "file feedback for X", "make a note about Y", "archive that note", or `/briskly:note`. Mid-flow capture during other work is the whole point. Also load when the user asks about existing notes ("what notes do I have", "find the note about X", "any notes about Y") so the storage convention is available for the read path. Skip when the user explicitly references a different note system (Obsidian, Notion, Apple Notes, etc.).
---

# briskly:note

Captures the user's stray observation as an enriched markdown note in the right project's `.briskly/notes/` directory, without diverting the current session. Conversational invocation is primary; the slash form (`/briskly:note <body>` or `/briskly:note to:<project> <body>`) is the same pipeline. Also handles archiving when the user says "archive that note about X".

## User-facing language

The user does not know briskly's internals — phrasing that requires that knowledge to make sense leaks the model and confuses them. Do not narrate this skill's inner mental model: do not say "running the enrichment pass", "consulting `resolve_project.py`", "probing candidate roots", or "writing via `write_note.py`". Say something contextually useful about the result instead. Example: "Captured a note for briskly at `.briskly/notes/2026-05-10-output-verbosity.md`." That's it. The script paths, the resolution algorithm, the slug-collision logic — none of that belongs in chat.

## Response format

Mirrors `docs/response-format.md`. If editing, propagate to all copies.

### Principles

- Lead with the answer. Recommendation first, reasoning after.
- Structured beats prose. One thought per line; bullets over paragraphs when both fit.
- Cap each line at one short sentence. If a thought needs two sentences, give it two lines.
- Use bold labels for the parts a user scans for: **Recommendation:**, **Why:**, **Alternative:**, **Push back if**.
- User CLAUDE.md or in-conversation instructions win when they conflict with this format.

### Default templates

Recommendation-style question:

````
<question>?

**Recommendation:** <answer>.
**Why:** <one-line reason>.
**Alternative:** <other option> — <when it would win>.
**Push back if** <signal that the recommendation is wrong>.
````

Approach selection (2–3 options):

````
A) <approach> — <one-line tradeoff>
B) <approach> — <one-line tradeoff>
C) <approach> — <one-line tradeoff>

**Recommendation:** A.
**Why:** <one-line reason>.
````

Handoff summary (end of plan / research / execute):

````
**Design ready:** `.briskly/sessions/<id>/design.md`
**Builds:** <one-line of what gets built>.
**Review:** <plan-coherence outcome line>.
**Next:** Run `/briskly:execute` when ready to ship.
````

End-of-session report (execute / research):

````
**Done:** <one-line of what shipped or what was found>.
**Files:** <paths touched, comma-separated>.
**Tests:** <pass/fail summary>.
**Follow-ups:** <anything deferred, or "none">.
````

### Examples

Bad — run-on prose that fuses recommendation, reasoning, and alternative into one sentence:

> For the mobile drop-up, my recommendation is to wrap the existing `<MobileActionSheet>` in a new `<ResponsiveActionMenu>` component that switches on viewport width so desktop still gets the popover and mobile gets the sheet, because that keeps the call sites unchanged and avoids forking the menu logic, though if you'd rather not introduce a new wrapper we could instead push the responsive switch down into `<MobileActionSheet>` itself and rename it, which is slightly more invasive but flatter.

Good — same content, restructured:

> **Recommendation:** Add a `<ResponsiveActionMenu>` wrapper that switches `<MobileActionSheet>` vs the existing popover on viewport width.
> **Why:** Call sites stay unchanged; menu logic doesn't fork.
> **Alternative:** Push the switch down into `<MobileActionSheet>` and rename it — flatter, but more invasive at the call sites.
> **Push back if** you'd rather not introduce a new wrapper component.

## Authoring craft

The point of this skill is to write a note that reads well *months later, in a different project, without the surrounding session context*. The user said one sentence; you turn that into a self-contained artifact.

- **Self-contained.** Name files, functions, error messages, links, version numbers. Don't leave dangling pronouns ("this", "the issue", "that bug"). A future reader has zero context.
- **Specific over generic.** "briskly:plan should not narrate calibration internals to the user" beats "improve briskly output."
- **Voice is first-person from the user.** These are the user's notes, not your third-person summary of what the user said.
- **Actionable when actionable.** If the note is a TODO/issue, include the obvious next step. If it's an observation, just say so — don't manufacture action items.
- **Session-context preserved when relevant.** "Came up while implementing X in quartery" — the why-this-came-up matters for prioritization later. Skip when irrelevant.

### Common failure modes

These are the ways a note ends up useless. Recognize them in your own draft before writing:

- **Verbatim or near-verbatim restatement** of what the user said. The user's input is a seed, not the note. Expand it.
- **Dangling references** — "this", "the issue", "that PR", "the bug we discussed" — without naming what `this` is. The future reader has zero context.
- **Manufactured action items.** If the user is just observing something, the note records the observation. Don't invent next steps that weren't there.
- **Asking the user for a title or filename.** You infer the slug from the content. Don't make capture into a question-and-answer session — that defeats mid-flow capture.
- **Probing the filesystem manually** to resolve a project name. Call `scripts/resolve_project.py` — it handles persistence, ambiguity, and case-insensitive macOS quirks correctly.
- **Generating frontmatter with a `source` field that equals the target.** Omit `source` entirely when source = target. `source: <same-name>` is noise.

### Worked example: thin paraphrase vs. enriched

*Bad (thin paraphrase):*

> User said: "output too verbose"
>
> Note body:
> ```
> The output is too verbose.
> ```

That's a useless note. Three weeks later, "the output" of *what*? Verbose how? Whose output?

*Good (enriched):*

> User said (while debugging `briskly:plan` in `~/Projects/briskly`): "output too verbose"
>
> Note body:
> ```
> Question phase in `briskly:plan` shouldn't narrate calibration
> internals to the user (e.g., "I'm running a calibrated question
> pass"). The user doesn't know briskly's internal model, so this
> leaks model details. Concrete fix: tighten the user-facing-language
> guard in `skills/plan/SKILL.md`. Came up while debugging the
> question-pass behavior.
> ```

Same input. The good version names the skill, names the bad behavior with a concrete example, names the file to fix, and preserves the why-this-came-up. Future reader understands it without re-reading the session.

## File format

Every note is a single markdown file with YAML-style frontmatter. Frontmatter is structural-only — no YAML parser is involved anywhere in the skill, the `---` delimiters are just visual separators.

```
---
date: 2026-05-10
source: quartery
tags: [output, briskly]
---

# Brief title

Body in markdown.
```

- `date`: ISO `YYYY-MM-DD`. Matches the filename's date prefix.
- `source`: cwd basename when the note was captured. **Omit the field entirely** when source = target (a note about the project you're already in). Do not write `source: <same-project>` and do not write `source: null`.
- `tags`: optional list. Author them when natural; do not solicit them from the user.
- Body: free-form markdown. The first line after frontmatter is a `# heading` titling the note.

## File layout

```
<target-project-root>/.briskly/notes/
├── YYYY-MM-DD-<slug>.md       # active notes
└── .archive/
    └── YYYY-MM-DD-<slug>.md   # archived notes (out of active context, retained)
```

One file per note. Date prefix sorts naturally. Slug derivation:

- Lowercase
- Non-alphanumerics replaced with `-`
- Runs of `-` collapsed
- Leading/trailing `-` trimmed
- Capped at 60 chars

If two notes resolve to the same `YYYY-MM-DD-<slug>.md` filename on the same day, `write_note.py` appends `-2`, `-3`, etc. — never silently overwrites. (You don't compute the suffix; the script does. You just pass the slug.)

## Project resolution

Default target = current project (cwd). Cross-project routing uses a `to:<name>` prefix when the user names another project — explicitly (`to:briskly`) or implicitly ("leave a note for briskly that..."). The deterministic algorithm — consult `~/.briskly/config.json`, probe `~/Projects/`, `~/projects/`, `~/Code/`, `~/code/`, `~/src/`, `~/dev/`, `~/work/`, `~/repos/` for `<name>/`, dedupe by inode — lives in `scripts/resolve_project.py`. You don't reimplement it; you call it.

### `to:` prefix parsing

`to:<token>` is a routing prefix only when:

1. It is the first whitespace-delimited token of the input, AND
2. `<token>` is a single non-whitespace word (no spaces inside the prefix).

Examples:

- `/briskly:note to:briskly the design feels right` → route to `briskly`, body is "the design feels right".
- `/briskly:note to: do this` → **not** a routing prefix (space after `to:`); body is `to: do this`.
- `/briskly:note remember to: ship the release` → **not** a routing prefix (`to:` is not the first token); body is the whole sentence.

Same rules for conversational form. "leave a note for briskly that ..." is implicit `to:briskly`; "leave a note: do this" is no routing prefix at all (no project named).

When in doubt about whether the user named a project, treat as no routing prefix and capture in the current project.

### The two-step script flow

`resolve_project.py` is fully non-interactive. It either succeeds (exit 0, prints absolute path on stdout) or returns a structured error code on stderr that you parse, prompt the user about inline, then re-invoke with a persistence flag. This two-step pattern is non-obvious, so internalize it:

**Step 1 — try to resolve:**

```
scripts/resolve_project.py <name>
```

**Step 2 — handle the structured stderr code:**

| Exit | First stderr line | What to do |
|---|---|---|
| 0 | (none) | Use the stdout path. Done. |
| 2 | `AMBIGUOUS:<path1>,<path2>,...` | Ask the user which root to persist (recommendation-style question). Re-invoke with `--persist-root <chosen-root>`. |
| 3 | `NO_MATCH:<name>` | Ask the user for the absolute path of `<name>` (recommendation-style question if you can recommend one from cwd context, else plain question). Re-invoke with `--persist-path <abs-path>`. |
| 1 | (other) | Surface the error. |

**Disambiguation prompt — ambiguous case (use the recommendation-style template):**

````
Which `<name>` do you mean?

A) `<path1>`
B) `<path2>`

**Recommendation:** A.
**Why:** <one-line reason — usually most-recently-modified, or matches the project you're in, or matches conversational context>.
**Push back if** you meant the other one — say "B" and I'll persist that root.
````

After the user picks, re-invoke: `scripts/resolve_project.py <name> --persist-root <chosen-root-without-the-name-suffix>`. The script persists the chosen root to `~/.briskly/config.json` and resolves.

**No-match prompt:**

````
I don't see `<name>` under any of the usual project roots. What's the absolute path?

**Recommendation:** `<best-guess-path-or-none>`.
**Why:** <one-line reason — e.g., closest match, or "no recommendation, please paste the path">.
````

After the user supplies a path, re-invoke: `scripts/resolve_project.py <name> --persist-path <abs-path>`. The script persists the `name → path` mapping under `project_paths` in `~/.briskly/config.json` and resolves.

### `~/.briskly/config.json` schema

Created lazily on the first `--persist-root` or `--persist-path` invocation. Schema:

```json
{
  "projects_roots": ["/Users/me/Projects"],
  "project_paths": {
    "weird-project": "/opt/work/weird-project"
  }
}
```

Persisted entries take precedence over default candidate roots on every invocation.

### Default-case (no `to:` prefix)

For the default case, just use cwd. Don't probe anything. If `<cwd>/.briskly/notes/` doesn't exist, `write_note.py` creates it. The cwd-not-under-any-project-root case is fine — write to `<cwd>/.briskly/notes/` without ceremony.

## Archiving

Notes are not deleted by the skill — they are *archived*. Moved out of active context but retained on disk under `.briskly/notes/.archive/`. Archive runs conversational-only (no slash form), because the disambiguation step needs context.

Flow when the user says "archive the note about X":

1. **Read candidates.** `ls .briskly/notes/*.md`, then `Read` (or `grep`) the candidates to match `X` against title/body content. Use base tools — no script for this match step.
2. **Disambiguate if multiple match.** Use the approach-selection template from Response format to list the candidates inline and ask the user to pick:

   ````
   Multiple notes match "<X>":

   A) `2026-05-10-foo.md` — <one-line title or first-line excerpt>
   B) `2026-05-08-bar.md` — <one-line title or first-line excerpt>

   **Recommendation:** A.
   **Why:** <one-line reason — usually best title/body match, or most recent>.
   ````

   No file moves until the user picks one.

3. **No matches.** Say so plainly. Do not create an empty `.archive/` directory. Do nothing else.

4. **Move.** Once a single note is identified, call `scripts/archive_note.py <project-path> <filename>`. The script moves `notes/<filename>.md` → `notes/.archive/<filename>.md`, lazy-creates `.archive/`, and refuses to overwrite an existing archived file.

5. **Confirm inline** with the moved path. (User-facing language: "Archived `<path>`." Don't narrate the script call.)

Archive is the single read-then-move action this skill performs. It does not require enrichment.

## Notes awareness

This skill is write-focused (plus the archive move). It does not ship a read/list/search subcommand — but it loads when the user asks about existing notes (per the description) precisely so the storage convention is in context for the read path.

When the user asks something like "what notes do I have for briskly?" or "is there a note about output verbosity?" or "find the note about polling", you (Claude) handle it directly with base tools. No script call. No skill subcommand. Just:

- `ls .briskly/notes/` to list (or `ls ~/Projects/briskly/.briskly/notes/` for cross-project — resolve the path with `scripts/resolve_project.py` if needed)
- `grep -ri 'polling' .briskly/notes/` to search bodies
- `Read` for individual files
- For routing across projects, the `to:<name>` resolution rules apply the same way as for capture

Storage convention you can rely on:

- Path pattern: `<project-root>/.briskly/notes/<YYYY-MM-DD>-<slug>.md`
- Frontmatter fields: `date` (ISO), `source` (cwd basename when captured, omitted when same as target), `tags` (optional list)
- Body: starts with a `# heading` line

**Default scope excludes archived notes.** When the user asks "what notes do I have?" / "any notes about X?" / "show me my notes for briskly", list and search only `.briskly/notes/*.md`. Do **not** include `.briskly/notes/.archive/*.md`.

Include archived notes only when the user explicitly opts in: "include archived", "show archived too", "search archived notes about X", "what's in the archive?". Then expand the scope to `.briskly/notes/.archive/*.md`.

## Safety guards

- The skill never edits or deletes existing notes. It only creates new notes (via `write_note.py`) and moves notes between `notes/` and `notes/.archive/` (via `archive_note.py`).
- The skill refuses to create `.briskly/notes/` under `$HOME`, `/`, `/tmp`, or `/var/tmp`. `write_note.py` enforces this and exits non-zero with a clear message; surface the error to the user, do not retry under a different path.
- The skill never writes outside the resolved project's `.briskly/notes/` (and its `.archive/` subdir), with the single exception of `~/.briskly/config.json` for first-time project resolution persistence.
- Archive disambiguation requires explicit user confirmation before moving any file. Never move on a guess.

## Bundled scripts

All deterministic mechanics live in `scripts/`. Call them; do not reimplement in shell.

**`scripts/resolve_project.py <name>`** — resolves a project name to an absolute path. Consults `~/.briskly/config.json` first, then probes default candidate roots. Exit 0 with the path on stdout, exit 2 (`AMBIGUOUS:<paths>` on stderr) for multiple matches, exit 3 (`NO_MATCH:<name>` on stderr) for zero matches. Use `--persist-root <root>` after the user disambiguates ambiguity, or `--persist-path <abs-path>` after the user supplies a path for a no-match.

```
$ scripts/resolve_project.py briskly
/Users/me/Projects/briskly                       # exit 0

$ scripts/resolve_project.py foo
AMBIGUOUS:/Users/me/Projects/foo,/Users/me/Code/foo
                                                  # exit 2 — ask user, then re-invoke
$ scripts/resolve_project.py foo --persist-root ~/Projects
/Users/me/Projects/foo                            # exit 0, root persisted

$ scripts/resolve_project.py weird
NO_MATCH:weird                                    # exit 3 — ask user, then re-invoke
$ scripts/resolve_project.py weird --persist-path /opt/work/weird
/opt/work/weird                                   # exit 0, mapping persisted
```

**`scripts/write_note.py <project-path> <slug> <body-file>`** — writes the note. Body comes from a file (or `-` for stdin); the script does **not** generate frontmatter or slug, you do. Slug must not include `.md`. Handles uniqueness collisions (`-2`, `-3`, ...). Exits 2 if `<project-path>` resolves to a forbidden target.

```
$ scripts/write_note.py /Users/me/Projects/briskly 2026-05-10-output-verbosity /tmp/note-body.md
/Users/me/Projects/briskly/.briskly/notes/2026-05-10-output-verbosity.md   # exit 0

$ scripts/write_note.py /Users/me/Projects/briskly 2026-05-10-output-verbosity /tmp/another.md
/Users/me/Projects/briskly/.briskly/notes/2026-05-10-output-verbosity-2.md # exit 0 (collision → -2)

$ scripts/write_note.py / 2026-05-10-foo /tmp/body.md
error: refusing to write notes under / (matches a forbidden target...)     # exit 2
```

Typical authoring flow: write the full note body (frontmatter + heading + markdown) to a temp file, then pass the temp file path. Or pipe via `-`:

```
$ scripts/write_note.py /Users/me/Projects/briskly 2026-05-10-foo - <<'EOF'
---
date: 2026-05-10
tags: [example]
---

# Foo

Body.
EOF
```

**`scripts/archive_note.py <project-path> <filename>`** — moves `notes/<filename>.md` to `notes/.archive/<filename>.md`. Filename accepted with or without `.md`. Lazy-creates `.archive/`. Exits 3 if the source is missing, exits 4 if the destination already exists (no silent overwrite).

```
$ scripts/archive_note.py /Users/me/Projects/briskly 2026-05-10-output-verbosity
/Users/me/Projects/briskly/.briskly/notes/.archive/2026-05-10-output-verbosity.md   # exit 0

$ scripts/archive_note.py /Users/me/Projects/briskly does-not-exist
error: source note does not exist: .../notes/does-not-exist.md             # exit 3
```
