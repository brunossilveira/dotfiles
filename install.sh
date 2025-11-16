#!/usr/bin/env bash
set -Eeuo pipefail
. "$(dirname "$0")/install/preflight/lib.sh"

main() {

# Repository configuration
DOTFILES_REPO="${DOTFILES_REPO:-brunossilveira/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-master}"
DOTFILES_DIR="$HOME/.dotfiles"

# Clone repository if we're not already in it
if [ ! -f "$(pwd)/install.sh" ] || [ "$(pwd)" != "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles repository..."
  rm -rf "$DOTFILES_DIR"
  git clone "https://github.com/${DOTFILES_REPO}.git" "$DOTFILES_DIR" >/dev/null
  
  if [ -n "$DOTFILES_REF" ] && [ "$DOTFILES_REF" != "master" ]; then
    cd "$DOTFILES_DIR"
    git fetch origin "$DOTFILES_REF" >/dev/null 2>&1
    git checkout "$DOTFILES_REF" >/dev/null
  fi
  
  cd "$DOTFILES_DIR"
  exec ./install.sh "$@"
fi

quietly_brew_bundle(){
  brew bundle --file="$1" | \
    grep -vE '^(Using |Homebrew Bundle complete)' || \
    true
}

if is_osx; then
  info "Installing Homebrew if not already installed..."
  if ! command -v brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  info "Installing Homebrew packages..."
  if [ -f "Brewfile" ]; then
    quietly_brew_bundle "Brewfile"
  fi

  info "Checking for command-line tools..."
  if ! command -v xcodebuild > /dev/null; then
    xcode-select --install
  fi
fi

if ! echo "$SHELL" | grep -Fq zsh; then
  info "Your shell is not Zsh. Changing it to Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  chsh -s /bin/zsh
fi

info "Linking dotfiles into ~..."

# Use the standalone link.sh script
"$DOTFILES_DIR/link.sh"

info "Installing zsh-syntax-highlighting..."
if [ ! -d ~/.zsh-plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-plugins/zsh-syntax-highlighting
fi

info "Installing tmux plugin manager..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

info "Installing oh my zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    echo "Warning: oh-my-zsh installation failed, continuing..."
  fi
else
  info "Oh My Zsh already installed, skipping..."
fi

info "Installing wd..."
if ! curl -L https://github.com/mfaerevaag/wd/raw/master/install.sh | sh; then
  echo "Warning: wd installation failed, continuing..."
fi

info "Running install scripts..."

for s in "$DOTFILES_DIR/install/"*.sh; do
  [[ -f "$s" ]] || continue
  bash "$s" || echo "Warning: $(basename "$s") failed"
done

if is_osx; then
  for s in "$DOTFILES_DIR/install/macos/"*.sh; do
    [[ -f "$s" ]] || continue
    bash "$s" || echo "Warning: $(basename "$s") failed"
  done
fi

}

# Call main function
main "$@"

