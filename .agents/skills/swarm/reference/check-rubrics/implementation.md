# Implementation check — agent rubric

Used when no test or lint tool could be resolved for this repository. You are
judging work you did not do, read-only, in the story's worktree. Return `pass`
or `fail` with the evidence.

Fail on any of these:

- **The change is not exercised.** No test covers the new behavior, and no
  existing test would fail if the new code were deleted. Name the test you
  looked for.
- **A test that cannot fail.** Asserts on a constant, on the code's own output
  fed back to it, or on data expected to change. A test that stays green when
  you mentally break the business logic is not a test.
- **The story is not actually implemented.** Compare the diff to `story.md`:
  something the story requires is missing, or the diff does work the story never
  asked for.
- **It does not run.** Syntax errors, undefined references, imports that do not
  resolve, a call signature that does not match its definition.
- **Obvious breakage on the unhappy path.** Nil, empty, zero, or missing input
  crashes where the surrounding code handles it.

Do not fail for style, naming, or structure — those are the reviewer's and the
architect's stages, and failing here would double-count them.

State what you checked, not just the verdict. "No test references
`RateLimiter#allow?`" is evidence; "tests look thin" is not.
