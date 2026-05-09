# Briskly

A structured-yet-speedy workflow plugin for Claude Code. Daily driver.

## What it is

Briskly is the tool you reach for constantly. It splits the gap between two things that don't fit:

- **Claude Code plan mode** — too basic. No design discipline, no review pattern, no spec.
- **superpowers** — too heavy for daily work. Full brainstorming → spec → plan → execute → review pipeline, even when you just want to knock something out.

Briskly fills the gap: light enough to use without thinking, structured enough to produce real work. Skills read adverbially in invocation: `briskly:brainstorm`, `briskly:execute`, `briskly:review`.

## Status

**Pre-implementation.** This repo holds the starting spec and will host the plugin as it gets built. Spec lives in [`docs/spec.md`](docs/spec.md) and is expected to evolve through refinement before code.

## Where this fits

Briskly is one of three independent Claude Code plugins in a broader architecture:

| Plugin    | Role                | One-liner                                                  |
|-----------|---------------------|------------------------------------------------------------|
| grovemind | Awareness / journey | What you're working on, sticky across sessions             |
| grovework | Structured pipeline | Full discipline for major projects — phases, canopies, AC  |
| briskly   | **Daily driver**    | Structured-yet-speedy work; this repo                      |

Each plugin works **fully standalone**. Briskly is not coupled to the others — its primary use is alone or with grovemind for resumability. grovework is an optional bigger-hammer for major projects.

The full cross-plugin vision lives in the grovework repo at `docs/agentic-workflow-vision.md`.

## License

TBD.
