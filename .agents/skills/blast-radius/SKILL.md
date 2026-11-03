---
name: blast-radius
description: Find what a change could break somewhere else before it ships, and prove the one fact it's safe because of by running real code
argument-hint: [a change, branch, PR, or nothing for the current diff]
---

Find what this change breaks somewhere else, before it ships:

$ARGUMENTS

Listing the callers is not the job. Any agent can grep those in a second. The job
is the breakage grep won't show you.

## How sure are you

A writeup that sounds right is worthless, because it reads as convincing whether
or not it's true. For each fact the change's safety depends on, get it as far down
this list as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line: a real `file:line`, or the library's own source.
3. You showed the bad case can't happen by walking the failure step by step.
4. You ran it: a script or test that calls the real code and fails loud if you're
   wrong.
5. You reproduced it in the running app.

Step 4 is usually one small script that imports the same library the app ships and
calls the exact function you're worried about.

## Steps

1. Read the change: the diff, the symbols it adds, changes, and deletes, and what
   it now does differently, including the part the diff doesn't spell out. Pull the
   PR and commits with `git log` and `gh pr view`.
2. Find the one fact it's safe because of. Most changes that look risky are safe
   because of a single fact, like "this call only drops already-dead cache entries
   and does nothing else". If it holds, most risky cases clear at once. Spend your
   time here, not on a long list of maybes.
3. Look where grep stops. Read the source of the library you call, and check its
   pinned version and any local patch. Work out when things run: callbacks,
   teardown, background jobs. Follow what a symbol search misses: the JSON an API
   returns, a DB column, a wire format, another language reading the same bytes, a
   feature flag, code three hops downstream.
4. Be honest about each risk. Give it a real chance of happening and a real cost if
   it does. Keep the risks you confirmed. List the ones you checked and cleared
   separately. Cite a real `file:line`. A search that finds nothing is still an
   answer. Never make up a caller or an API.
5. Prove the one fact. Write a script or test that runs the real code, run it, and
   paste what happened.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which level you got it to,
  and show the proof. If you couldn't prove it, write "unproven".
- **Risks.** Each names how it breaks, the `file:line`, how likely and how bad, and
  how to check. Paste the proof for the ones that matter.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug,
  including the script you wrote.

Adapted from pstack (MIT, Copyright (c) 2026 Lauren Tan): https://github.com/cursor/plugins/tree/main/pstack
