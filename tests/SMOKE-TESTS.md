# Briskly Smoke Tests

Manual checklist run after install. Each section maps to acceptance criteria in `docs/superpowers/specs/2026-05-09-briskly-design.md` §3. Skill content tasks append to this file as they are implemented.

## How to run

1. Install the plugin per README (`/plugin marketplace add micah-svenson/briskly`, `/plugin install briskly@briskly`)
2. Start a fresh Claude Code session to trigger the SessionStart hook
3. Walk through each section below, ticking items as you confirm them

---

<!-- Skill task sections appended below -->

## §3.4 SessionStart hook (using-briskly)

- [ ] After install + session restart, a `<system-reminder>` block appears at session start containing the using-briskly content.
- [ ] Hook content describes when to reach for briskly (non-trivial-but-not-huge work).
- [ ] Hook content names the three skills: `briskly:plan`, `briskly:execute`, `briskly:research`.
- [ ] Hook content explicitly defers to plan mode (for trivial questions) and to superpowers (for major projects requiring full pipeline).
- [ ] If superpowers is also installed, both `<system-reminder>` blocks appear without one shadowing the other.
- [ ] Hook content fits well under 200 lines (skim test).

## §3.3 briskly:research

- [ ] Direct invocation `/briskly:research <topic>` produces an artifact at `.briskly/research/<slug>-YYYY-MM-DD.md`.
- [ ] Artifact contains three labeled sections: **Findings**, **Sources**, **Confidence** (with one of: high / medium / low).
- [ ] Sources cite at least one piece of evidence (file path, URL, or excerpt).
- [ ] No auto-review subagent runs after research completes.
- [ ] When invoked from inside plan, dispatch is asynchronous (plan continues asking questions while research runs).
- [ ] When plan reads a research artifact older than 30 days, it surfaces a one-line freshness note to the user.

## §3.1 briskly:plan

### Calibrated grill

- [ ] One-line invocation (e.g., `/briskly:plan add a rate limiter`) → plan asks at least one clarifying question before drafting.
- [ ] Invocation containing a complete design paragraph (problem + approach + AC) → plan drafts directly, no grill questions.
- [ ] Invocation with partial context (problem stated, no approach) → plan grills only on the gaps.
- [ ] Negative: plan never asks a question whose answer is in a clearly-referenced file (verify by giving plan a path to a file that answers the question).

### Question presentation

- [ ] Every grill question includes a recommended answer.

### Design.md authoring

- [ ] design.md is written to `.briskly/sessions/<YYYY-MM-DD-slug>/design.md`.
- [ ] design.md contains all six sections: Problem, Approach, Acceptance criteria, Out of scope, Open questions / risks, Execution outline.
- [ ] Execution outline contains 5–10 one-liners with no expanded code or per-substep checkboxes.
- [ ] No per-section approval interruptions during drafting.

### Plan-coherence review

- [ ] After design.md is written, plan-coherence review subagent runs automatically.
- [ ] Review outcome line is emitted to chat: `plan-review: N issues auto-fixed, ✓ ready` or `plan-review: 1 blocking issue 🚨 <description>`.
- [ ] Auto-fix scope: typos, AC gaps, prose↔outline mismatches, untestable AC phrasing get fixed silently.
- [ ] Escalate scope: internal contradictions, missing source-of-truth info trigger 🚨.
- [ ] Negative: reviewer never modifies anything outside design.md without escalation.

### Handoff

- [ ] Plan presents file path + brief summary at end.
- [ ] Plan does NOT auto-invoke briskly:execute (manual handoff is required).
