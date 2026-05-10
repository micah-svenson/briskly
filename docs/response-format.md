# Response format (canonical)

Mirrors the `## Response format` block inlined in each briskly SKILL.md and user-visible subagent prompt. If editing, propagate to all copies.

## Principles

- Lead with the answer. Recommendation first, reasoning after.
- Structured beats prose. One thought per line; bullets over paragraphs when both fit.
- Cap each line at one short sentence. If a thought needs two sentences, give it two lines.
- Use bold labels for the parts a user scans for: **Recommendation:**, **Why:**, **Alternative:**, **Push back if**.
- User CLAUDE.md or in-conversation instructions win when they conflict with this format.

## Default templates

Recommendation-style question:

```
<question>?

**Recommendation:** <answer>.
**Why:** <one-line reason>.
**Alternative:** <other option> — <when it would win>.
**Push back if** <signal that the recommendation is wrong>.
```

Approach selection (2–3 options):

```
A) <approach> — <one-line tradeoff>
B) <approach> — <one-line tradeoff>
C) <approach> — <one-line tradeoff>

**Recommendation:** A.
**Why:** <one-line reason>.
```

Handoff summary (end of plan / research / execute):

```
**Design ready:** `.briskly/sessions/<id>/design.md`
**Builds:** <one-line of what gets built>.
**Review:** <plan-coherence outcome line>.
**Next:** Run `/briskly:execute` when ready to ship.
```

End-of-session report (execute / research):

```
**Done:** <one-line of what shipped or what was found>.
**Files:** <paths touched, comma-separated>.
**Tests:** <pass/fail summary>.
**Follow-ups:** <anything deferred, or "none">.
```

## Examples

Bad — run-on prose that fuses recommendation, reasoning, and alternative into one sentence:

> For the mobile drop-up, my recommendation is to wrap the existing `<MobileActionSheet>` in a new `<ResponsiveActionMenu>` component that switches on viewport width so desktop still gets the popover and mobile gets the sheet, because that keeps the call sites unchanged and avoids forking the menu logic, though if you'd rather not introduce a new wrapper we could instead push the responsive switch down into `<MobileActionSheet>` itself and rename it, which is slightly more invasive but flatter.

Good — same content, restructured:

> **Recommendation:** Add a `<ResponsiveActionMenu>` wrapper that switches `<MobileActionSheet>` vs the existing popover on viewport width.
> **Why:** Call sites stay unchanged; menu logic doesn't fork.
> **Alternative:** Push the switch down into `<MobileActionSheet>` and rename it — flatter, but more invasive at the call sites.
> **Push back if** you'd rather not introduce a new wrapper component.
