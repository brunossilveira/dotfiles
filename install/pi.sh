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
fi
