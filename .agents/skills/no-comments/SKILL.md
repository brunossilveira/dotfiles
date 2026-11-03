---
name: no-comments
description: Delete comments from the current diff, keeping only a short list of exceptions, and flag the code that needed a comment to make sense
argument-hint: [files or a diff, or nothing for the current diff against the base branch]
---

Delete comments in this scope:

$ARGUMENTS

With no scope given, use the current diff against the base branch, including the
working tree. Never touch a comment outside the scope.

## What stays

Only these survive:

- Legal or license headers.
- Non-obvious behavior forced by an external dependency, platform, vendor, or
  protocol we cannot change, when the claim is still true today.
- Directives that tools read: shebangs, magic comments, pragmas, generated-file
  markers, formatter ignores.
- Lint suppressions whose rule is faulty, pedantic, or style-only.
- Doc comments that define a public API contract.
- Issue or RFC links that explain a constraint code cannot express.

When you are not sure an exception applies, delete the comment.

## What goes

Everything else: narration, banners, commented-out code, TODOs with no link, and
justifications for workarounds. `IMPORTANT`, `do not remove`, and `fine for now` are
claims, not exceptions. Read the nearby code and check the claim before deciding.

## Flag what the comment was hiding

- **A surprise in our own code.** Delete the comment and flag the symbol for a
  rename, extraction, type, or fix that makes the behavior obvious without prose.
- **A suppression whose rule protects correctness or safety.** Delete it and flag
  the code that triggered it. Do not silence it with a new comment.
- **A real constraint, such as "do not change this wording".** Offer the cheapest
  in-scope type, runtime check, test, or lint that enforces it. Keep the comment
  until I answer, then encode it and delete the comment, or delete it and report
  the constraint as unenforced.

Fix a trivial flag directly, such as deleting a dead path or dropping a parameter.
Report the rest. Do not widen the scope to fix them.

**Reply:** files touched, how many comments you deleted, each flag on one line, and
each comment you kept with the exception that saved it.

Adapted from pstack (MIT, Copyright (c) 2026 Lauren Tan): https://github.com/cursor/plugins/tree/main/pstack
