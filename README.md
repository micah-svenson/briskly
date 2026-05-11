# Briskly

Daily-driver design-then-execute workflow for Claude Code. One reviewable design, one human gate, subagent-driven implementation, single end-of-run review focused on behavior.

## How briskly works

Three steps:

1. **Design.** `/briskly:plan` runs a calibrated question pass — one question at a time, codebase-first, with a recommended answer paired so you can usually say "yes" or redirect. Output is a six-section prose `design.md` (Problem, Approach, Acceptance criteria, Out of scope, Open questions / risks, Execution outline). A plan-coherence review runs silently and emits one outcome line.
2. **Approve.** You read the design end-to-end — usually under 3 minutes — and edit or approve. This is the only human gate.
3. **Execute.** `/briskly:execute` expands the execution outline into TodoWrite items and dispatches sequential implementer subagents that work from the design. A single end-of-run review validates the diff against the acceptance criteria and behavior tests, auto-fixes what it can, and only escalates real blockers.

Plus an orthogonal capture primitive — `/briskly:note` — for mid-flow notes, bugs, ideas, or feedback that you want recorded without diverting the current task.

The name is the goal: **brisk** — thorough enough to improve outcomes, quick enough to reach for every day.

## Behavior-based testing

Briskly's testing philosophy is behavior-first: tests describe what the system *does* from an external observer's perspective — inputs, outputs, observable side effects — not how it's wired internally.

This shows up in three places:

- **Acceptance criteria are testable behaviors.** The `design.md` Acceptance criteria section is a list of behavioral assertions, including edge cases and negatives. They are the contract between design and implementation.
- **Tests pin to acceptance criteria.** Implementer subagents write tests that reference the AC they cover. Tests verify real behaviors, not toy assertions.
- **Review checks behavior, not style.** The end-of-run reviewer validates that every AC has real test coverage and that the diff satisfies the design's intent. It is not a stylistic gauntlet — refactors that preserve behavior survive review.

The result: tests survive refactors, the design stays the source of truth, and TDD is encouraged where it earns its keep without being forced as ceremony.

## What's different

- **One human gate.** Approve the design, execution starts. No "now write the plan" step. No pre-expanded execution script you'd never read.
- **Reviewable prose design.** Six sections, end-to-end readable in a few minutes. The artifact is the contract between you and the implementer subagents.
- **Single end-of-run review.** Validates against design + behavior tests, auto-fixes what it can, escalates only real blockers. One outcome line back to chat.
- **Subagent-driven implementation.** Sequential implementer subagents keep main-context usage low.
- **Lightweight by design.** More structured than ad-hoc plan mode, less ceremony than full multi-stage workflow plugins. The middle ground for daily work.

## Where it fits

Plan mode produces a plan artifact, but it's intentionally lightweight — fine for trivial pre-work, not enough structure for anything with real moving parts.

Heavier workflow plugins like `superpowers:*` are excellent when the work warrants full ceremony — multi-week features, large refactors, architecture changes. Briskly is intentionally lighter than that: it skips the post-spec "write the plan" step, the unread pre-expanded plan file, and multi-stage review pipelines. For changes that don't earn that ceremony, the lighter loop is the point.

## When NOT to use briskly

- **Trivial questions or one-line edits** — answer or edit directly. Plan mode is also fine for quick pre-work.
- **Major projects** — multi-week features, large refactors, architecture changes. Reach for a heavier workflow plugin when the work warrants the full brainstorm → plan → execute → multi-stage review pipeline.

## Install

```bash
/plugin marketplace add micah-svenson/briskly
/plugin install briskly@briskly
```

Restart your Claude Code session to activate the SessionStart hook.

## The skills

Three core workflow primitives plus one helper:

| Skill | Role | What it does |
|---|---|---|
| `/briskly:plan` | core | Calibrated question pass → reviewable `design.md` → auto plan-coherence review |
| `/briskly:execute` | core | Subagent-driven implementation from `design.md` → end-of-run review with auto-fix |
| `/briskly:note` | core | Lightweight in-session capture of a note, issue, idea, or feedback to the current or another project's `.briskly/notes/` |
| `/briskly:research` | helper | Async investigation, dispatched primarily from plan but user-invokable too |

### When to reach for note

Use `briskly:note` when you're mid-task and want to capture something — a bug to look at later, an idea about another project, feedback about a tool you're using — without breaking the current flow. It enriches the capture with whatever session context is live (file paths, function names, source-of-thought) and writes a self-contained markdown file. Cross-project routing is built in: from any project, "leave a note for briskly that..." resolves the briskly project's path and writes there. Notes never get deleted by the skill — archive them via `.briskly/notes/.archive/` to retire from active context.

## Typical use

```
/briskly:plan add a per-user rate limiter to the API
   <calibrated question pass — usually a few questions; less if you provided context>
   <design.md written to .briskly/sessions/<id>/design.md>
   <plan-coherence review runs silently; ✓ outcome line>
   <user reviews the design — usually under 3 minutes>

/briskly:execute
   <TodoWrite shows live progress>
   <subagents implement task by task>
   <single review subagent at the end validates against the design + behavior tests, auto-fixes what it can>
   <execute-review: ✓ all green>
```

## Artifacts

Briskly writes to `.briskly/` at the cwd root:

```
.briskly/
├── sessions/<YYYY-MM-DD-slug>/
│   ├── design.md      # human-reviewable design
│   └── notes.md       # subagent shared scratchpad during execute
├── research/<topic>-YYYY-MM-DD.md
└── notes/
    ├── <YYYY-MM-DD-slug>.md    # captured notes for this project
    └── .archive/
        └── <YYYY-MM-DD-slug>.md  # archived (out of active context, retained)
```

`.briskly/` is gitignored by default. Commit it when project history is valuable. To retire all notes wholesale, delete the `.briskly/` directory (or `.briskly/notes/` specifically).

## Coexistence

All briskly skills are namespaced `briskly:*` and never collide with other plugins. Briskly works fully standalone and composes additively with anything else you have installed.

## Versioning

Briskly uses explicit semver in `.claude-plugin/plugin.json`. Each push to main bumps the version (CI enforces this for skill/hook changes). Run `/plugin marketplace update briskly` to pick up new versions.

## Status

v1.1.1. See `docs/spec.md` for the broader design.

## License

MIT.
