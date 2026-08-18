# Hardening check — agent rubric

Used when no mutation-testing tool could be resolved. Hardening runs only on
risky stories, so the bar is higher than for the other stages: the question is
whether the tests would actually catch a regression.

Work through the story's diff line by line and ask, for each meaningful line:
**if this line were changed, would a test fail?** Concretely — a comparison
flipped from `<` to `<=`, a boundary moved by one, a condition negated, a return
value replaced with nil or zero, an early return removed.

Fail on any of these:

- **Surviving mutants.** Any line where you can name a plausible change that no
  test would catch. Name the line and the change.
- **Untested error paths.** A rescue, catch, or error branch that no test enters.
- **Boundaries untested.** Empty collection, single element, maximum, off-by-one
  either side of a threshold, zero, negative, nil.
- **Concurrency or ordering assumed.** Shared state written from more than one
  path with nothing exercising the interleaving.
- **Nothing was added.** The hardener recorded work but the diff adds no tests
  and fixes no defect.

Pass only if you can state which mutations you considered and why each would be
caught. A pass with no such account is indistinguishable from not checking.
