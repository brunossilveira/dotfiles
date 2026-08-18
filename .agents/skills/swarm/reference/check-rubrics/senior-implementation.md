# Senior implementation check — agent rubric

Used when no test tool could be resolved. This stage applies architecture
findings and must preserve behavior exactly.

Fail on any of these:

- **Behavior changed.** Any test edited, deleted, or weakened. Any observable
  output that differs. An extraction that "fixes" something along the way is a
  failure of this stage, however good the fix.
- **A finding was not applied.** Compare against the architecture review: a
  finding is either applied, or explicitly handed back as a blocker. Silently
  skipped is a fail.
- **Work beyond the findings.** Modules the review called healthy were rewritten,
  or new abstractions appeared that no finding asked for.
- **An extraction without its tests.** Code moved to a new file with no test
  covering it there.

State each finding and what happened to it. A list is the evidence; a summary is
not.
