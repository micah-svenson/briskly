# Briskly — Starting Spec

**Status:** Starting spec. Expected to be refined through iteration before any code lands. Treat every section as draftable.
**Date:** 2026-05-09
**Parent context:** Cross-plugin vision in `grovework/docs/agentic-workflow-vision.md`. Read that for the full ecosystem framing. This spec covers briskly only.

---

## 1. Purpose

Briskly is a structured-yet-speedy workflow plugin for Claude Code. It is the **daily driver** — used constantly, with low ceremony — and is designed to fill the gap between:

- **Claude Code plan mode**, which is too basic (no design discipline, no review, no spec)
- **superpowers**, which is too heavy for everyday work (full brainstorm/spec/plan/execute/review pipeline with persistent artifacts even when you just want to ship something small)

The discipline briskly imposes is real (you brainstorm before executing; review happens) but the artifacts are transient and the friction is low.

## 2. Positioning

Briskly works **standalone**. It does not require any other plugin.

The two supported composition points are optional and additive:

- **briskly + grovemind**: threads make briskly sessions resumable across days/weeks. Most useful when work pauses.
- **briskly inside grovework Implement**: a heavy-loop task may invoke a briskly session for an inline sub-task. Supported but not the primary use.

Briskly is **not** a "lighter tier" of grovework. It is a separate plugin with its own discipline, lifecycle, and skills.

## 3. The shape

```
   ┌─────────────────┐    spec
   │ briskly:        │ ◀────review
   │ brainstorm      │
   └────────┬────────┘
            ▼
   ┌─────────────────┐    review
   │ briskly:        │ ◀──subagent
   │ execute         │
   └────────┬────────┘
            ▼
          Done
       (artifacts archived or discarded)
```

### Stages

**Brainstorm** — quick interrogation/grilling that produces a working spec. The output is a transient spec good enough to drive execution. Lighter than superpowers' full brainstorming — fewer mandatory questions, no formal design doc, no on-disk persistence required.

**Execute** — subagent-driven implementation against the spec. Produces shipped code. Self-review during execution; independent review on demand.

**Done** — the working spec is archived (if worth keeping) or discarded (most common). Nothing persists by default.

## 4. Initial skills

Three skills to start. Add when real use surfaces gaps; do not preemptively design for needs that haven't appeared.

| Skill                | Purpose                                                                                  |
|----------------------|------------------------------------------------------------------------------------------|
| `briskly:brainstorm` | Quick interrogation → working spec. Drives toward "good enough to execute," not "complete." |
| `briskly:execute`    | Subagent-driven impl from the spec, with self-review before reporting done.              |
| `briskly:review`     | Independent review subagent against the working spec.                                    |

The naming pattern (`briskly:` namespace, verb skill name) is intentional — invocations read as "briskly brainstorm," "briskly execute," "briskly review." The prefix grammatically modifies the verb, reinforcing the daily-driver positioning.

## 5. Artifacts

**Transient by default.** A briskly session creates a working spec in memory or in a temporary location. On completion:

- If the work was worth preserving (significant decision, reusable design), it gets explicitly saved.
- Otherwise, it's discarded.

Briskly does **not** maintain a permanent artifact tree like grovework does. No `define.md`, no `design.md`, no task subfolders, no acceptance criteria checklists. The framework's value is in the *flow* (brainstorm → execute → review), not in the artifact trail.

## 6. Composition

### Standalone (most common)

User invokes `briskly:brainstorm` to quickly design what they're about to build. Spec emerges in conversation. User invokes `briskly:execute` to ship. Done. No threads, no milestones.

### With grovemind

Same flow, but a thread is created (or auto-suggested) at session start. If work pauses, the thread holds journey-state. Resume next day, thread reactivates, briskly session picks back up.

### Inside grovework

A grovework Implement-phase task hits a sub-problem that warrants quick design. The user invokes briskly inline, runs the brainstorm → execute cycle, and resumes the grovework task. The briskly session is scoped to the sub-problem; its artifacts (if any) live within the grovework task's working area.

## 7. What briskly is NOT

- Not a replacement for plan mode (briskly has design discipline; plan mode does not)
- Not a tier of grovework (separate plugin, separate concerns)
- Not phase-based (no Define/Design/Implement/Closeout)
- Not coupled to any project (briskly sessions can run anywhere — a project, scratch space, `/tmp`)
- Not catch-crop with a new name (catch-crop targets autonomous bug-report → completion; briskly is broader and lighter)
- Not a heavy framework with a "lite mode" — briskly is the whole thing

## 8. Open questions

To be resolved during iteration / before build:

- **Brainstorm depth / exit criterion.** What signals "spec is good enough to execute"? Is it a hard heuristic, a user gate, or both?
- **Review trigger.** Is review automatic after execute, on demand only, or configurable?
- **Spec location.** When the working spec needs to be on disk (subagent handoff), where does it live? `~/.briskly/sessions/<id>/spec.md`? Inside the working directory? Configurable?
- **Session lifecycle.** Is a briskly "session" a first-class concept (with start/end/resume), or just an implicit container?
- **Composition with grovemind threads.** Does a thread for a briskly session contain the spec, or does it just point at the session and let briskly own the spec?
- **Failure handling.** When `briskly:execute` fails, what's the path? Re-brainstorm? Retry? Triage?
- **Skill verbs beyond the initial three.** Is `briskly:plan` needed (between brainstorm and execute)? `briskly:research` for ad-hoc lookups? Hold these until real use surfaces the need.
- **Marketplace publishing.** Public plugin in the Claude Code marketplace, or private/personal use only?

## 9. Design principles

These ground truths constrain the build:

1. **Standalone is the primary use.** Every design choice optimizes for "briskly works alone, no threads, no other plugins." Composition is additive, not load-bearing.
2. **Friction is the enemy.** Briskly is a daily driver. Any step that makes a user hesitate to invoke it is a problem. Defaults must be sane; required input must be minimal.
3. **Discipline is real but light.** Briskly is not just "do whatever." Brainstorm before execute. Review at least once. The discipline is what distinguishes briskly from plan mode. But the discipline is not heavy — fewer steps, less ceremony, no required artifacts.
4. **Transient by default.** Nothing persists unless explicitly saved. The framework does not accumulate clutter.
5. **Skill verbs over framework concepts.** Users invoke `briskly:brainstorm` and `briskly:execute`. They do not think about "phases" or "modes." The skill verbs are the surface.
6. **Three skills to start; add from real use.** Theoretically-useful skills accumulate as clutter. Ship the minimum, observe gaps, add when justified.

## 10. Reference: parent vision

The full architecture this plugin is part of is in:

```
grovework/docs/agentic-workflow-vision.md
```

Key sections of that doc that inform briskly:

- "Architecture overview: three independent plugins" — the trinity framing
- "briskly — mini loop" — the longer description that this spec extracts from
- "How layers compose: scenarios" — Scenarios B (briskly with thread) and E (briskly as default)
- "Where this leaves us" — the suggested build order (briskly first)

Updates to either doc should keep the other in sync, but they serve different purposes: this spec is the build target for briskly itself; the vision doc is the cross-plugin north star.

---

## Refinement plan

Before code:

1. Resolve open questions above (Section 8) through discussion / further design
2. Decide on session-lifecycle model (Section 8 question)
3. Finalize skill list and per-skill behavior
4. Define interaction patterns between briskly and grovemind threads (the most concrete composition point)
5. Write a build plan with ordered tasks

Once those are nailed: build the plugin, smallest viable scope first.
