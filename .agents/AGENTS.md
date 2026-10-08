# Global Claude Code Instructions

## Communication

- When posting to Linear, drafting status messages, or explaining something, default to short plain English. Lead with the answer in 2-4 sentences. Include only what the reader needs to act. Leave out paging context, internal traces, and side details unless asked.
- When I ask to update a Linear ticket's description, edit the description. Do not add a comment instead.

## Git

Safe by default: `git status/diff/log` freely. Push only when asked.

Destructive ops (`reset --hard`, `clean`, `restore .`, `push --force`) forbidden unless I explicitly ask.

Write `--since` dates as `YYYY-MM-DD 00:00`. A bare date uses the current time of day.

### Before committing

- Run the full relevant test suite AND the typecheck for every package touched before every commit. Do not run only the new tests. This includes the Python suite in plugin repos and the AI-package typecheck in the monorepo.
- When adding a field to a type, grep for hand-built fixtures and test factories and update them too.
- Stage files explicitly. Check `git status` before each commit so unrelated staged changes do not end up in the wrong commit.

### Pull requests

- Never use unbounded values (tool-call IDs, session IDs, user IDs) as Datadog metric tags or attribute keys.
- Before opening a PR, self-review the diff the way Copilot would: check for unbounded cardinality, race conditions, muted/skipped edge cases, duplicate prompt content, and missing fixture updates.

## Verify, don't assume

- Never claim a process is running, a deploy is live, or a fix works without checking it first (ps/pgrep, Datadog via pup, a reload test).
- Surface uncertainty. "Done" means verified, not assumed. If you skipped something or aren't sure it worked, say so explicitly.

## Ruby / Rails

My main work project is a Rails app using Docker. Development commands use `make`:
- `make start` / `make stop` / `make restart`
- `make console` (Rails console)
- `make rspec <spec_files>` / `make tests <test_files>` -- always specify files
- `make rubocop app/models/` -- run on specific paths
- `make bash` (shell into container)

## Session Logging

I log sessions to Obsidian. Use `/log-session` at end of sessions. Vault is at $OBSIDIAN_VAULT_DIR.

## Coding Behavior

State assumptions before acting. If a simpler approach exists, push back. Ask before guessing.

Write the minimum code that solves the problem. No speculative features, no abstractions for single-use code, no premature generalization.

Touch only what you must. Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing style. Every changed line should trace directly to my request.

Unused code must go. Remove imports, variables, and functions that your changes made unused, and delete pre-existing dead code you come across.

If you find a broken thing adjacent to your change (e.g., a broken CLI command), fix it or flag it explicitly. Do not silently leave it.

Read surrounding code before adding to a file — exports, callers, shared utilities. Don't add code that duplicates or conflicts with existing code nearby.

Match the codebase's conventions, even if you disagree. If the codebase uses one pattern, don't introduce another. Disagreement is a separate conversation — don't fork it silently.

When two patterns in a codebase contradict, pick one (the more recent or more tested) and flag the other. Don't blend them.

Tests must encode why behavior matters, not just what it does. A test that can't fail when business logic changes is worthless.

Two banned test shapes:
- **Change-detector tests** — assert on data that is *expected* to change: model catalogs, config version literals, enumeration counts, hardcoded name lists. If the test reads like a snapshot of current data, delete it. If it reads like a contract about how two pieces of data must relate, keep it. `assert len(providers) == 8` ✗ / `assert every catalog entry has a context length` ✓.
- **Tests that read source text** — regexing a file's contents tests the shape of the source, not its behavior. It passes when the wiring is subtly broken and fails on correct refactors, so it blocks cleanups and gives false confidence. If the logic only exists inline in a god-file, extracting it into a callable unit is the fix, not a tighter regex.

Before calling something a bug, verify the premise. Most confident-but-wrong fixes rest on one of these:
- The limitation is intentional design, not a gap — the isolation IS the feature.
- The premise doesn't hold against how the code actually works — trace the runtime, don't trust the mental model.
- The absence was load-bearing — adding the obvious missing piece breaks what the omission was protecting.
- Scope creep that revives an approach already abandoned.

Bar to clear: point at the exact line where the bug manifests AND show the fix changes that line's behavior. A reproduction beats a plausible rationale.

On multi-step tasks, checkpoint: summarize what's done, what's verified, what's left. Don't continue from a state you can't describe.

Reframe vague tasks as verifiable goals before starting — a clear done-condition lets you loop independently instead of asking me to confirm:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

These caution-biased rules are for non-trivial work. For one-liners and throwaway tasks, use judgment — don't let them over-fire.

## Agentic Workflow

- Decompose by risk, not just size. Each unit should have a single dominant risk, be independently verifiable, and have a clear done condition. Small is not the same as well-scoped.
- TDD red must actually run. A test that's written but never executed doesn't count as failing — watch it fail before you make it pass.
- Parallelize by write surface, not by task. Run lanes concurrently only when their write surfaces are disjoint. Never parallelize migrations, same-table writes, or destructive commands without an explicit gate.
- Don't build for one-shots. Keep a one-off inline; only extract a script or skill once the task actually recurs.
- Repeated self-agreement isn't verification. An agent re-confirming its own answer across rollouts is not approval — gate destructive or outward-facing actions on an independent recheck, and default to dry-run.
- Compact at boundaries, not mid-debug. Compact after a milestone or phase transition, never during active debugging (you lose in-flight variable names and file paths). Continue a session for closely-coupled work; start fresh after a major phase change.
- For high-assurance changes (risky migrations, auth/security), run two independent review passes with clean context and ship only if both pass.

## Memory

Memories (in the harness memory dir) carry a confidence score and an evidence trail, so reinforced facts outrank one-off guesses.

Frontmatter adds `confidence` under `metadata` (range 0.3–0.9):

```yaml
metadata:
  type: user | feedback | project | reference
  confidence: 0.6
```

End the body with an `**Evidence:**` list of dated bullets recording each observation that created or reinforced the fact.

Scoring rules:
- Start at 0.6 when I state it explicitly; 0.4 when you infer it from behavior.
- Reinforce +0.1 (cap 0.9) and append an evidence bullet when the pattern recurs without correction.
- Contradict −0.2 and append a bullet when I correct or reject it. If confidence would fall below 0.3, delete the memory instead.
- On recall, weight higher-confidence memories more; treat anything below 0.5 as tentative and verify before acting on it.

Also maintain `log.md` in the memory dir: append a dated bullet whenever you create, reinforce, contradict, or delete a memory (`- YYYY-MM-DD — <verb> [[name]] — <one-line why>`). This is the bundle-level changelog; the per-file `Evidence:` lists stay too.

What belongs in memory:

- **Staleness test** — if a fact will be stale in a week, it doesn't belong in memory. Never store PR numbers, issue numbers, commit SHAs, "fixed bug X", "shipped Y", "Phase N done", file counts, or task progress. Recall those from past transcripts instead.
- **Declarative, not imperative** — `User prefers concise responses` ✓ / `Always respond concisely` ✗. `Project uses pytest with xdist` ✓ / `Run tests with pytest -n 4` ✗. Imperative phrasing gets re-read as a standing directive in a later session and can override what I'm actually asking for then. Procedures and workflows go in skills, not memory.
- **Prioritize what reduces future steering** — a memory that stops me repeating a correction is worth more than one that logs task detail.

## Preferences

- Don't add AI attribution to commits or PRs.
