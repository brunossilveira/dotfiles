# Cleanup check — agent rubric

Used when no duplication, complexity, or lint tool could be resolved. Cleanup is
behavior-preserving, so this check has two halves: it must have changed nothing
observable, and it must have been worth doing.

Fail on any of these:

- **Behavior changed.** A test was edited, deleted, or its expectations moved. A
  branch condition flipped. A default value differs. Cleanup that changes a test
  is not cleanup.
- **Nothing meaningful happened.** The diff is whitespace, comment churn, or
  renames that carry no more meaning than the names they replaced. An empty
  cleanup should fail rather than be waved through.
- **Duplication left in place.** Two or more blocks in the story's diff express
  the same decision. Point at the exact ranges.
- **A function still does several things.** Multiple levels of abstraction in one
  body, or a name that needs "and" to describe it honestly.
- **Scope creep.** Files the story never touched were cleaned. That is someone
  else's diff and someone else's risk.
- **Dead code introduced or left behind by this change.** Pre-existing dead code
  elsewhere is not this check's business.

State the ranges you examined. If the diff is small and already clean, that is a
`pass` — say so plainly rather than inventing work.
