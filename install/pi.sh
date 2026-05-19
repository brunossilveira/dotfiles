#!/usr/bin/env bash
set -Eeuo pipefail

info() { echo "→ $1"; }

info "Installing PI coding agent..."

if command -v pi > /dev/null 2>&1; then
  current_version=$(pi --version 2>/dev/null || echo "unknown")
  info "PI already installed (v${current_version}), upgrading..."
  npm install -g @mariozechner/pi-coding-agent@latest
else
  npm install -g @mariozechner/pi-coding-agent
fi

# Verify installation
if command -v pi > /dev/null 2>&1; then
  info "PI $(pi --version) installed successfully"
else
  echo "Warning: PI installation failed. Install manually: npm install -g @mariozechner/pi-coding-agent"
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Copy global Claude instructions to PI agent config
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  mkdir -p "$DOTFILES_DIR/.pi/agent"
  cp "$HOME/.claude/CLAUDE.md" "$DOTFILES_DIR/.pi/agent/AGENTS.md"
  info "Copied CLAUDE.md to .pi/agent/AGENTS.md"
fi

# Apply patches
PI_ROOT="$(npm root -g)/@mariozechner/pi-coding-agent"
PATCHES_DIR="$DOTFILES_DIR/.pi/patches"

if [ -d "$PATCHES_DIR" ]; then
  for patch_file in "$PATCHES_DIR"/*.patch; do
    [ -f "$patch_file" ] || continue
    patch_name="$(basename "$patch_file")"
    if patch -p1 --dry-run -d "$PI_ROOT" < "$patch_file" > /dev/null 2>&1; then
      patch -p1 -d "$PI_ROOT" < "$patch_file"
      info "Applied patch: $patch_name"
    else
      echo "Warning: Patch $patch_name failed to apply (PI version may have changed)"
    fi
  done
fi
