# Briskly v1 — Design Spec

**Status:** Approved design, ready for implementation planning.
**Date:** 2026-05-09
**Supersedes:** `docs/spec.md` (the starting spec) for build purposes. The starting spec stays as historical context for positioning rationale.

---

## 1. Problem

Claude Code users need a daily-driver workflow tool that sits between two unsatisfying options:

- **Plan mode** has no design discipline, no review pattern, no spec artifact.
- **Superpowers** has full ceremony — brainstorm → writing-plans → executing-plans → multi-stage review — even when you just want to ship something modest. Its `writing-plans` output is a pre-expanded execution script for context-less subagents (full inline code per task, mandated checkbox-per-2-minute-step format, content repeated across tasks). It is unreviewable by humans, and the post-design ceremony is heavier than the work warrants on a daily basis.

Briskly fills this gap. It imposes real discipline (design before execute, review before done) but with reviewable artifacts, near-zero ceremony post-approval, and a single human decision point at the plan→execute handoff.

## 2. Approach

Three skills in a `briskly:*` namespace — `plan`, `execute`, `research`. They coexist with superpowers (no name collisions, no displaced functionality). A SessionStart hook injects guidance for when to reach for briskly versus alternatives.

The pipeline:

```
briskly:plan ──→ design.md ──→ user approves ──→ briskly:execute ──→ shipped code
                    ▲                                    │
                    │                                    │
                    └── briskly:research ────────────────┘
                           (async during plan; user-invokable)
```

**North star:** minimize user touchpoints while preserving correctness through structured automation. Token efficiency is a nice-to-have, not the goal. Structure-and-subagents-as-confidence is the trade.

### 2.1 The three skills

| Skill | Role |
|---|---|
| `briskly:plan` | Calibrated grill → design.md → auto plan-coherence review → present to user |
| `briskly:execute` | Subagent-driven dev from design.md → final review with auto-fix |
| `briskly:research` | Async investigation, dispatched primarily from plan but user-invokable too |

### 2.2 `briskly:plan` flow

1. Read context: cwd state, recent commits, any existing `.briskly/` artifacts (research, prior sessions), and the user's invocation message.
2. **Grill (calibrated to context).** One question at a time, codebase-first ("if a question can be answered by reading code, read it instead of asking"), each question paired with my recommended answer. Grill load scales inversely with context provided — full grill from a one-liner, near-zero from a complete design paragraph.
3. Once scope is clear, propose 2–3 approaches with tradeoffs. User picks.
4. **Author `design.md` straight through** — no per-section approval interruptions during drafting.
5. **Auto plan-coherence review subagent** runs immediately. It checks: prose↔outline coherence, AC testability, internal contradictions, gaps. Auto-fixes everything locally resolvable. Escalates only on contradictions or missing source-of-truth info.
6. Emit a one-line outcome line in chat: `plan-review: 3 issues auto-fixed, ✓ ready` or `plan-review: 1 blocking issue 🚨 <one-line description>`.
7. Present the file path and a brief summary to the user. User reads, approves, manually invokes `briskly:execute`. The handoff is the one human gate that stays — it protects against runaway loops building the wrong thing.

### 2.3 `design.md` sections

| Section | Content |
|---|---|
| **Problem** | One paragraph: what we're solving, why now |
| **Approach** | Architecture, key components, data flow if non-trivial. Prose. |
| **Acceptance criteria** | Testable assertions. Includes edge cases and negative cases. Tests pin to these. |
| **Out of scope** | Explicit NOTs |
| **Open questions / risks** | Known unknowns; things execute may defer back |
| **Execution outline** | 5–10 one-liners. No code, no per-substep checkboxes. "Add X to Y", "Wire Z handler", "Add tests for W edge cases" |

### 2.4 `briskly:execute` flow

1. Read `design.md`. Expand the execution outline into TodoWrite items (live progress visible to user).
2. **Sequential subagent dispatch** per task. Each implementer subagent gets: task ID, path to `design.md`, path to `notes.md`. Subagent reads the spec itself rather than receiving it re-passed in the prompt — uses durable on-disk artifact instead of context retransmission.
3. Subagents implement, test, commit per task. **TDD encouraged but not enforced.** Test *quality* is the bar: tests must verify acceptance criteria, edge cases, and negative cases. Toy assertions don't count.
4. Subagents append findings/blockers/decisions to `.briskly/sessions/<id>/notes.md` — a shared scratchpad readable by the orchestrator and subsequent subagents. Free-form, light convention.
5. After all tasks complete: **single review subagent** runs against full diff vs main + `design.md`. It checks spec compliance, code quality, scope (no surprise additions), and obvious bugs.
6. **Auto-fix loop:** review issues → fix subagent → re-review. Cap at 2 loops. Then escalate.
7. Emit one-line outcome: `execute-review: ✓ all green` or `execute-review: 🚨 N unresolved after fix loop, <summary>`.
8. Done. User decides commit/PR via separate flow — briskly does not push or open PRs.

