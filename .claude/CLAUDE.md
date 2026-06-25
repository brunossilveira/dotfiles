# Global Claude Code Instructions

## Shell & Tools

I use zsh (oh-my-zsh). Editor is nvim. Terminal multiplexer is tmux (prefix C-a, vim keys).

Available tools:
- `gh` for all GitHub interactions (PRs, issues, CI)
- `lazygit` for interactive git (my primary git UI)
- `mise` for runtime version management (replaces rbenv, nvm)
- `fzf` for fuzzy finding
- `rg` (ripgrep) for searching
- AeroSpace for tiling window management

## Git

Safe by default: `git status/diff/log` freely. Push only when asked.

Destructive ops (`reset --hard`, `clean`, `restore .`, `push --force`) forbidden unless I explicitly ask.

I have these aliases: `g` (status or git), `gd` (diff), `ga` (add), `gpr` (gh pr create), `amend` (commit --amend -Chead).

## Ruby / Rails

My main work project is a Rails app using Docker (OrbStack). Development commands use `make`:
- `make start` / `make stop` / `make restart`
- `make console` (Rails console)
- `make rspec <spec_files>` / `make tests <test_files>` -- always specify files
- `make rubocop app/models/` -- run on specific paths
- `make bash` (shell into container)

Bundler: `be` is aliased to `bundle exec`.

## Session Logging

I log sessions to Obsidian. Use `/log-session` at end of sessions. Vault is at $OBSIDIAN_VAULT_DIR.

## Coding Behavior

State assumptions before acting. If a simpler approach exists, push back. Ask before guessing.

Write the minimum code that solves the problem. No speculative features, no abstractions for single-use code, no premature generalization.

Touch only what you must. Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing style. Every changed line should trace directly to my request.

Clean up only your own mess. Remove imports/variables/functions that YOUR changes made unused. Leave pre-existing dead code alone — mention it, don't delete it unless I ask.

Read surrounding code before adding to a file — exports, callers, shared utilities. Don't add code that duplicates or conflicts with existing code nearby.

Match the codebase's conventions, even if you disagree. If the codebase uses one pattern, don't introduce another. Disagreement is a separate conversation — don't fork it silently.

When two patterns in a codebase contradict, pick one (the more recent or more tested) and flag the other. Don't blend them.

Tests must encode why behavior matters, not just what it does. A test that can't fail when business logic changes is worthless.

On multi-step tasks, checkpoint: summarize what's done, what's verified, what's left. Don't continue from a state you can't describe.

Surface uncertainty. "Done" means verified, not assumed. If you skipped something or aren't sure it worked, say so explicitly.

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

## Preferences

- Concise output. Don't over-explain.
- Don't add AI attribution to commits or PRs.
- `vim` is aliased to `nvim` -- use nvim directly.
- `rm` is aliased to `rm -iv` in my shell, but Claude's Bash tool bypasses aliases. Be careful with destructive commands.
