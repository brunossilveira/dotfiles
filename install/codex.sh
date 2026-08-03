#!/usr/bin/env bash
set -Eeuo pipefail

info() { echo "→ $1"; }

info "Installing Codex CLI..."

if command -v codex > /dev/null 2>&1; then
  info "Codex already installed ($(codex --version 2>/dev/null || echo unknown)), updating..."
  codex update || echo "Warning: codex update failed, continuing..."
else
  npm install -g @openai/codex
fi

if ! command -v codex > /dev/null 2>&1; then
  echo "Warning: Codex installation failed. Install manually: npm install -g @openai/codex"
  exit 1
fi

info "Codex $(codex --version) ready"

# link.sh symlinks ~/.codex/{config.toml,AGENTS.md,hooks.json,prompts,hooks,skills}.
# Codex won't run a non-managed hook until it is trusted — review and approve
# them once with the /hooks command inside Codex.
info "Reminder: run /hooks inside Codex once to trust ~/.codex/hooks.json"
