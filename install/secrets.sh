#!/usr/bin/env bash
set -Eeuo pipefail

info() { echo "→ $1"; }

SECRETS_DIR="$HOME/.secrets"
SECRETS_FILE="$SECRETS_DIR/vars"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

if [ -f "$SECRETS_FILE" ]; then
  info "$SECRETS_FILE already exists, leaving it alone"
else
  info "Creating $SECRETS_FILE template — copy the real values from another machine"
  cat > "$SECRETS_FILE" <<'EOF'
# Secrets — never tracked. Copy real values from another machine.
# export OPENAI_API_KEY=
# export TWITTER_CLIENT_SECRET=
# export TWITTER_ACCESS_TOKEN=
# export TWITTER_ACCESS_TOKEN_SECRET=
EOF
fi
chmod 600 "$SECRETS_FILE"

# zshrc sources it on macOS; on Linux the shell is bash and ~/.bashrc is unmanaged.
if [ "$(uname -s)" != Darwin ]; then
  SOURCE_LINE='[ -f ~/.secrets/vars ] && . ~/.secrets/vars'
  if ! grep -qxF "$SOURCE_LINE" "$HOME/.bashrc" 2>/dev/null; then
    info "Sourcing ~/.secrets/vars from ~/.bashrc"
    printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
  fi
fi
