# Design

What a swarm run is and how it behaves. Decisions here are settled; mechanics
(file formats, script interfaces, prompt rewrites) are not, and deliberately are
not described. `PORTING.md` covers what still has to change in the copied
prompts to match this.

## The run

A **run** is one user intent carried from a request to a set of merged pull
requests. It has a durable identity, a goal, a done-condition, and it survives
the session that started it.

Four nested things:

- **Run** — the intent. Owns the story set, the dependency order, and the record.
- **Story** — an independently valuable, independently verifiable slice. Moves
  through the pipeline on its own clock; two stories can sit at different stages
  at once. Produces exactly one branch and one pull request.
- **Stage** — a named fact about a story: implemented at this sha, reviewed with
  this verdict, cleaned, architecturally accepted. A stage is history, not a
  task, and it outlives whatever produced it.
- **Assignment** — one role, one story, one stage, one attempt. The only thing
  ever retried, replaced, or abandoned. Rework creates a linked new assignment
  rather than mutating the old one, so the trail of what was rejected stays
  readable.

The consequence that matters: **agents are disposable, assignments are not.** A
worker that dies takes nothing with it — its assignment simply needs another
attempt.

## The loop

Every tick is the same four beats:

1. **Observe** — read the recorded state of the run. Not chat history, not
   memory, not the previous message.
2. **Decide** — an advisor computes the single highest-priority next action from
   that state. Deterministic: same state, same answer, whichever model asks.
3. **Act** — execute exactly that action and nothing else.
4. **Record** — write the outcome down before deciding anything again.

The model supplies judgment *inside* an action: shaping stories, writing code,
reviewing a diff, resolving a conflict. It never supplies sequencing. Roles do
not choose, skip, or reorder stages from prose, memory, or their own reading of
the situation — that split is what makes a run resumable and auditable, and what
stops a session from deciding it already did a phase it skipped.

## Pipeline

The spine, in order:

```
analyst -> implementer -> code-reviewer -> cleaner -> architect
```

Optional stages, enabled per story rather than always on:

- `hardener` — risky or high-blast-radius stories.
- `senior-implementer` — only when the architect returns changes-requested.
- `merger` — narrowed to restacking after a parent story merges.

`qa` is not a role. On a project with a real test suite, independent
verification is CI on the pull request, which is a durable fact the advisor can
read rather than an agent it has to spawn.

`troubleshooter` is not carried over. It exists upstream because a human cannot
see inside a ten-agent swarm; here the pull requests are the window and the
operator is already in the session.

The analyst runs even for a single-story run. A one-story run does not need
shaping, but it does need the plan gate — the cheapest place to catch a misread
task before any code exists.

## Branches and pull requests

`master` is the only trunk. One story, one branch, one pull request.

- Independent stories branch from `master` and run in parallel.
- A story that depends on another branches from that story's branch, and its
  pull request targets that branch. The stack is the dependency order made
  physical.
- Stack depth is capped. A deep stack means the analyst split along the wrong
  axis; the run should say so rather than build a tower.
- When a parent merges, its children are restacked onto the new base. This is
  the recurring chore stacking buys, and it is the `merger` role's whole job.

The pull request opens **as a draft, right after the implementer's first
commit**. Review, cleanup, hardening, and architecture all land as commits on
that branch while the draft is open, and it goes ready-for-review once the
internal pipeline passes. This makes the run observable through GitHub instead
of through a dashboard.

Parallelism needs no separate heuristic: independent stories have disjoint write
surfaces by construction, and stacked stories are by definition sequential. The
dependency graph already says what may run at once. The only remaining limit is
how many workers are wanted alive at a time.

## Reviews and gates

Two review layers, kept distinct:

- **In-pipeline review** — `code-reviewer` plus an adversarial pass from a
  different model with clean context. Runs before the pull request is ready.
  Findings post as pull request comments; the machine-readable verdict
  (`accepted` / `changes-requested`) is recorded in run state. Neither reviewer
  edits the implementation.
- **The merge** — always the operator's, never automatic, even with green CI and
  an accepted review. A merged pull request *is* the final approval, durably
  recorded by GitHub, so the run keeps no separate final-approval record.

