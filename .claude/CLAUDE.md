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

Touch only what you must. Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing style.

Read surrounding code before adding to a file — exports, callers, shared utilities. Don't add code that duplicates or conflicts with existing code nearby.

Match the codebase's conventions, even if you disagree. If the codebase uses one pattern, don't introduce another. Disagreement is a separate conversation — don't fork it silently.

When two patterns in a codebase contradict, pick one (the more recent or more tested) and flag the other. Don't blend them.

Tests must encode why behavior matters, not just what it does. A test that can't fail when business logic changes is worthless.

On multi-step tasks, checkpoint: summarize what's done, what's verified, what's left. Don't continue from a state you can't describe.

Surface uncertainty. "Done" means verified, not assumed. If you skipped something or aren't sure it worked, say so explicitly.

## Preferences

- Concise output. Don't over-explain.
- Don't add AI attribution to commits or PRs.
- `vim` is aliased to `nvim` -- use nvim directly.
- `rm` is aliased to `rm -iv` in my shell, but Claude's Bash tool bypasses aliases. Be careful with destructive commands.
