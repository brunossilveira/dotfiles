#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

info "Installing fonts..."

# Create fonts directory if it doesn't exist
mkdir -p "$HOME/Library/Fonts"

# Check if CaskaydiaMono Nerd Font is already installed
if ! fc-list 2>/dev/null | grep -qi "CaskaydiaMono Nerd Font"; then
    info "Installing CaskaydiaMono Nerd Font..."
    
    # Create temporary directory and work in subshell
    ( TEMP_DIR=$(mktemp -d)
      cd "$TEMP_DIR"
      
      # Download CaskaydiaMono Nerd Font from official Nerd Fonts releases
      curl -L -o CascadiaMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
      
      # Extract and install fonts
      unzip -q CascadiaMono.zip -d CascadiaFont
      cp CascadiaFont/CaskaydiaMonoNerdFont-*.ttf "$HOME/Library/Fonts/"
      
      # Clean up in subshell
      rm -rf "$TEMP_DIR"
    )
    
    # Refresh font cache
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f
    fi
    
    info "CaskaydiaMono Nerd Font installed successfully!"
else
    info "CaskaydiaMono Nerd Font is already installed."
fi
