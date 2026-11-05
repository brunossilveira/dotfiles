---
name: handoff
description: Write portable continuation instructions when transferring work to another agent, harness, or working directory. Use for a handoff or continuation prompt, rather than an archival session log.
---

Write a short Markdown handoff for the next agent:

$ARGUMENTS

Check the current working directory, branch, commit, and working-tree changes
before describing their state. Preserve uncommitted work; link the relevant
diff or files rather than assuming the commit contains everything. Verify any
process or service the next agent is expected to use before calling it running.

Include only what the next session needs:

- **Goal and scope:** the requested outcome and constraints that still apply.
- **Verified state:** completed work, the checks actually run and their results,
  and anything unverified. Give exact commands when useful for continuing.
- **Decisions and evidence:** link existing plans, issues, commits, files, and
  research. Summarize only reasoning that those artifacts do not preserve.
- **Next action:** the first concrete step, remaining work, and blockers or
  decisions that need the user. Keep hypotheses distinct from proven causes.
- **Suggested skills:** name the available skills relevant to that next action.

Tailor the handoff to the requested focus. Exclude credentials, personal data,
and raw logs that do not help continuation. Describe an approved action and a
pending approval distinctly; a handoff does not grant new permissions.

Save a new file in the OS temporary directory unless the user gave a path.
Report its absolute path and confirm it can be read. Reference existing
artifacts instead of copying them: keep artifact-covered scope to a short
pointer and name the next action, leaving implementation procedures to the
suggested skill. Finish after writing the document; starting another agent or
sending it elsewhere requires a request to do so.
