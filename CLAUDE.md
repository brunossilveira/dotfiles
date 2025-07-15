# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that manages configuration files for development tools including Zsh, Neovim, Git, Ruby, and various macOS applications. The repository uses a custom linking script for dotfiles installation and organization.

## Setup and Installation

### Initial Setup
```bash
# Clone the repository and run the full installation
./install.sh
```

The `install.sh` script:
- Installs Homebrew and all packages from `Brewfile`
- Sets up Zsh as the default shell with Oh My Zsh
- Links dotfiles using custom `link.sh` script
- Installs development tools and plugins
- Runs all tag-specific setup scripts

### Manual Linking
```bash
# Link dotfiles manually
./link.sh

# Preview changes without making them
./link.sh --dry-run

# Verbose output
./link.sh --verbose
```

## Architecture

### Custom Linking System
The repository uses a custom `link.sh` script that:
- Uses a whitelist approach for safe, predictable linking
- Creates symlinks from dotfiles to `$HOME`
- Handles nested directories (like `config/nvim/`)
- Provides backup and rollback capabilities
- Supports dry-run mode for testing

### Tag-Based Organization
Remaining tag directories organize related configurations:
- `tag-ruby/`: Ruby development tools (rbenv, gems, etc.)
- `tag-nvim/`: Neovim setup scripts
- `tag-software/`: Software installation lists

### Key Configuration Files
- `link.sh`: Custom dotfiles linking script
- `Brewfile`: Homebrew package definitions
- `zshrc`: Zsh shell configuration with Oh My Zsh
- `config/nvim/`: Neovim configuration using Lazy.nvim
- `tmux.conf`: Terminal multiplexer configuration
- `gitconfig`: Minimal git configuration optimized for lazygit
- `gitignore`: Global git ignore patterns

### Neovim Configuration
The Neovim setup uses Lazy.nvim as the plugin manager with a modular structure:
- `config/nvim/init.lua`: Entry point loading config and lazynvim
- `config/nvim/lua/config/`: Core configuration (keymaps, options)
- `config/nvim/lua/plugins/`: Plugin specifications and configurations

## Development Commands

### Package Management
```bash
# Update Homebrew packages
brew update && brew upgrade

# Install new packages
brew install <package>
# Then add to Brewfile for persistence
```

### Dotfiles Management
```bash
# Link dotfiles with custom script
./link.sh

# Preview changes
./link.sh --dry-run --verbose

# After adding new files, update link.sh whitelist
```

### Git Configuration
Git is configured for lazygit workflow with minimal CLI usage:
- Essential aliases: `st`, `cm`, `unstage`, `pf`
- Auto-rebase and fast-forward merge settings
- Global ignore patterns in `gitignore`

### Ruby Development
```bash
# Install latest Ruby version
rbenv install $(rbenv install --list | grep -v dev | tail -1)

# Set global Ruby version
rbenv global <version>

# Install gems from default-gems
rbenv default-gems
```

## Key Tools and Integrations

### Essential Tools (via Brewfile)
- `neovim`: Primary editor
- `tmux`: Terminal multiplexer
- `fzf`: Fuzzy finder
- `ripgrep`: Fast text search
- `gh`: GitHub CLI
- `rbenv`: Ruby version management
- `universal-ctags`: Code indexing

### Zsh Configuration
- Oh My Zsh with plugins: git, ruby, rails, rbenv, tmux, fzf
- Custom functions for git workflow (`g`, `branchify`, `changes`)
- FZF integration for file/command search
- Syntax highlighting via zsh-syntax-highlighting

### Environment Variables
- `EDITOR=nvim`: Default editor
- `FZF_DEFAULT_COMMAND`: Configured to ignore common build directories
- `HOMEBREW_NO_ANALYTICS=1`: Disable Homebrew analytics

## Special Considerations

### macOS Specific
- Homebrew installation uses `/opt/homebrew/bin` path for Apple Silicon
- Includes macOS-specific Oh My Zsh plugin
- System preferences automation in `system/osx-settings`

### Security
- Secrets loaded from `~/.secrets/vars` (not tracked in repo)
- Git configuration handles sensitive operations safely
- Custom linking script excludes system files and installation scripts

### Performance
- FZF configured to exclude large directories (tmp, node_modules)
- Rbenv and NVM properly initialized for fast shell startup
- Lazy loading of completion systems where possible

### Workflow Integration
- Git configuration optimized for lazygit UI usage
- Minimal CLI aliases for occasional terminal git operations
- Neovim plugins selected for modern development workflow