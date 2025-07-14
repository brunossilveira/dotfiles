# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that manages configuration files for development tools including Zsh, Neovim, Git, Ruby, and various macOS applications. The repository uses thoughtbot's RCM (rcm) for managing dotfiles installation and organization.

## Setup and Installation

### Initial Setup
```bash
# Clone the repository and run the full installation
./install.sh
```

The `install.sh` script:
- Installs Homebrew and all packages from `Brewfile`
- Sets up Zsh as the default shell with Oh My Zsh
- Links dotfiles using RCM
- Installs development tools and plugins
- Runs all tag-specific setup scripts

### Individual Component Setup
```bash
# Install specific components using tag setup scripts
./tag-git/setup      # Git hooks and configuration
./tag-ruby/setup     # Ruby/rbenv setup
./tag-nvim/setup     # Neovim setup
```

## Architecture

### Tag-Based Organization
The repository uses RCM's tag system to organize configurations:
- `tag-git/`: Git configuration, hooks, and templates
- `tag-ruby/`: Ruby development tools (rbenv, gems, etc.)
- `tag-nvim/`: Neovim configuration
- `tag-software/`: Software installation lists

### Key Configuration Files
- `rcrc`: RCM configuration defining dotfiles directories and exclusions
- `Brewfile`: Homebrew package definitions
- `zshrc`: Zsh shell configuration with Oh My Zsh
- `config/nvim/`: Neovim configuration using Lazy.nvim
- `tmux.conf`: Terminal multiplexer configuration

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
# Link new dotfiles
rcup -d .

# Check what would be linked without actually linking
rcup -d . -n

# Update dotfiles after changes
rcup -d .
```

### Git Configuration
Git hooks are automatically installed via `tag-git/setup` and include:
- Post-merge hook for automatic actions
- Ctags integration for code navigation
- Custom git message template

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
- Git hooks handle sensitive operations safely
- RCM excludes system files and installation scripts from linking

### Performance
- FZF configured to exclude large directories (tmp, node_modules)
- Rbenv and NVM properly initialized for fast shell startup
- Lazy loading of completion systems where possible