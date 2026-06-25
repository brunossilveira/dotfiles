---
name: safe-refactoring
description: >-
  Best practices for safely fixing code smells and refactoring — the safety
  harness (keep tests green, small reversible steps, separate refactoring from
  behavior change, characterization tests for untested code) plus named
  techniques (extract class, introduce parameter object, replace boolean
  parameter, remove dead parameter, extract compound conditional, speed up slow
  tests, fix deprecation warnings). Use when actually applying a fix or refactor —
  especially after cqc-review surfaces a candidate to improve.
---

# Safe refactoring — fix code smells without breaking things

cqc-review *finds* candidates; this skill is *how to fix them well*. It has two
parts: a universal **safety harness** that applies to every change, and a
**technique catalog** keyed to the smells.

## The safety harness — do this regardless of technique

1. **Green before you start.** Run the relevant tests; they must pass first. A
   refactor on a red suite is a gamble — you can't tell what you broke.
2. **No tests covering it? Characterize first.** For untested/legacy code, write
   *characterization tests* that pin down current behavior (even its quirks)
   before touching it. They're a safety net, not a spec of correctness.
3. **Small, reversible steps.** One mechanical change at a time; rerun tests after
   each. If a step needs a paragraph to explain, it's too big — split it.
4. **Two hats (Kent Beck).** At any moment you're *either* refactoring (behavior
   unchanged) *or* changing behavior — never both in the same step. Switch hats
   deliberately and know which you're wearing.
5. **Separate the diffs.** Pure refactors go in their own commit, isolated from
   logic changes *and* from reformatting. A reviewer should be able to trust a
   "refactor: no behavior change" commit at a glance.
6. **Prefer automated refactorings.** Editor/IDE rename, extract-method, etc. are
   behavior-preserving by construction — safer than hand edits.
7. **Know when to stop.** No clean seam, or the change keeps ballooning? Revert to
   the last green commit and leave a note. A forced refactor you can't finish
   safely is worse than none. "Left as-is — here's why" is a valid outcome.

## Technique catalog

| Smell (cqc-review detector) | Technique | Reference |
|---|---|---|
| Large class | Extract Class (+ method-level fallbacks) | [extract-class.md](references/extract-class.md) |
| Long param list — data clump | Introduce Parameter Object / value object | [introduce-parameter-object.md](references/introduce-parameter-object.md) |
| Long param list — boolean flag | Replace Boolean Parameter with explicit methods | [replace-boolean-parameter.md](references/replace-boolean-parameter.md) |
| Long param list — unused arg | Remove Dead Parameter | [remove-dead-parameter.md](references/remove-dead-parameter.md) |
| Compound conditional | Extract/Decompose Conditional into a named query | [extract-compound-conditional.md](references/extract-compound-conditional.md) |
| Slowest tests | Speed up / prune tests | [speed-up-slow-tests.md](references/speed-up-slow-tests.md) |
| Warnings / deprecations | Fix the deprecation safely | [fix-deprecation-warnings.md](references/fix-deprecation-warnings.md) |
| High-churn file | No single technique — add tests, find the seam, then apply whichever fits | — |

Each reference covers: when it applies, before/after, the safe step sequence, and
when **not** to do it.
