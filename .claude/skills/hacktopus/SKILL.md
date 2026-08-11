---
name: hacktopus
description: Run and manage AI coding sessions across repositories from the command line. Use when asked to start, list, inspect, archive, or delegate work to a hacktopus session, or when acting on the session you are running inside.
---

# hacktopus

hacktopus runs AI coding sessions across many repositories. Each session has a
working directory, runs durably in a terminal multiplexer, and outlives the
terminal you started it from.

If `$HACKTOPUS_SESSION_ID` is set, **you are inside a session** and that is
its id.

## Read the guide first

The guide ships inside the binary, so it always describes the version that is
installed. Prefer it over anything remembered:

    hacktopus guide            what hacktopus is, and the chapter list
    hacktopus guide driving    wait, tell and output — steering a session from outside
    hacktopus guide json       the output contract, and what a script may rely on
    hacktopus guide panels     the column beside a session, and how to change it
    hacktopus guide repos      registering repositories and putting them away
    hacktopus guide self       how a session identifies itself, and verbs that need no id
    hacktopus guide sessions   creating, listing, and the stop/archive/delete ladder

## The commands worth knowing without reading anything

    hacktopus session ls --json           what exists
    hacktopus session show <id> --json    record, git state, pull request
    hacktopus session new --repo <name> --name <what> --prompt "..."
    hacktopus session archive <id>        put it away, keeping its branch

Read verbs take `--json`. Ids may be abbreviated to any unambiguous prefix.

## Working alongside yourself

Two ways to get a second agent going, and they are not interchangeable:

    hacktopus session split --command "claude '...'"        a pane beside you, now
    hacktopus session new --repo <name> --name reviewer \
      --in "$PWD" --hidden --prompt "..."                   its own session, same directory

`split` is visible next to you and lasts as long as the window. `--in` makes a
real session in a directory that already exists — it appears in the sidebar,
survives a restart, and `session wait` can block on it. Both see the uncommitted
work in that directory; a plain `session new` gets its own worktree and does not.

`hacktopus session panes` says what is in a workspace and which pane may be closed.

## Search for the goal, not the word

hacktopus's nouns will not always be the user's. "Split this in two" is a
request for a second agent, and the chapter that answers it is `self`, not
`panels`. When a chapter tells you hacktopus cannot do something, check that
you are in the one that owns the goal before believing it.

## Two things that are easy to get wrong

**A pull request answers in three ways**, not two: `found`, `none`, and
`unavailable`. `none` means the work is unshared; `unavailable` means
hacktopus could not find out. Treating the second as the first sends you looking
for work that has already been pushed.

**Archive is reversible; delete is not.** `session archive` releases the
working directory and keeps the branch, so nothing is lost — the work lives in
git. `session rm` deletes the branch too.
