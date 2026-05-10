---
name: research
description: Investigate a topic by reading code or searching docs. Use whenever the user says "look into X", "how does Y work", "research Z", or `/briskly:research <topic>`. Writes a dated artifact.
---

# briskly:research

Investigative async dispatch that produces a date-stamped research artifact. Primarily a mixin to `briskly:plan` (called during the calibrated question pass when an answer requires real digging) but also user-invokable for ad-hoc deep-dives.

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

## When to use

- **From plan:** during the question pass, when you need to investigate something to inform the design (e.g., "does our auth system support X?", "where is rate limiting currently handled?"). Dispatched async on branches independent of the next pending question.
- **Direct invocation:** `/briskly:research <topic>` for ad-hoc deep-dives without committing to a plan session.

## What it produces

An artifact at `.briskly/research/<topic-slug>-YYYY-MM-DD.md` with three sections:
- **Findings** (200–500 words; longer if warranted)
- **Sources** (file paths, URLs, command outputs, excerpts — every claim traceable)
- **Confidence** (high / medium / low, with one paragraph of rationale)

No auto-review runs on research artifacts — they're investigative, not decisions.

## How to invoke

### From plan (async, mixin)

When plan needs to investigate while asking questions:

1. Derive a topic slug from the topic phrase (lowercase, non-alphanumerics → `-`, collapse runs, trim).
2. Read `prompts/researcher.md` and substitute placeholders: `{{TOPIC}}`, `{{CWD}}`, `{{SLUG}}` (the slug from step 1), `{{DATE}}` (`YYYY-MM-DD` UTC).
3. Dispatch a subagent **asynchronously** (using the Agent tool's `run_in_background: true` parameter where the harness supports it; otherwise foreground). Plan continues asking questions on independent branches while research runs.
4. When the subagent reports DONE, plan reads the artifact and may cite it in the design.md (e.g., "see `.briskly/research/auth-flow-2026-05-09.md`").

If the harness does NOT support background subagents (no `run_in_background` parameter), dispatch foreground and continue asking questions on dependent branches afterward — the artifact still gets written and cited; only the parallelism is lost.

### Direct invocation

User runs `/briskly:research <topic>`:

1. Topic = the user's argument string.
2. Same slug derivation and prompt substitution.
3. Dispatch foreground (the user is waiting for the artifact).
4. On DONE, present the artifact path and a one-line summary.

## Slug derivation

Given a topic string, derive the slug:
- Lowercase
- Replace any non-alphanumeric character with `-`
- Collapse runs of `-`
- Trim leading/trailing `-`
- Cap at 60 chars (truncate if longer; preserve word boundaries when possible)

Examples:
- `"how does our auth system work?"` → `how-does-our-auth-system-work`
- `"Kroger API rate limits"` → `kroger-api-rate-limits`

## Stale-detection

When plan reads a research artifact older than 30 days (compare today's date with the artifact's filename date), surface a one-line freshness note to the user:

`Note: research artifact <name> is <X> days old.`

Plan proceeds — the note is informational, not blocking.

## What this skill does NOT do

- Modify any files outside `.briskly/research/`
- Run an auto-review (research is investigative, not a decision)
- Block on long investigations — if a topic balloons, the subagent writes what it has and notes the open thread under Confidence
- Push to remote or commit (research artifacts are gitignored by default along with the rest of `.briskly/`)
