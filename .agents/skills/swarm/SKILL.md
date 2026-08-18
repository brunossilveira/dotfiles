---
name: swarm
description: Work an intent end to end as a run — shape it into stories, then drive each story through implement, review, clean, and architecture to its own pull request, sequenced by a deterministic advisor
argument-hint: [intent, ticket id, or task description] | resume | status
---

Run the work described by:

$ARGUMENTS

With no argument, or with `resume`, continue the run already in progress. With
`status`, print the summary and stop.

`reference/DESIGN.md` explains why this is shaped the way it is. Read it before
changing any of it.

## The rule that matters

**You do not decide what happens next. `~/.agents/skills/swarm/scripts/swarm_next.sh` does.**

Run it, do exactly the one action it names, record the outcome, run it again.
Do not skip a stage because it looks unnecessary, do not reorder stages, do not
batch two actions because they seem related, and do not infer the next step from
this file, from memory, or from what the conversation was just talking about.
Your judgment goes *inside* an action — shaping stories, writing code, reviewing
a diff. Sequencing is the advisor's.

If the advisor's output contradicts what you believe about the run, the advisor
is right about sequence and you are possibly right about facts: check whether
something went unrecorded, record it, and ask again.

Every path the advisor prints is absolute, so the commands work from whatever
repository the run is in. The skill lives at `~/.agents/skills/swarm/`.

## Before starting

The repository needs: a GitHub remote, `gh` authenticated, and a clean working
tree. `codex` must be on PATH for the adversarial pass. The branch you are on
when the run starts becomes the run's base — every story branches from it and
every pull request targets it.

## Starting and resuming

```sh
~/.agents/skills/swarm/scripts/swarm_run.sh start "<intent>"     # new run; makes it current
~/.agents/skills/swarm/scripts/swarm_run.sh list                 # runs for this repository
~/.agents/skills/swarm/scripts/swarm_run.sh use <run-id>         # switch the current run
~/.agents/skills/swarm/scripts/swarm_summary.sh --print          # where the run stands
```

State lives outside the repository, under
`${XDG_STATE_HOME:-~/.local/state}/swarm/<repo>/runs/<run-id>/`, so per-story
worktrees all see the same run and nothing lands in a diff. A dead session loses
nothing: resume and the advisor picks up at the next action.

## The loop

```sh
~/.agents/skills/swarm/scripts/swarm_next.sh --all
```

It prints one `NEXT_ACTION`, the story it applies to, the reason, and the command
that records the result. `CONCURRENT:` lines list other stories with work
available — those are safe to run in parallel, because independent stories have
disjoint write surfaces by construction. Stacked stories never appear
concurrently with their parent.

After anything is recorded, run `~/.agents/skills/swarm/scripts/swarm_summary.sh`.

