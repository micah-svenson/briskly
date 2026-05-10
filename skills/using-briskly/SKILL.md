---
name: using-briskly
description: Daily-driver design-then-execute workflow for Claude Code. Reach for it on non-trivial-but-not-huge work where a reviewable design beats winging it but full superpowers ceremony is overkill.
---

# Using Briskly

Briskly is a Claude Code plugin that fills the gap between plan mode (no design discipline, no spec artifact) and superpowers (full brainstorm → writing-plans → executing-plans ceremony). It produces a single reviewable `design.md`, runs subagent-driven execution against it, and reviews the result automatically. The north star is minimizing user touchpoints while keeping correctness through structured automation — one human gate at the design→execute handoff, everything else automated.

## When to reach for briskly

- The work is non-trivial but not huge — a feature, a refactor, a bugfix with real moving parts. Not a one-liner; not a multi-week project.
- Designing before executing matters — there are choices to make, edge cases to nail down, or acceptance criteria worth writing down.
- You want subagent-driven development (sequential implementer subagents working from a shared spec) without the writing-plans pre-expanded execution-script overhead.
- You want a reviewable artifact: a `design.md` you can read, edit, or hand off, not a context-dependent in-memory plan.
- You want the review pattern (auto plan-coherence review on the design, single end-of-run review on the diff) without scaffolding it yourself.

## When NOT to use briskly

- **Trivial questions or one-line edits** — answer or edit directly. No skill invocation needed. Claude Code's plan mode is also fine for quick pre-work where a written design would be overkill.
- **Major projects warranting full superpowers pipeline** — multi-week features, large refactors, architecture changes, anything where you want explicit brainstorm → writing-plans → executing-plans → multi-stage review. Defer to `superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development`. Briskly is intentionally lighter than that.

## The three skills

| Skill | Purpose |
|---|---|
| `briskly:plan` | Calibrated grill (one question at a time, codebase-first, recommended answers paired) → reviewable `design.md` → auto plan-coherence review. Hands off to the user for approval. |
| `briskly:execute` | Reads an approved `design.md`, expands the execution outline into TodoWrite items, dispatches sequential implementer subagents, runs a single end-of-run review with auto-fix loop. |
| `briskly:research` | Async investigation, dispatched primarily from plan but user-invokable as `/briskly:research <topic>`. Output is `Findings / Sources / Confidence`. |

The pipeline: `briskly:plan → design.md → user approves → briskly:execute → shipped code`. Research feeds plan (and occasionally execute) as needed.

## How briskly composes with other tools

- **vs Claude Code plan mode:** briskly imposes design discipline and produces a reviewable spec. Plan mode is fine for trivial pre-work; reach for briskly when the work merits a written design and acceptance criteria.
- **vs superpowers:** briskly is intentionally lighter. Superpowers' full pipeline (brainstorming → writing-plans → executing-plans → multi-stage review) is the right tool when the work warrants that ceremony. Briskly is the daily-driver middle ground — single design.md, single end-of-run review, one human gate.
- **Coexistence:** briskly's skills are namespaced `briskly:*` and never collide with `superpowers:*`. Both plugins can be installed and active in the same session. Use whichever fits the task in front of you.

## Artifacts

Briskly writes to `.briskly/` at the cwd root:

- `.briskly/sessions/<YYYY-MM-DD-slug>/design.md` — the human-reviewable design. The only artifact that gates execute. Six sections: Problem, Approach, Acceptance criteria, Out of scope, Open questions / risks, Execution outline.
- `.briskly/sessions/<YYYY-MM-DD-slug>/notes.md` — subagent shared scratchpad during execute. Free-form, light convention, timestamped/task-tagged entries.
- `.briskly/research/<topic>-YYYY-MM-DD.md` — research artifacts. Cross-session reusable; date-stamped for freshness.

`.briskly/` is gitignored by default. Plan emits a one-line suggestion to commit when the design is significant enough to warrant project-history retention. The decision stays with the user.

## Outcome lines

Both review stages emit a single chat line so you can skim and move on:

- `plan-review: 3 issues auto-fixed, ✓ ready` or `plan-review: 1 blocking issue 🚨 <description>`
- `execute-review: ✓ all green` or `execute-review: 🚨 N unresolved after fix loop, <summary>`

A 🚨 line is the only thing that requires a decision from you. Everything else is auto-handled.
