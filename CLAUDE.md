# CLAUDE.md

Personal dotfiles repo. Config files are symlinked to `$HOME` via `link.sh`.

## Non-obvious

- `link.sh` uses a **whitelist** — new files must be added to its whitelist array before they'll be linked.
- `./link.sh --dry-run` to preview changes before applying.
- Secrets live in `~/.secrets/vars` (never tracked, never commit).
- After `brew install <pkg>`, add it to `Brewfile` to persist across machines.
- Neovim uses Lazy.nvim with modular plugin specs in `config/nvim/lua/plugins/`.
- Three agents share one config set: `.claude/` (Claude Code), `.pi/` (PI), `.codex/` (Codex CLI).
  **Nothing is copied between them — every shared thing is a symlink, so editing the one real file
  updates all three.** Keep it that way when adding anything new.
  - Global instructions: `.claude/CLAUDE.md` is canonical. `.pi/agent/AGENTS.md`, `.codex/AGENTS.md`
    and the repo-root `AGENTS.md` all symlink to it.
  - Skills: `.claude/skills/` is canonical (some entries symlink on into `.pi/agent/skills/`).
    `.codex/skills` symlinks the whole directory, so a new skill reaches Codex automatically.
  - Slash commands: canonical file is `.agents/skills/<name>/SKILL.md`; `.claude/commands/<name>.md`
    symlinks to it. Codex 0.144 dropped custom prompts (`~/.codex/prompts` is dead) and reads
    `~/.agents/skills` instead — which Claude does not read, so they don't list twice in Claude.
  - Hooks: `.claude/hooks/deny-rm-rf.jq` is canonical; `.codex/hooks/` symlinks to it. Both
    harnesses take the same payload and the same `hookSpecificOutput.permissionDecision` reply.
- Codex follows *directory* symlinks but silently skips a symlinked `SKILL.md` — a skill's
  `SKILL.md` must be a real file or the skill vanishes with no error.
- Codex refuses to run a non-managed hook until it is trusted — run `/hooks` inside Codex after
  a fresh install, otherwise `.codex/hooks.json` silently does nothing.
- Codex writes machine-local state back into `~/.codex/config.toml` (project trust, TUI first-run
  flags). That file is a symlink into this repo, so expect diff noise to discard.
- Tag directories (`tag-ruby/`, `tag-nvim/`, `tag-software/`) each have their own setup scripts.
