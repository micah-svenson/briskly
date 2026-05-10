# Briskly

Daily-driver workflow plugin for Claude Code. Sits between plan mode (no design discipline) and superpowers (full ceremony) — three core primitives plus a research helper, reviewable specs, automated reviews.

## Install

```bash
/plugin marketplace add micah-svenson/briskly
/plugin install briskly@briskly
```

Restart your Claude Code session to activate the SessionStart hook.

## The skills

Three core workflow primitives plus one helper:

| Skill | Role | What it does |
|---|---|---|
| `/briskly:plan` | core | Calibrated question pass → reviewable `design.md` → auto plan-coherence review |
| `/briskly:execute` | core | Subagent-driven implementation from `design.md` → auto-fix review at end |
| `/briskly:note` | core | Lightweight in-session capture of a note, issue, idea, or feedback to the current or another project's `.briskly/notes/`. Conversational primary; archive via `.briskly/notes/.archive/` |
| `/briskly:research` | helper | Async investigation, dispatched primarily from plan but user-invokable too |

### When to reach for note

Use `briskly:note` when you're mid-task and want to capture something — a bug to look at later, an idea about another project, feedback about a tool you're using — without breaking the current flow. It enriches the capture with whatever session context is live (file paths, function names, source-of-thought) and writes a self-contained markdown file. Cross-project routing is built in: from any project, "leave a note for briskly that..." resolves the briskly project's path and writes there. Notes never get deleted by the skill — archive them to retire from active context.

## Typical use

```
/briskly:plan add a per-user rate limiter to the API
   <calibrated question pass — usually a few questions; less if you provided context>
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
│   └── notes.md       # subagent shared scratchpad during execute
├── research/<topic>-YYYY-MM-DD.md
└── notes/
    ├── <YYYY-MM-DD-slug>.md    # captured notes for this project
    └── .archive/
        └── <YYYY-MM-DD-slug>.md  # archived (out of active context, retained)
```

`.briskly/` is gitignored by default. Commit it when project history is valuable. To retire all notes wholesale, delete the `.briskly/` directory (or `.briskly/notes/` specifically).

## Versioning

Briskly uses explicit semver in `.claude-plugin/plugin.json`. Each push to main bumps the version (CI enforces this for skill/hook changes). Run `/plugin marketplace update briskly` to pick up new versions.

## Status

v1.0.0 — initial release. See `docs/superpowers/specs/2026-05-09-briskly-design.md` for the full design and `docs/superpowers/plans/2026-05-09-briskly-v1.md` for the implementation plan.

## License

MIT.
