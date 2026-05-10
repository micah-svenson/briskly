# Briskly

Daily-driver workflow plugin for Claude Code. Sits between plan mode (no design discipline) and superpowers (full ceremony) — three skills, reviewable specs, automated reviews.

## Install

```bash
/plugin marketplace add micah-svenson/briskly
/plugin install briskly@briskly
```

Restart your Claude Code session to activate the SessionStart hook.

## The three skills

| Skill | What it does |
|---|---|
| `/briskly:plan` | Calibrated grill → reviewable `design.md` → auto plan-coherence review |
| `/briskly:execute` | Subagent-driven implementation from `design.md` → auto-fix review at end |
| `/briskly:research` | Async investigation, dispatched primarily from plan but user-invokable too |

## Typical use

```
/briskly:plan add a per-user rate limiter to the API
   <calibrated grill — usually a few questions; less if you provided context>
   <design.md written to .briskly/sessions/<id>/design.md>
   <plan-coherence review runs silently; ✓ outcome line>
   <user reviews the design — usually under 3 minutes>

/briskly:execute
   <TodoWrite shows live progress>
   <subagents implement task by task>
   <single review subagent at the end auto-fixes what it can>
   <execute-review: ✓ all green>
```

## Coexistence with other tools

- **vs Claude Code plan mode:** briskly has design discipline and produces a reviewable spec. Use plan mode for trivial pre-work; reach for briskly when the work merits a written design.
- **vs superpowers:** briskly is intentionally lighter. If a project needs full brainstorm → writing-plans → executing-plans → multi-stage review ceremony, defer to superpowers.
- All briskly skills are namespaced `briskly:*` and never collide with `superpowers:*`.

## Artifacts

Briskly writes to `.briskly/` at the cwd root:

```
.briskly/
├── sessions/<YYYY-MM-DD-slug>/
│   ├── design.md      # human-reviewable design
│   └── notes.md       # subagent shared scratchpad
└── research/<topic>-YYYY-MM-DD.md
```

`.briskly/` is gitignored by default. Commit it when project history is valuable.

## Versioning

Briskly uses explicit semver in `.claude-plugin/plugin.json`. Each push to main bumps the version (CI enforces this for skill/hook changes). Run `/plugin marketplace update briskly` to pick up new versions.

## Status

v1.0.0 — initial release. See `docs/superpowers/specs/2026-05-09-briskly-design.md` for the full design and `docs/superpowers/plans/2026-05-09-briskly-v1.md` for the implementation plan.

## License

MIT.
