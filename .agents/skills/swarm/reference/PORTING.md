# Provenance

The role set, the contract-beside-prompt idea, and the deterministic-advisor
shape come from [unclebob/swarm-forge](https://github.com/unclebob/swarm-forge),
branch `squad`, commit `9b7f405` (2026-08-17), which carries no LICENSE file.
The prompts here were rewritten against this runtime; nothing upstream is copied
verbatim any more.

## What was taken

- **Durable state as files**, so a dead session loses nothing and every fact has
  one home.
- **One deterministic advisor** as the only source of workflow order, with roles
  explicitly forbidden from inferring transitions themselves.
- **Contracts beside prompts** — `writes`, `forbidden_writes`, and whether a role
  may spawn or talk to the operator.
- **Writer/reviewer pairs** where the author never approves its own work and the
  reviewer never edits.
- **Bounded rework**, so a review loop turns into a blocker instead of running
  forever.
- **A simulator**, so the pipeline can be exercised without spending an agent
  turn.

## What was left behind, and why

- **The handoff daemon, the tmux topology, and the web dashboard.** They exist
  upstream because ten agents coordinate with no human watching. Here the pull
  requests are the window and the operator is in the session.
- **The Gherkin and QA-procedure lane** (four roles). Stories go straight to the
  implementer; acceptance intent lives in the story.
- **The `qa` role.** On a project with a real suite, independent verification is
  CI on the pull request — a fact to read, not an agent to spawn.
- **The `troubleshooter` role.** State surgery is the operator's, with the
  scripts in hand.
- **The Clojure tool table** (`crap4clj`, `dry4clj`, `clj-mutate`, the acceptance
  pipeline). Language-specific, and the hardener's job is stated behaviorally
  instead.
- **The mechanical apply loop.** The advisor advises; nothing applies transitions
  behind the operator's back.
