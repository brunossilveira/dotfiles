#!/bin/bash

# Open a new scratch note in nvim with a timestamped filename.
# Usage:
#   scratch          — opens in current terminal
#   scratch --gui    — opens in a new Alacritty window (for Raycast/external use)

SCRATCH_DIR="${OBSIDIAN_VAULT_DIR:-/Volumes/NAS/bruno/vault}/scratch"
FALLBACK_DIR="$HOME/scratch"

# Use Obsidian vault if available, otherwise fall back to local
if [ -d "$(dirname "$SCRATCH_DIR")" ]; then
  DIR="$SCRATCH_DIR"
else
  DIR="$FALLBACK_DIR"
fi

mkdir -p "$DIR"

FILENAME="$(date '+%Y-%m-%d-%H%M%S').md"
FILEPATH="$DIR/$FILENAME"

if [ "$1" = "--gui" ]; then
  exec alacritty -e nvim "$FILEPATH"
else
  exec nvim "$FILEPATH"
fi
