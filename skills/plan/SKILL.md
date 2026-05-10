---
name: plan
description: Design a feature, refactor, or bugfix before implementing. Use whenever the user says "let me plan X", "design Y", "before I build Z", or wants a reviewable spec before touching code.
---

# briskly:plan

A calibrated question pass (one question at a time, codebase-first, recommended answers paired) produces a reviewable `design.md`. An auto plan-coherence review runs immediately on the artifact. The user reads, approves, and manually invokes `briskly:execute`. The handoff is the single human gate that protects against runaway loops building the wrong thing.

## User-facing language

The user does not know briskly's internals — phrasing that requires that knowledge to make sense leaks the model and confuses them. Do not narrate this skill's inner mental model: do not reference question-pass calibration, "light" / "heavy", or comparisons to a baseline the user does not know exists. When narration is helpful, say something contextually useful about the next concrete step instead of meta-commentary about how this skill is calibrating itself. Example: "I have two questions, then I'll draft the design."

## Flow

1. **Read context.** Cwd state, recent git commits (skip with a one-line warning if the cwd is not a git repo — briskly still operates), any existing `.briskly/` artifacts (especially research files), the user's invocation message.
2. **Calibrated question pass.** Ask one question at a time. Each question paired with a recommended answer. Codebase-first: if a question can be answered by reading code, read it instead of asking. Question intensity scales inversely with context provided — a full pass from a one-liner; no further questions when the user provides a complete design paragraph.
3. **Approach selection.** Once scope is clear, propose 2–3 approaches with tradeoffs. Lead with your recommendation. User picks.
4. **Author design.md straight through.** No per-section approval interruptions. Write to `.briskly/sessions/<YYYY-MM-DD-slug>/design.md` (create the directory if needed).
5. **Auto plan-coherence review.** Dispatch a subagent with `prompts/plan-coherence-reviewer.md` filled in (`{{SPEC_PATH}}` replaced with the actual path).
6. **Emit outcome line** to chat:
   - `plan-review: <N> issues auto-fixed, ✓ ready` (when no blockers)
   - `plan-review: <M> blocking issue(s) 🚨 <first blocker>` (when blockers exist)
7. **Present to user.** File path + 2-3 sentence summary. **Do NOT auto-invoke execute** — the user must explicitly run `/briskly:execute`.

## Calibrated questions — heuristic

| Context provided in invocation | Question intensity |
|---|---|
| Empty or one-line | Full pass: problem framing, approach options, AC, edges |
| Partial (problem stated, no approach) | Ask only on the gaps |
| Complete design paragraph | No further questions — draft directly |
| Codebase-answerable question | Read the code instead of asking |

The reason this matters: every question is a user touchpoint, and briskly's whole pitch is fewer touchpoints than full superpowers ceremony. More upfront context from the user (or from the codebase) means fewer questions later. If the user already provided the design, asking it back at them is friction without value.

Each question presented to the user must include a recommended answer. Format:

`<question>? My recommendation: <answer>. <one-line reason>. Push back if not.`

## Approach selection

Once scope is clear, propose 2–3 approaches:

```
A) <approach>: <one-line tradeoff>
B) <approach>: <one-line tradeoff>
C) <approach>: <one-line tradeoff>

I lean A. <reason in one sentence>.
```

Lead with the recommended option and explain why.

## design.md sections (template)

Every design.md must have these six sections, in this order:

1. **Problem** — one paragraph: what we're solving and why now.
2. **Approach** — chosen design as prose. Architecture, key components, data flow if non-trivial.
3. **Acceptance criteria** — testable assertions including edge cases and negative cases. Tests written by execute pin to these.
4. **Out of scope** — explicit NOTs.
5. **Open questions / risks** — known unknowns, things execute may defer back.
6. **Execution outline** — 5–10 one-liners. No code, no per-substep checkboxes. Format: "Add X to Y", "Wire Z handler", "Add tests for W edge cases".

## Plan-coherence review

After design.md is written, dispatch `prompts/plan-coherence-reviewer.md` with `{{SPEC_PATH}}` filled in. The reviewer:
- Auto-fixes typos, missing AC, prose-outline mismatches, untestable AC phrasing
- Escalates internal contradictions and missing source-of-truth info
- Returns a structured outcome with N auto-fixed and M blocking

Translate the structured outcome into the chat outcome line per the Flow step 6 format.

If M > 0: present the blocker(s) to the user. Decision: address now / defer to execute / proceed as-is. Do not write the design.md again unless the user picks "address now."

If M = 0: proceed to handoff.

## Handoff

End the plan session with these four pieces, in order:

1. The file path: `.briskly/sessions/<id>/design.md`
2. A 2-3 sentence summary of the design (what gets built, the chosen approach, anything notable about scope)
3. The outcome line from plan-coherence review
4. A line: `Run /briskly:execute when ready to ship.`

If the design is significant enough to warrant project-history retention (e.g., it captures non-obvious architecture decisions or risk tradeoffs), append a one-line suggestion: `Consider committing this session — remove .briskly/sessions/<id>/ from .gitignore if you want the design tracked.` The decision stays with the user.

Do NOT auto-invoke execute.

## Slug rules

Session ID = `YYYY-MM-DD-<topic-slug>` where the slug is:
- Lowercase
- Non-alphanumerics replaced with `-`
- Runs of `-` collapsed
- Leading/trailing `-` trimmed
- Capped at 60 chars

Topic is derived from the user's invocation (first noun phrase) or asked during the question pass if unclear.

## Research mixin

When the question pass needs to investigate something, dispatch `briskly:research` async (see `skills/research/SKILL.md`). Plan continues asking questions on independent branches while research runs. When research returns, plan reads the artifact and may cite it in the design.md.

If plan reads a research artifact older than 30 days during context-loading, surface a one-line freshness note.

## What this skill does NOT do

- Per-section approval during drafting (no mid-draft interruptions)
- Auto-invoke execute (manual handoff only — protects against runaway loops building the wrong thing)
- Modify files outside `.briskly/sessions/<id>/`
- Block on plan-coherence review when M=0 (proceed silently)
