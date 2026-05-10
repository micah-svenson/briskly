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