That leaves two gates that stop the run and wait:

1. **Plan** — the story split and dependency order, before any code.
2. **Review disposition** — what the pipeline does with findings, when the
   operator disagrees with a reviewer.

An approval is real only once it is recorded. A remembered "yes" did not happen.

Rework is bounded at **two cycles**. A third changes-requested on the same story
stage becomes a blocker instead of another attempt. The plan gate counts the
same way: two rejected plans, then stop and talk.

## Checks

Four stages produce work rather than opinions — implementation, cleanup,
hardening, senior implementation — and each is gated by a check that runs
outside the role that did the work. A stage cannot be recorded until its check
passes.

The threshold lives in a command, not in an agent's judgment, because a tool
that exits non-zero cannot be talked around. Which command depends on the
repository: the languages present decide, a `.swarm.conf` at the repo root
overrides, and `skip <stage>` opts out explicitly rather than silently.

**Deterministic first, always.** A language that has a defined check for a stage
gets that check and nothing else. If its tool is not installed, the run stops
and names what is missing — it does not quietly downgrade to an opinion, because
a real bar exists and skipping it would be invisible in the record afterwards.
This is the property swarm-forge buys by owning its language; keeping it means
accepting that a repo sometimes has to install something before a stage can
pass.

An agent judges against a written rubric in exactly one case: no check is
defined for that language at that stage. That path exists so an unsupported
language does not stop the run outright, not as a general substitute. It is
weaker by construction, so it keeps the shape — separate actor, recorded
verdict, evidence required — and records `source: agent`, which the summary
shows, so a run gated by opinions never reads like one gated by measurements.

The fallback agent is never the one that produced the work.

A rework cycle supersedes the checks that passed for the work it replaces, so a
story cannot inherit a green check from a version of the code that no longer
exists.

## State

Run state lives **outside the repository**, keyed by repo and run id — not in a
working tree. Per-story worktrees each see their own checkout, so repo-local
state would fork; external state is worktree-agnostic, survives branch switches,
never appears in a diff, and cannot be committed by a worker by accident.

The run keeps two records, both of them cheap:

- **A summary** — rewritten whenever anything changes. One screen: the intent,
  each story with its stage, pull request, and verdict, open blockers, and what
  is waiting on the operator. This is the thing to read.
- **A journal** — append-only, one line per decision and outcome. This is the
  thing to read when something went wrong.

## Invocation

`/swarm <intent>` starts a run. `/swarm` with no argument reads the existing run
and continues it. Durable state plus re-entrancy is what makes a dead session a
non-event: reattach and the loop picks up at the next action.

## Pauses, blockers, and termination

Three reasons a run is not moving, and they must be distinguishable:

- **Gate** — waiting on an operator decision. Healthy.
- **Capacity** — the next action is known but a slot or a dependency is not
  ready. Healthy.
- **Blocker** — anything else. A durable record with an owner. A run with an
  open blocker is stopped, and says so loudly rather than appearing busy.

A run ends in exactly one of three ways, stated explicitly:

- **Complete** — every story merged.
- **Blocked** — an open blocker nobody resolved. State stays intact.
- **Abandoned** — called off. State stays for the record.

## Substrate

Roles are prompt plus contract; what runs them is a separate question, decided by
write surface:

- **Read-only roles** (analyst shaping, architecture review, audits) — subagents.
  No worktree needed, no isolation problem to solve.
- **Writing roles** (implementer, cleaner, senior-implementer) — a session with
  its own worktree and branch, one per story.
- **Adversarial review** — headless Codex against the branch, findings captured
  to a file. A different model with clean context is the point; a session
  reviewing its own diff is the weakest link in the current `work` skill.

## Deliberately not built

Upstream solves problems this design does not have. Not carried over: the
handoff daemon and file transport, the tmux socket topology, the web dashboard,
the Gherkin and QA-procedure lane, the Clojure tool table, and the mechanical
apply loop. Each exists because ten agents coordinate without a human watching.
Here the operator is present, GitHub holds the integration state, and the
advisor runs on demand.