### 2.5 `briskly:research` mechanics

- Async dispatch from plan during grill, on branches independent of the next pending question. Synchronous fallback when the next grill step depends on the research result.
- Direct user invocation also supported: `/briskly:research <topic>`.
- Output: `.briskly/research/<topic-slug>-YYYY-MM-DD.md` (cross-session reusable, date-stamped for freshness).
- Format: **Findings** / **Sources** (files, URLs, evidence) / **Confidence** (high / medium / low — based on direct evidence vs inference).
- No auto-review (investigative artifact, not a decision).
- Plan can cite research artifacts in `design.md` ("see `.briskly/research/auth-flow-2026-05-09.md`"). Execute can read them when relevant.

### 2.6 `.briskly/` layout

```
.briskly/
├── sessions/
│   └── 2026-05-09-add-auth-middleware/
│       ├── design.md
│       └── notes.md
└── research/
    ├── auth-flow-2026-05-09.md
    └── kroger-api-rate-limits-2026-04-22.md
```

- Located at cwd root (where briskly is invoked).
- Session ID format: `YYYY-MM-DD-<topic-slug>`.
- `.briskly/` added to user's `.gitignore` by default. Plan emits a one-line suggestion to commit when the design is significant enough to warrant project-history retention. Decision stays with the user.

### 2.7 Reviews & auto-fix policy

| Stage | Reviewer scope | Auto-fix | Escalate when |
|---|---|---|---|
| Plan-coherence | `design.md` only | Typos, AC gaps, prose↔outline mismatches, untestable AC phrasing | Internal contradictions, missing source-of-truth info |
| Execute-final | Full diff vs main + `design.md` | Code lint, obvious bugs, removable scope creep, fixable test failures | Test failures unfixable in 2 loops, scope drift requiring decision |

User sees a one-line outcome each time. Decision required only on 🚨.

### 2.8 Failure handling

- **Plan-review escalates** → user picks: address now / defer to execute / proceed as-is.
- **Execute-review escalates** → user picks: retry with notes / re-plan / abandon.
- **Auto-fix loop cap: 2** at both review stages. After cap, escalate with a summary of what's unresolved.

### 2.9 SessionStart hook & superpowers coexistence

- Hook config at `hooks/hooks.json`, mirroring superpowers' pattern. A polyglot wrapper (`hooks/run-hook.cmd`) → a `hooks/session-start` script that emits JSON `additionalContext` containing the contents of `skills/using-briskly/SKILL.md`.
- `skills/using-briskly/SKILL.md` is the single source of truth for the persistent system prompt. Editing one file updates the hook content.
- Content covers: when to reach for briskly (non-trivial-but-not-huge work — design before execute, but no full superpowers ceremony); the three skill names; how briskly differs from plan mode (more discipline) and from superpowers (much less ceremony — defer to superpowers when the work warrants it).
- All skills namespaced `briskly:*`. No name collisions with `superpowers:*`.

### 2.10 Plugin distribution

- Single repo (this one) serves as both plugin and marketplace.
- `.claude-plugin/plugin.json` carries an explicit `version` field (semver).
- `.claude-plugin/marketplace.json` lists this plugin and points at itself.
- User installs: `/plugin marketplace add micah-svenson/briskly` then `/plugin install briskly@briskly`.
- **Update flow:** bump `version` in `plugin.json` on each push to main. Users run `/plugin marketplace update briskly` to pick up new version. Auto-update configurable per their marketplace settings.
- **Version-bump enforcement:** a pre-commit (or CI) check that fails when skill files have changed but `version` has not. Prevents shipping stealth updates.

## 3. Acceptance criteria

These pin the build. Tests must verify each, including the edge and negative cases noted.

### 3.1 Plan skill

1. **Calibrated grill behaves correctly.**
   - Given a one-line invocation, plan asks meaningful clarifying questions before drafting (≥1 question).
   - Given an invocation containing a complete design paragraph (problem + approach + AC), plan drafts directly without grilling.
   - Edge: invocation contains partial context — plan grills only on the gaps, not on what's already provided.
   - Negative: plan does NOT ask questions whose answers are findable by reading the codebase (verify via a test scenario where the answer is in a referenced file).
