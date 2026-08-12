---
name: work
description: Work a task end to end — gather context, implement, simplify, then spawn an adversarial Codex review of the branch
argument-hint: [ticket id, prompt, or description of the work]
---

Work this task through all four phases, in order, without stopping to ask
whether to continue:

$ARGUMENTS

## 1. Gather context

Do not start editing until you know what the task actually is.

- **Linear ticket** (an id like `ABC-123`, or a `linear.app` URL): read it with
  the Linear tools — the issue, its description, its comments, and any linked
  document or parent project. Take the acceptance criteria literally.
- **A document or URL**: read it before working from the summary in the prompt.
- **File paths**: read them, plus their callers and their tests.
- **A plain description**: locate the relevant code first. Delegate a broad
  search rather than guessing at file names.

Then restate, in a few lines: what is being asked, what you will change, and
what "done" looks like as something verifiable. If two readings of the task
would produce materially different work, ask now — this is the only phase where
stopping to ask is cheap.

## 2. Do the work

Implement it. Write the minimum code that solves the problem, match the
surrounding conventions, and touch only what the task requires.

Run the tests, and the linter the repo actually uses. `done` means verified,
not assumed — if something is unverified, say so explicitly rather than
letting it pass.

Commit the work before the next phase, so the review has a branch to read.

## 3. Simplify

Invoke the `simplify` skill on the change. Let it apply its cleanups, then
re-run the tests — a quality pass that breaks the build is not done.

## 4. Spawn the adversarial review

Split this hacktopus session and hand the branch to Codex:

```bash
~/.agents/skills/work/scripts/spawn-review.sh --focus "<one line: what this change is meant to do>"
```

The script resolves the base branch itself (`origin/HEAD`, else `main`, else
`master`); pass `--base BRANCH` when the branch targets something else. It
opens Codex interactively in a pane beside you, so the review can be followed
up on there.

The pane is a second agent, not a subagent — its findings do not come back to
you. Stop here and tell the user what was done, what is verified, and that the
review is running next to them. Act on its findings only when they bring them
back.

If the script reports it is not inside a hacktopus session, do not work around
it — say so, and offer to run the review inline instead.
