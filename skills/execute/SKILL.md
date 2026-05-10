---
name: execute
description: Implement an approved briskly design.md. Use whenever the user says "ship it", "build this", "implement the design", "run execute", or has a `.briskly/sessions/<id>/design.md` ready to ship.
---

# briskly:execute

Implements an approved `design.md` by expanding its execution outline into TodoWrite items and dispatching implementer subagents sequentially with a shared `notes.md` scratchpad. A single end-of-run review subagent verifies spec compliance and triggers a capped auto-fix loop.

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

## Pre-flight

1. Determine session id: explicit argument from invocation, or most recent `.briskly/sessions/*` directory by mtime.
2. Verify `.briskly/sessions/<id>/design.md` exists. If not, surface a clear error and exit:
   `briskly:execute requires an approved design.md. Run /briskly:plan first.`
3. Verify the design.md has the required six sections (Problem, Approach, Acceptance criteria, Out of scope, Open questions / risks, Execution outline).

## Flow

1. **Read design.md.** Specifically the Execution outline and Acceptance criteria.
2. **Expand outline → TodoWrite.** Each outline item becomes one TodoWrite task. User sees live progress. Populate TodoWrite **before** any subagent dispatches.
3. **Initialize notes.md** at `.briskly/sessions/<id>/notes.md` with a header line if it doesn't exist.
4. **Per task (sequential — no parallel dispatch in v1):**
   - Mark TodoWrite item `in_progress`
   - Read `prompts/implementer.md`, substitute placeholders (`{{TASK_ID}}`, `{{TASK_DESCRIPTION}}` from outline, `{{CWD}}`, `{{DESIGN_PATH}}`, `{{NOTES_PATH}}`)
   - Dispatch implementer subagent with the filled prompt. **The subagent receives paths, not the spec text inline.**
   - On `DONE` or `DONE_WITH_CONCERNS`: mark TodoWrite `completed`, proceed to next task
   - On `BLOCKED`: pause, escalate to user with the reason and the task id
5. **End-of-run review.** Once all tasks are `completed`:
   - Read `prompts/reviewer.md`, substitute placeholders (`{{DESIGN_PATH}}`, `{{NOTES_PATH}}`, `{{BASE_REF}}` = the commit before execute started, typically `main` or the user's pre-execute HEAD)
   - Dispatch reviewer subagent
   - Reviewer auto-fixes what it can, reports blockers in the structured outcome
6. **Auto-fix loop (cap 2):**
   - If reviewer reports M > 0 blockers: read `prompts/fixer.md`, substitute placeholders (`{{DESIGN_PATH}}`, `{{ISSUES}}` = the blocker list)
   - Dispatch fixer subagent
   - Re-dispatch reviewer
   - Cap at 2 fix → review iterations. After cap, escalate (see below).

**Escalation behavior** (when the cap is hit with M > 0 blockers remaining): pause execution, present to the user (1) the unresolved blockers from the final review, (2) what each fix attempt tried, and (3) the relevant commit SHAs. Emit the 🚨 outcome line. Do NOT continue dispatching subagents. The user decides next: retry with new context, re-plan, or abandon.
7. **Outcome line** to chat:
   - M = 0 (after at most 2 loops): `execute-review: ✓ all green`
   - M > 0 after cap: `execute-review: 🚨 <M> unresolved after fix loop, <summary>`
8. **Done.** Final state: clean working tree on the current branch, commits made. User decides commit/PR via separate flow.

## Test quality bar

Tests written by implementers MUST:
- Reference the AC they cover (test name, comment, or docstring)
- Cover edge cases and negative cases listed in the spec
- Verify real behaviors — not toy assertions

The reviewer's spec-compliance check enforces this. An AC with zero test coverage causes the reviewer to flag a blocker that requires fixing (or escalation).

## notes.md format

Free-form scratchpad. Light convention — each subagent appends:

```
## [<task-id>] <ISO 8601 timestamp> <role>
- decision: <if any non-obvious choice>
- discovery: <if you learned something useful for later tasks>
- blocker: <if any unresolved issue>
```

Omit lines that don't apply. Subsequent subagents read notes.md before starting their task.

## Sequential dispatch (v1)

Implementers dispatch one at a time. No parallel dispatch in v1 — risk of file conflicts outweighs the speed benefit at this scope. Parallel dispatch for proven-conflict-free tasks is parked for a future version.

## Non-git cwd

If the cwd is not a git repository, surface a one-line warning at pre-flight (`Note: cwd is not a git repo — commits and diff-based review will be skipped or degraded.`) and proceed. Implementers may skip the commit step; the end-of-run reviewer falls back to file-tree inspection vs the spec rather than a diff.

## Subagent prompts

- `prompts/implementer.md` — per-task implementer
- `prompts/reviewer.md` — single end-of-run reviewer
- `prompts/fixer.md` — fix subagent for review-flagged issues

All three accept path-based context, not inline spec text. Substitute placeholders before dispatch.

## What this skill does NOT do

- Push to remote
- Open PRs
- Prompt the user mid-flight (runs to completion or escalates)
- Modify the spec at `design.md`
- Dispatch implementers in parallel (v1)
- Run per-task review (single end-of-run review only)
