#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

info "Setting up n8n..."

# Ensure mise is available
if ! command -v mise &> /dev/null; then
  error "mise is not installed. Please run the main install.sh first."
  exit 1
fi

# Install Node.js via mise if not already installed
info "Ensuring Node.js is available via mise..."
mise use --global node@latest

# Install n8n globally via npm
info "Installing n8n globally..."
npm install -g n8n

# Create data directory for persistence
mkdir -p "$HOME/.n8n"

# Create launchd plist for auto-start on macOS
info "Setting up n8n as a system service..."
PLIST_PATH="$HOME/Library/LaunchAgents/com.n8n.plist"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.n8n</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(mise where node)/bin/node</string>
        <string>$(npm root -g)/n8n/bin/n8n</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.n8n/n8n.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.n8n/n8n.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>N8N_PORT</key>
        <string>5678</string>
        <key>PATH</key>
        <string>$(mise where node)/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

# Load the service
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

# Wait a moment for n8n to initialize
info "Waiting for n8n to start..."
sleep 5

# Import workflows from the dotfiles config directory
WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)/config/n8n/workflows"
if [ -d "$WORKFLOW_DIR" ] && [ "$(ls -A "$WORKFLOW_DIR"/*.json 2>/dev/null)" ]; then
  info "Importing workflows..."
  n8n import:workflow --separate --input="$WORKFLOW_DIR"

  # Restart n8n to load the imported workflows
  info "Restarting n8n to load workflows..."
  launchctl unload "$PLIST_PATH"
  sleep 2
  launchctl load "$PLIST_PATH"
  sleep 3
else
  info "No workflows found to import in $WORKFLOW_DIR"
fi

info "n8n setup complete!"
info "Access n8n at: http://localhost:5678"
info "Logs: ~/.n8n/n8n.log and ~/.n8n/n8n.error.log"
info "To stop: launchctl unload ~/Library/LaunchAgents/com.n8n.plist"
info "To restart: launchctl unload ~/Library/LaunchAgents/com.n8n.plist && launchctl load ~/Library/LaunchAgents/com.n8n.plist"