2. **Question presentation:** every grill question includes a recommended answer.
3. **Design.md is written to `.briskly/sessions/<YYYY-MM-DD-slug>/design.md`** with all six required sections (Problem, Approach, AC, Out of scope, Open questions, Execution outline).
4. **Plan-coherence review subagent runs automatically** after design.md is written. Its outcome line is emitted to chat.
5. **Auto-fix scope correctness:** typos, AC gaps, prose-outline mismatches, untestable AC phrasing get fixed silently. Internal contradictions and missing source-of-truth info get escalated.
   - Edge: a contradiction the reviewer initially flags can be auto-fixed if it's a simple wording issue resolvable from the spec itself; if it requires user input, escalate.
   - Negative: reviewer never modifies anything outside the design.md without escalation.
6. **No per-section approval during drafting.** Plan does not interrupt mid-draft for approval.
7. **The plan→execute handoff is manual.** Plan emits the file path and a brief summary; it does NOT auto-invoke execute.

### 3.2 Execute skill

1. **Refuses to run without an approved design.md** — checks for `.briskly/sessions/<id>/design.md` (path provided as argument or inferred from most recent session).
2. **TodoWrite is populated** from the execution outline before any subagent dispatches. User can see live progress.
3. **Sequential subagent dispatch.** No parallel implementer subagents in v1. (Acceptance: log/trace shows sequential dispatch only.)
4. **Subagents read design.md from disk** — verifiable by checking implementer prompts: they receive paths, not the spec text inline.
5. **Tests written by subagents pin to AC.** A test file produced by execute references the acceptance criteria it covers (comment, docstring, or test name pattern). Edge and negative cases for each AC have at least one test.
   - Negative: an AC with zero test coverage fails the execute-final review.
6. **notes.md exists and is appended to** by subagents during execution. Format is free-form but each entry is timestamped/task-tagged.
7. **Single review subagent at end** — not per-task. Verifiable by trace.
8. **Auto-fix loop respects cap (2).** Third unsuccessful loop escalates with summary, no further dispatches.
9. **Outcome line emitted** in both ✓ and 🚨 cases.
10. **Execute does not push or open PRs.** Final state is a clean working tree on a feature branch (or wherever the user invoked from), commits made, no remote operations.

### 3.3 Research skill

1. **Direct invocation works:** `/briskly:research <topic>` produces a research artifact at `.briskly/research/<slug>-YYYY-MM-DD.md`.
2. **Async dispatch from plan works:** when plan dispatches research mid-grill, plan continues asking questions on independent branches without blocking.
3. **Artifact format:** Findings / Sources / Confidence. Sources cite at least one piece of evidence (file path, URL, or excerpt).
4. **No auto-review on research artifacts.**
5. **Stale-detection signal:** if plan reads a research artifact older than 30 days, it surfaces a one-line freshness note to the user.
   - Edge: artifact older than 30 days but the user explicitly references it — surface the note but proceed.

### 3.4 SessionStart hook

