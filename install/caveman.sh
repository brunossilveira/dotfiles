#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

info "Setting up caveman (Claude Code output-compression plugin)..."

# caveman is a Claude Code plugin. Install is idempotent — re-running just
# refreshes the marketplace and re-installs at the pinned scope.
if ! command -v claude &> /dev/null; then
  info "  claude CLI not found on PATH — skipping caveman plugin install."
  exit 0
fi

# The default-mode config (config/caveman/config.json -> ~/.config/caveman/)
# is symlinked by link.sh. Nothing to do here for defaults.

# Use a TMPDIR on the same filesystem as ~/.claude to dodge the plugin
# installer's cross-device rename bug (caveman #585).
export TMPDIR="$HOME/.claude/tmp"
mkdir -p "$TMPDIR"

if claude plugin list 2>/dev/null | grep -qi 'caveman@caveman'; then
  info "  caveman plugin already installed — skipping."
else
  claude plugin marketplace add JuliusBrussee/caveman
  claude plugin install caveman@caveman
fi

info "caveman setup complete. Default mode: lite (see ~/.config/caveman/config.json)."
