#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

info "Setting up n8n..."

# Ensure mise is available
if ! command -v mise &> /dev/null; then
  error "mise is not installed. Please run the main install.sh first."
  exit 1
fi

# Install Node.js v22 via mise for n8n compatibility
# n8n requires Node.js v18.17+, v20, or v22 (not v25+)
info "Ensuring Node.js v22 is available via mise for n8n..."
mise install node@22

# Install n8n globally using Node.js v22
info "Installing n8n globally with Node.js v22..."
N8N_NODE_VERSION=22
eval "$(mise env -s bash)" && mise exec node@${N8N_NODE_VERSION} -- npm install -g n8n

# Create data directory for persistence
mkdir -p "$HOME/.n8n"

# Load secrets to get API keys
source "$HOME/.secrets/vars" 2>/dev/null || true

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
        <string>$(mise where node@22)/bin/node</string>
        <string>$(mise exec node@22 -- npm root -g)/n8n/bin/n8n</string>
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
        <string>$(mise where node@22)/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>OPENAI_API_KEY</key>
        <string>${OPENAI_API_KEY}</string>
        <key>DB_SQLITE_POOL_SIZE</key>
        <string>3</string>
        <key>N8N_RUNNERS_ENABLED</key>
        <string>true</string>
        <key>N8N_BLOCK_ENV_ACCESS_IN_NODE</key>
        <string>false</string>
        <key>N8N_GIT_NODE_DISABLE_BARE_REPOS</key>
        <string>true</string>
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

# Import credentials from the dotfiles config directory
CREDENTIALS_DIR="$(cd "$(dirname "$0")/.." && pwd)/config/n8n/credentials"
if [ -d "$CREDENTIALS_DIR" ] && [ "$(ls -A "$CREDENTIALS_DIR"/*.json 2>/dev/null)" ]; then
  info "Importing credentials..."
  # Create temp directory with credentials, substituting environment variables
  TEMP_CREDS_DIR=$(mktemp -d)
  for cred_file in "$CREDENTIALS_DIR"/*.json; do
    filename=$(basename "$cred_file")
    # Substitute placeholders with actual values from environment (only if env var exists)
    sed -e "s/__OPENAI_API_KEY_PLACEHOLDER__/${OPENAI_API_KEY:-__OPENAI_API_KEY_PLACEHOLDER__}/g" \
        -e "s/__TWITTER_CLIENT_ID_PLACEHOLDER__/${TWITTER_CLIENT_ID:-__TWITTER_CLIENT_ID_PLACEHOLDER__}/g" \
        -e "s/__TWITTER_CLIENT_SECRET_PLACEHOLDER__/${TWITTER_CLIENT_SECRET:-__TWITTER_CLIENT_SECRET_PLACEHOLDER__}/g" \
        -e "s/__TWITTER_ACCESS_TOKEN_PLACEHOLDER__/${TWITTER_ACCESS_TOKEN:-__TWITTER_ACCESS_TOKEN_PLACEHOLDER__}/g" \
        -e "s/__TWITTER_ACCESS_TOKEN_SECRET_PLACEHOLDER__/${TWITTER_ACCESS_TOKEN_SECRET:-__TWITTER_ACCESS_TOKEN_SECRET_PLACEHOLDER__}/g" \
        "$cred_file" > "$TEMP_CREDS_DIR/$filename"
  done
  mise exec node@22 -- node $(mise exec node@22 -- npm root -g)/n8n/bin/n8n import:credentials --separate --input="$TEMP_CREDS_DIR"
  rm -rf "$TEMP_CREDS_DIR"
else
  info "No credentials found to import in $CREDENTIALS_DIR"
fi

# Import workflows from the dotfiles config directory
WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)/config/n8n/workflows"
if [ -d "$WORKFLOW_DIR" ] && [ "$(ls -A "$WORKFLOW_DIR"/*.json 2>/dev/null)" ]; then
  info "Importing workflows..."
  mise exec node@22 -- node $(mise exec node@22 -- npm root -g)/n8n/bin/n8n import:workflow --separate --input="$WORKFLOW_DIR"

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