1. **Hook fires on session startup, clear, and compact** (matcher pattern matches superpowers').
2. **Content sourced from `skills/using-briskly/SKILL.md`** — editing that file changes hook output without touching `hooks.json`.
3. **JSON output uses the platform-appropriate field** (`additionalContext` or `hookSpecificOutput.additionalContext` based on env vars). Mirror superpowers' platform detection.
4. **Coexists with superpowers' hook** — both run on session start without one shadowing the other. (Acceptance: install both, observe both `<system-reminder>` blocks present at startup.)
5. **Hook content describes when to use briskly vs alternatives.** Negative: it does NOT instruct the user to displace plan mode or superpowers in cases they're better suited for.

### 3.5 Plugin packaging

1. **`.claude-plugin/plugin.json` validates** against the documented schema. Required fields: `name`, `version`, `description`. `version` is explicit semver.
2. **`.claude-plugin/marketplace.json` is valid** and lists the plugin pointing at itself.
3. **Install flow works end-to-end** from a clean `~/.claude/`: `/plugin marketplace add` → `/plugin install` → skills become invocable.
4. **Update flow works:** bump version, push to main, `/plugin marketplace update` → user gets new version.
5. **Version-bump enforcement:** the CI/pre-commit check fails on a commit that modifies `skills/**` or `hooks/**` without bumping `version`. Negative: the check passes on doc-only changes.

### 3.6 General

1. **All artifacts (`design.md`, `notes.md`, research files) are valid markdown** parseable by standard tools.
2. **No interactive prompts during execute** — execute runs to completion or escalation without user input.
3. **Briskly works in any cwd**, not just git-tracked projects (graceful fallback if no git, single-line warning).

## 4. Out of scope (deliberate NOTs)

- Not a replacement for plan mode (briskly has design discipline; plan mode does not).
- Not a tier of grovework (separate plugin, separate concerns).
- Not a "lighter superpowers" — different artifact philosophy. Briskly produces a single reviewable design.md, never a pre-expanded executable plan file.
- Not phase-based (no Define/Design/Implement/Closeout structure).
- Not catch-crop renamed (catch-crop has hard scope gates and mandatory cleanup; briskly is broader and lighter).
- Not a heavy framework with a "lite mode" — briskly is the whole thing.
- Not coupled to grovemind or grovework (composition is additive, not load-bearing).
- v1 does NOT include parallel subagent dispatch, Agent Teams mode, or a `briskly:resume` verb.
- v1 does NOT push to remotes or open PRs.

## 5. Open questions / risks

- **Pre-commit version-bump check vs CI check.** Pre-commit is faster feedback but adds friction; CI is non-bypassable. Likely both, with pre-commit as warning and CI as gate. Resolve during plan stage.
- **Notes.md format convention.** Currently "free-form, light convention." May need a stronger schema if subagent communication patterns get richer. Defer until real use.
- **Calibrated grill heuristic.** "How much context = how much grill" is judgment-based; we'll see in real use whether the calibration needs explicit rules.
- **Stale-research threshold.** 30 days is a guess. Adjust based on use.
- **Marketplace name.** Spec assumes the user's GitHub handle namespace; verify before publishing.
- **Pre-existing `docs/spec.md` lifecycle.** Once briskly v1 ships, the starting spec is superseded. Decide: archive, delete, or keep as historical context. Defer.

## 6. Execution outline

1. Scaffold plugin structure: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start`, `skills/{plan,execute,research,using-briskly}/SKILL.md` stubs.
2. Implement `skills/using-briskly/SKILL.md` content (the SessionStart hook payload — when/why to reach for briskly, the three skill names, coexistence with plan mode and superpowers).
3. Implement `skills/plan/SKILL.md` (invoked as `/briskly:plan`): calibrated grill loop, design.md authoring, plan-coherence review subagent dispatch, auto-fix loop, outcome-line emission. Includes the design.md section template and the plan-review subagent prompt template.
4. Implement `skills/research/SKILL.md` (invoked as `/briskly:research`): async-dispatchable research with Findings/Sources/Confidence output. Includes the research subagent prompt template.
5. Implement `skills/execute/SKILL.md` (invoked as `/briskly:execute`): outline → TodoWrite, sequential implementer dispatch, notes.md scratchpad, single end-of-run review, auto-fix loop, outcome line. Includes the implementer prompt template, the spec-and-quality reviewer prompt template, and the fix-subagent prompt template.
6. Wire SessionStart hook: `hooks/hooks.json` with the matcher pattern, `hooks/run-hook.cmd` polyglot, `hooks/session-start` script that emits platform-appropriate JSON containing `using-briskly/SKILL.md`.
7. Add CI/pre-commit version-bump enforcement: a check that fails if `skills/**` or `hooks/**` changed without `version` bumping in `plugin.json`.
8. Write tests: end-to-end install flow; calibrated-grill behavior under three context-richness conditions; auto-fix vs escalate boundary cases; subagent sequential dispatch; SessionStart coexistence with superpowers.
9. Write a top-level README.md update describing v1 install/use, the three skills, and coexistence guidance.
10. Tag v1.0.0, push to main, verify install flow from a clean machine.

---

## 7. Future direction (parking lot — not v1)

- **Agent Teams mode.** Multi-agent collaboration richer than the shared `notes.md` scratchpad — explicit role-based subagents working in parallel with structured handoff protocols.
- **`briskly:resume` verb.** First-class resumption for long-paused sessions, especially for grovemind thread integration.
- **Plan-mode-to-briskly handoff.** When a plan-mode session realizes it needs design discipline, smooth handoff into `briskly:plan` carrying the in-flight context.
- **Parallel subagent dispatch in execute** for tasks the orchestrator can prove are conflict-free.
