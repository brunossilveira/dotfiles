---
name: cqc-review
description: >-
  Find concrete code-quality improvement opportunities in a codebase using the
  Code Quality Challenge heuristics — large/longest classes, high-churn files,
  slowest tests, TODO comments, compiler/runtime warnings, and long parameter
  lists. Use when scanning a repo for refactoring candidates, doing a code-quality
  pass, or driving a workflow that surfaces files worth improving.
---

# Code Quality Challenge — Review

A catalog of six **improvement detectors**. Each one is a cheap way to surface
*candidate* files/tests/lines, paired with guidance on what the improvement
actually is. Detectors find candidates; they don't auto-fix — a human or agent
judges each candidate and decides whether the change is worth it.

Adapted from Jason Swett's *Code Quality Challenge* (codewithjason.com). Examples
are Ruby/RSpec-flavored where the original is; the heuristics are language-general.

## When to use this

- "Find files worth improving / refactoring candidates in this repo."
- A code-quality sweep, or one detector on demand ("show me the high-churn files").
- Driving a workflow that fans out per candidate (see **Workflow integration**).

## The catalog

| # | Detector | What it surfaces | Cost | Reference |
|---|----------|------------------|------|-----------|
| 1 | Large class | Longest source files (proxy for classes doing too much) | cheap (static) | [references/slim-down-large-class.md](references/slim-down-large-class.md) |
| 2 | High-churn files | Files changed most often (instability / unclear code) | cheap (git) | [references/investigate-high-churn-files.md](references/investigate-high-churn-files.md) |
| 3 | Slowest tests | Tests that drag the suite | needs test run | [references/investigate-slowest-test.md](references/investigate-slowest-test.md) |
| 4 | TODO comments | TODO/FIXME/HACK left in code | cheap (grep) | [references/nuke-todo-comments.md](references/nuke-todo-comments.md) |
| 5 | Warnings | Deprecations/warnings on boot/test/install/deploy | needs run | [references/get-rid-of-warnings.md](references/get-rid-of-warnings.md) |
| 6 | Long parameter lists | Methods with 4+ params (data clumps, control coupling) | cheap (grep) | [references/investigate-long-parameter-lists.md](references/investigate-long-parameter-lists.md) |

## How to use

1. Pick a detector (or run several). The runnable command for each lives in
   [`detectors.yml`](detectors.yml) under `find:` — substitute `{path}` with the
   target directory.
2. Run it to get a ranked list of candidates.
3. For each candidate worth pursuing, **load that detector's reference file** for
   the full rationale, what to look for, and how to make the improvement.
4. Propose the smallest worthwhile change. Don't force it — "no good candidate
   found" is a valid outcome for any single file.

The two `requires_run: true` detectors (slowest tests, warnings) need the suite /
boot to actually execute, so they're heavier — gate them behind an explicit
opt-in rather than running them on every sweep.

## Workflow integration (Fabro.sh)

[`detectors.yml`](detectors.yml) is the machine-readable bridge. An orchestrator
should: read the manifest → run each `find` command to collect candidates →
fan out one agent per candidate → that agent loads the matching `reference` file
and proposes/applies the improvement. Keep this skill as the single source of
truth; the workflow only orchestrates.
