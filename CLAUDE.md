# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Briskly is a Claude Code plugin: three skills (`briskly:plan`, `briskly:execute`, `briskly:research`) and a `using-briskly` SessionStart hook. See `README.md` and `docs/spec.md` for the broader design.

## Post-implementation workflow

After any implementation that touches `skills/**` or `hooks/**`, complete the full release loop so the plugin is ready after the next Claude Code restart. CI enforces step 1 via `.github/workflows/version-bump-check.yml` and `scripts/check-version-bump.sh` — skill/hook changes without a version bump fail.

1. Bump `.claude-plugin/plugin.json` `version` (semver: PATCH for fixes/cleanups, MINOR for new behavior, MAJOR for breaks).
2. Commit: `release: v<X.Y.Z> — <one-line summary>` with the standard co-author line.
3. Tag: `git tag v<X.Y.Z>` (matches the existing bare-`v` convention used on `v1.0.0` / `v1.0.1`; do *not* use `briskly--v<X.Y.Z>` from `claude plugin tag`).
4. Push: `git push origin main --tags`.
5. Update locally: `claude plugin update briskly@briskly` (note the `<plugin>@<marketplace>` form — `claude plugin update briskly` alone fails with "Plugin not found").
6. Tell the user: "Restart Claude Code to activate v<X.Y.Z>." The new version is fetched on step 5 but only loads on restart.

This is the default for every implementation here — don't ask first, just run the loop. If a change touches only docs/non-shipped files (no `skills/**` / `hooks/**` diff), skip the version bump but still push and tell the user.
