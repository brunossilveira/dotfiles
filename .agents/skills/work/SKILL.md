---
name: work
description: Work a task end to end — gather context, design the code, implement with TDD, simplify, verify, request adversarial review when risk warrants it, and drive tickets to a merge-ready PR
argument-hint: [ticket id, prompt, or description of the work]
---

Work this task through the phases below, in order, without stopping to ask
whether to continue. Check in only for a real scope decision:

$ARGUMENTS

## 1. Gather context

Do not start editing until you know what the task actually is.

- **Ticket** (an id like `ABC-123` or `#123`, or a tracker URL — Linear,
  GitHub Issues, Jira, etc.): read it with whatever tool reaches that tracker
  (an MCP server, or a CLI like `gh issue view`) — the issue, its description,
  its comments, and any linked document or parent project. If no tool reaches
  it, ask the user to paste it. Take the acceptance criteria literally. Verify
  the ticket's premise against the code and, if relevant, the production
  telemetry (e.g. Datadog via `pup`). If the premise is wrong or already
  solved, comment on the ticket and stop.
- **A document or URL**: read it before working from the summary in the prompt.
- **File paths**: read them, plus their callers and their tests.
- **A plain description**: locate the relevant code with direct `rg` searches.
  Delegate only if direct searches fail or the relevant area remains ambiguous.

Then restate, in a few lines: what is being asked, what you will change, and
what "done" looks like as something verifiable. If two readings of the task
would produce materially different work, ask before designing the code.

## 2. Design the code

Before editing, describe the smallest viable code design. Keep it proportional:
one sentence for a local change; a short plan for substantive work. Identify:

- The behavior or invariant and its entry point.
- Which existing or new class/module owns it, and why.
- Changed collaborators, contracts, and data flow.
- The responsibility of each class/module the design adds or grows.
- The focused test boundary that will prove the behavior.

Follow established codebase patterns. Add an interface or abstraction only for
a real boundary, multiple implementations, or isolated volatility — never just
to wrap one use. Reject a design that gives a class a second reason to change or
a separate state cluster. Compare alternatives only when multiple credible
designs have a meaningful trade-off.

State assumptions. Ask a concise clarifying question before coding when an
answer would materially change behavior, public API, schema, ownership, or
scope. Otherwise state the assumption and proceed. Do not create a standalone
design document unless the user asks for one.

## 3. Implement with TDD

Write or adjust a focused behavioral test, run it, and confirm it fails for the
expected reason. If it does not, revisit the premise or design instead of
patching blindly. Implement the minimum code needed to make it pass, then run
that focused test green. Repeat in small red-green cycles when the behavior has
multiple increments. Do not run the final test set or linter yet.

## 4. Simplify

Invoke the `simplify` skill once. It owns both clarity and responsibility
placement. Tell it to defer tests and lint to the final verification phase.

## 5. Final verification

After all edits, run the full local check suite: typecheck for every affected
package, the Ruby, Python, and TS tests, lint/qlty, and diff coverage. This is
the single final verification phase; do not duplicate it earlier. If a failure
requires an edit, fix it and rerun the full suite before committing. `done`
means verified, not assumed — state anything that remains unverified. Commit
only after final verification succeeds.

## 6. Adversarial review when warranted

Spawn the separate Codex reviewer only when:

- The user explicitly requests it, including with `--review`; or
- The change has material risk involving authorization or security, schema or
  data, concurrency, external protocols or backwards compatibility, complex
  logic with important edge cases, or broad cross-component behavior.

Do not treat every code change as material risk. For a localized low-risk
change, skip the reviewer and state why.

When the gate matches, run:

```bash
~/.agents/skills/work/scripts/spawn-review.sh --focus "<one line: what this change is meant to do>"
```

Pass `--base BRANCH` for a non-default target. Wait for `DONE_FILE`, then read
`REPORT_FILE`. A non-zero exit or empty report is a failed review; show the log.
Treat findings as claims to verify, show them to the user, and do not act on
them before the user has seen them.

## 7. Drive the PR to green (tickets, or when asked for a PR)

Open the PR with the `open-pr` skill. Then loop until every check is green:
wait for CI and bot reviews (e.g. Copilot) with `gh pr checks --watch`, run
the `fix-pr` skill to fix every valid comment, reply to and resolve each
thread, and push.

Two kinds of red are acceptable: a check that also fails on the base branch
(prove it with a link to the failing base-branch run), and the human-approval
Review Policy check.

## 8. Close out

If the task came from a ticket, update its description (not a comment) with
what changed, the decisions made, and any follow-ups. File follow-ups as linked
sub-issues, or linked issues if the tracker has no sub-issues. If no tool can
write to the tracker, put that update in your summary for the user to paste.
End with a 5-line summary.
