---
name: swarm
description: Multi-story orchestration — a deterministic advisor sequences the work and roles do it; single tasks are a swarm of one story
argument-hint: [theme, ticket id, or task description]
---

**Status: scaffolding.** The design is settled (`reference/DESIGN.md`) and the
roles and contracts are in place, but the advisor, the state directory, and the
spawn path are not written yet. Running this today gets you role prompts to
read, nothing that orchestrates. Use `work` until the advisor lands.

## The idea

Three parts, kept separate on purpose:

- **State on disk.** Every fact about the run — which story exists, which sha
  implemented it, which review accepted it, which gate the user approved — is a
  file, not a memory of the conversation. Sessions can die; the run continues.
- **A deterministic advisor sequences the work.** A script reads the state and
  prints the single next action. Roles do not choose, skip, or reorder the
  pipeline from prose, memory, or judgment. The model supplies judgment; the
  script supplies order.
- **Roles are prompt + contract.** A contract says what a role may write, what
  it may never write, and who it hands to. The orchestrator's contract forbids
  it from authoring product artifacts at all — it routes, it does not
  contribute.

A single task is not a special case: it is a run with one story.

A **run** carries one intent from a request to a set of merged pull requests —
one branch and one draft PR per story, stacked only where a dependency demands
it, and merged by the operator, never automatically. `reference/DESIGN.md` is
the full picture: the run structure, the loop, the gates, and what upstream
machinery is deliberately left out.

## Roles

The spine is `analyst -> implementer -> code-reviewer -> cleaner -> architect`;
the rest are enabled per story. `roles/` holds the persistent pair,
`role-templates/` the spawnable workers. Each has a `.prompt` (what it owns) and
a `.contract` (what it may touch: `key: value`, lists space-separated).

| Role | Owns |
| --- | --- |
| `squad-leader` | Talks to the user, routes work, records results, requests approvals. Authors no product artifact. |
| `analyst` | Intent to self-contained stories (INVEST), plus the dependency order the branch stack is built from. |
| `implementer` | Implements exactly one story, TDD, and opens its draft pull request. |
| `cleaner` | Behavior-preserving cleanup — names, cohesion, duplication, dead code. |
| `code-reviewer` | Reads the diff, writes a review artifact, returns `accepted` or `changes-requested`. Never edits the implementation. |
| `architect` | Reviews structure and dependency direction. Recommends only. |
| `hardener` | Optional. Robustness and edge handling on risky stories, after code review passes. |
| `senior-implementer` | Optional. Applies the architect's findings, behavior-preserving. |
| `merger` | Restacks a story branch after its parent merges. |

Carried over but not in the pipeline: `troubleshooter` (the pull requests are
the window, and the operator is in the session) and `qa` (independent
verification is CI on the PR, a fact to read rather than a role to spawn).

The shape worth keeping: **the author never approves itself** — reviewers read
and comment, never edit — and an **orchestrator that writes nothing**, only
routes.

## Still to build

`reference/DESIGN.md` decides the behavior; `reference/PORTING.md` lists what the
copied prompts still assume that this setup does not have.

1. State layout — stories, assignments, verdicts, gates, blockers, plus the run
   summary and journal. Lives outside the repository, keyed by repo and run id.
2. `scripts/swarm_next.sh` — the advisor. Bash. Pure function of the state.
3. Spawn path — subagent, worktree session, or headless Codex, chosen by write
   surface.
4. Gates — plan and review disposition stop for the operator; everything else
   runs through. Rework bounded at two cycles.
5. Prompt rewrite — strip the upstream runtime the roles still talk to.
6. A simulator, so the pipeline can be exercised without spending a single
   agent turn.
