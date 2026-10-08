# AGENTS.md

Personal dotfiles repo. Config files are symlinked to `$HOME` via `link.sh`.

## Dotfiles / config

- These dotfiles run on BOTH macOS and Omarchy (Arch Linux). Never put OS-specific settings (credential helpers, paths, shells, zsh) in shared files. Use per-OS includes or conditionals (see the `link.sh` and git credential notes below).
- Prefer the simplest fix (untrack a file, remove a symlink) over new system-level layers or anything that needs sudo.
- Stay strictly in scope. Do not change aliases or unrelated config unless asked.

## Non-obvious

- `link.sh` uses a **whitelist** — new files must be added to its whitelist array before they'll be linked.
- `link.sh` is OS-aware: entries in the `OSX_*` arrays (zshrc, tmux.conf, aerospace, alacritty,
  ghostty) are skipped on Linux. On Omarchy the shell is bash and Ghostty is theme-managed.
- Skill dirs (`.claude/skills`, `.pi/agent/skills`, `.codex/skills`) are linked **per child**, not as
  one directory symlink, so Omarchy's own `omarchy`/`diagnose-crash` skill symlinks survive in place.
- Git credential helper is OS-specific: `config/gitconfig` includes `~/.gitconfig.os`, which
  `link.sh` points at `config/gitconfig.macos` (osxkeychain) or `config/gitconfig.linux`
  (`gh auth git-credential`). Put other OS-only git settings there, not in `config/gitconfig`.
- `./link.sh --dry-run` to preview changes before applying.
- Secrets live in `~/.secrets/vars` (never tracked, never commit).
- After `brew install <pkg>`, add it to `Brewfile` to persist across machines.
- Neovim uses Lazy.nvim with modular plugin specs in `config/nvim/lua/plugins/`.
- Three agents share one config set: `.claude/` (Claude Code), `.pi/` (PI), `.codex/` (Codex CLI).
  **Nothing is copied between them — every shared thing is a symlink, so editing the one real file
  updates all three.** Keep it that way when adding anything new.
  - Global instructions: `.agents/AGENTS.md` is the one real file. `.claude/CLAUDE.md`,
    `.codex/AGENTS.md`, and `.pi/agent/AGENTS.md` symlink to it. The `CLAUDE.md` name has to stay:
    Claude Code reads `AGENTS.md` only at project level, never `~/.claude/AGENTS.md`.
  - Project instructions: this file (`AGENTS.md`). There is no root `CLAUDE.md`; Claude Code reads
    `AGENTS.md` because `.claude/settings.json` sets the `cc-plugin-agents-md@builtin` option
    `instructionFiles` to `claude-md-and-agents-md` (the repo's `.claude/CLAUDE.md` would otherwise
    count as a project `CLAUDE.md` and suppress `AGENTS.md`).
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
- `~/.codex/config.toml` is deliberately **not** tracked or linked: Codex rewrites it with
  machine-local state (project trust, hook hashes, app paths), which conflicted between macOS and
  Linux. Each machine keeps its own real file.
- Tag directories (`tag-ruby/`, `tag-nvim/`, `tag-software/`) each have their own setup scripts.
