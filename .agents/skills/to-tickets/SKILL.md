---
name: to-tickets
description: Turn an agreed plan, spec, or conversation into self-contained implementation tickets with acceptance criteria and explicit blockers. Use when breaking work into tickets; use shaping when the solution still needs decisions and work to implement a ticket.
---

Turn this work into tickets an agent can execute in a fresh session:

$ARGUMENTS

## Gather the contract

Read the source plan or issue, including relevant discussion, and inspect the
code it concerns. Reuse settled decisions. If a missing decision changes the
behavior or scope, ask about that decision before presenting the affected
ticket as ready. Facts available in the repository are yours to look up.

This phase is complete when the desired behavior, scope, and unresolved
decisions are explicit.

## Draft the work

Prefer a narrow, complete path through the layers that own the behavior. Each
ticket must deliver an independently verifiable outcome and fit one session.
Backend and CLI outcomes qualify; a slice does not require a UI. Include a
prerequisite refactor only when the implementation actually needs it.

For a broad mechanical migration that cannot land in vertical slices, sequence
expand, migrate, and contract: introduce the compatible form, move callers in
batches that stay green, then remove the old form after all callers move. Keep
destructive contraction explicit and separately authorized.

Give every ticket:

- **Title:** a short name describing its outcome.
- **Source:** a link or path to the parent plan or issue, when one exists.
- **Current and desired behavior:** enough context to work without this chat.
- **Acceptance criteria:** observable results that establish completion.
- **Blocked by:** the tickets whose results this one actually requires, or none.
- **Out of scope:** adjacent work the ticket might otherwise attract.

Use domain terms and contracts. Current symbols and paths may help discovery,
but re-read the implementation rather than treating a line number as a plan.

Check that every in-scope requirement has a ticket, blockers exist, the graph
has no cycles, and each dependent ticket states what it needs from its blocker.
Do not impose an order between otherwise independent tickets. Note overlapping
write surfaces so their execution can be coordinated without inventing logical
dependencies. Present the breakdown and flag any unresolved decision that
prevents a ticket being ready.

## Save or publish

Default to a local draft. Follow an existing ticket-file convention; otherwise
use one Markdown file per ticket in a descriptive directory under the OS
temporary directory. Report the paths and which tickets can start now.

Publish only when the user requests it. For a requested tracker write, inspect
existing tickets first to avoid duplicates, then create missing tickets before
wiring native dependency links with their real IDs. Reuse existing issues on
retry. Ask only about a material unresolved scope decision or missing required
tracker information. Leave the parent issue's state unchanged unless asked.

Finish when the requested drafts or tracker entries exist and their contents
and dependencies have been read back. Creating tickets does not authorize
implementing them, posting unrelated messages, or pushing code.
