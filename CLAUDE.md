# CLAUDE.md

Personal dotfiles repo. Config files are symlinked to `$HOME` via `link.sh`.

## Non-obvious

- `link.sh` uses a **whitelist** — new files must be added to its whitelist array before they'll be linked.
- `./link.sh --dry-run` to preview changes before applying.
- Secrets live in `~/.secrets/vars` (never tracked, never commit).
- After `brew install <pkg>`, add it to `Brewfile` to persist across machines.
- Neovim uses Lazy.nvim with modular plugin specs in `config/nvim/lua/plugins/`.
- Tag directories (`tag-ruby/`, `tag-nvim/`, `tag-software/`) each have their own setup scripts.
