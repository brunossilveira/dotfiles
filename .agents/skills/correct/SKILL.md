---
name: correct
description: Find the mistakes agents keep repeating in this repo and make each one impossible — architecture first, then types or lint, then tests, with docs last
argument-hint: [a mistake agents keep making, or nothing to mine history]
---

Agents in this repo keep making the same mistakes. Change the repo so the next
agent can't make them:

$ARGUMENTS

Assume every contributor is an agent that sees only the files it opened, copies
the nearest example, and takes the shortest path that compiles. Design the repo
so a change that looks right from one file is right for the whole repo.

## Find the mistake classes

Read recent commits, reverts, review comments, agent instruction files, comments
that explain workarounds, and this workspace's own session history if your harness
keeps one. Never read another project's history. Group the mistakes into classes.
A class counts once it has happened twice.

## Fix each class at the highest level that works

1. **Eliminate it with architecture.** Give each piece of state one owner and each
   task one supported way. Hide internals so the wrong import fails. Replace
   hand-synced lists with one source of truth. Delete old ways and dead code an
   agent would copy.
2. **Enforce it with types so the bad state can't be written.** If bad code still
   compiles, add a lint or CI check whose error names the file, type, or function
   to use instead. If the pattern is already common, fail only when a change adds
   more.
3. **Test the behavior.** Fix or delete any test that still passes when the
   behavior it checks breaks, or that fails when only the internals change.
4. **Write docs or agent rules last, only for judgment calls.** Nothing fails when
   an agent skips them.

## Fix and prove

Fix the most frequent classes now, one commit each. Prove each new check fails on
a real past mistake. Run the same command locally and in CI. An exception goes on
the offending line with a reason and an expiry date, and needs my approval.

## Keep the rule table

Keep a table in the repo's agent instruction file that pairs each rule with what
enforces it. When I correct you, fix the mistake and add the rule. If the rule was
already there and nothing enforces it, that's a repeat, so fix it at the highest
level in the same change. Drop a rule once its mistake can't happen.

**Reply:** each class with its evidence, the level you picked, and why a higher
level didn't work.

Adapted from pstack (MIT, Copyright (c) 2026 Lauren Tan): https://github.com/cursor/plugins/tree/main/pstack