| `NEXT_ACTION` | What you do |
| --- | --- |
| `run_analyst` | Subagent with `~/.agents/skills/swarm/role-templates/analyst.prompt`, repository root, read-only. It writes `story.md` per story and registers each with `swarm_story.sh add`. Then request the plan gate. |
| `await_approval` | Stop. Show the operator the gate's question and the artifact it covers. Record their answer with `swarm_gate.sh approve/reject`. Never approve on their behalf. |
| `request_plan_approval` | Run the command it prints. |
| `create_worktree` | Run the command. It branches from the parent story's branch when there is one, from the run's base otherwise. |
| `run_implementer`, `rework_implementer` | Subagent with `~/.agents/skills/swarm/role-templates/implementer.prompt`, working **only** in the printed `WORKTREE`. Pass it the story's `story.md`, and for rework the review findings. It commits, then you **check before recording** (below). |
| `open_draft_pr` | Run the command. The PR opens as a draft so the run is visible in GitHub while the pipeline finishes. |
| `run_code_reviewer` | Subagent with `~/.agents/skills/swarm/role-templates/code-reviewer.prompt`, read-only in the worktree. Post its findings with `swarm_pr.sh comment`, record its verdict. |
| `run_adversarial_review` | `~/.agents/skills/swarm/scripts/swarm_review.sh run <story>`. Headless Codex, clean context, different model. It records its own verdict. Post the report to the PR. |
| `run_cleaner`, `run_hardener`, `run_senior_implementer` | Subagent with the matching prompt, in the worktree. Each commits, then you **check before recording** (below). |
| `run_architect` | Subagent with `~/.agents/skills/swarm/role-templates/architect.prompt`, read-only. Post findings, record the verdict. |
| `mark_pr_ready` | Run the command. Every stage cleared. |
| `await_ci` | Run `swarm_pr.sh sync <story>` and check again. Do not poll in a tight loop. |
| `await_merge` | Stop and tell the operator the PR is ready. **You never merge.** Take a concurrent lane if one is offered. |
| `record_merge`, `restack` | Run the command. If a restack conflicts, spawn a subagent with `~/.agents/skills/swarm/role-templates/merger.prompt` in that worktree. |
| `handle_blocker`, `open_blocker` | Stop. Report the blocker plainly and what it would take to clear it. Resolve only with `swarm_blocker.sh resolve` after the operator decides. |
| `complete_run` | Run the command and report what shipped. |
| `wait`, `none` | Say what the run is waiting on and stop. |

## Checking before recording

`implementation`, `cleanup`, `hardening`, and `senior-implementation` cannot be
recorded until their check passes. `swarm_story.sh record` refuses otherwise, so
the threshold lives outside the role that did the work:

```sh
~/.agents/skills/swarm/scripts/swarm_check.sh run <story> <stage>
```

It resolves the check from the languages the repository actually uses, or from a
`.swarm.conf` at the repo root when one exists (`check <stage> <command...>`,
`skip <stage>`), and runs it in the story's worktree. Three outcomes:

- `RESULT: pass` — record the stage.
- `RESULT: fail` — hand the log back to the role that produced the work and let
  it fix what failed. Do not record, and do not argue with the tool.
- `RESULT: fallback` — no tool exists for this stage here. Spawn a **read-only**
  subagent with the printed `RUBRIC`, the story's diff, and `story.md`; it
  returns `pass` or `fail` with evidence. Record its verdict with
  `swarm_check.sh record <story> <stage> <pass|fail> <detail>`, then proceed.
  The fallback agent must not be the one that did the work.

Capture the output before matching on it — piping into `grep -q` under
`pipefail` misreports, because the writer takes SIGPIPE when grep exits early.

## Spawning a role

Every worker gets: its role prompt, its contract, the story's `story.md`, the
worktree path, and the exact command that will record its result. Nothing else.
Workers do not spawn other workers, do not talk to the operator, and do not
touch a worktree that is not theirs.

## What you never do

- Merge a pull request. That is the operator's, always, even with green CI and an
  accepted review.
- Approve a gate, or treat a remembered "yes" as an approval. If it is not in
  `gates/`, it did not happen.
- Author product artifacts yourself. You route work and record results — see
  `~/.agents/skills/swarm/roles/orchestrator.contract`.
- Record a checked stage yourself when its check failed or was never run. The
  refusal is the point.
- Retry past the rework bound. Two changes-requested cycles on a story, or two
  rejected plans, and the advisor raises a blocker instead. Let it.

## Changing the pipeline

`~/.agents/skills/swarm/scripts/swarm_sim.sh` drives the advisor through a whole run with no agents and
no network, printing the tick trace. Run it after any change to
`swarm_next.sh`, including the paths that are meant to stop:

```sh
~/.agents/skills/swarm/scripts/swarm_sim.sh
~/.agents/skills/swarm/scripts/swarm_sim.sh --reviewer reject-once --architect reject-once
~/.agents/skills/swarm/scripts/swarm_sim.sh --reviewer reject-always     # expect a blocker, not a third attempt
```
