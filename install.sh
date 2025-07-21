#!/bin/bash

set -e

yellow() {
  tput setaf 3
  echo "$*"
  tput sgr0
}

info(){
  echo
  yellow "$@"
}

quietly_brew_bundle(){
  brew bundle --file="$1" | \
    grep -vE '^(Using |Homebrew Bundle complete)' || \
    true
}

is_osx(){
  [ "$(uname -s)" = Darwin ]
}


if is_osx; then
  info "Installing Homebrew if not already installed..."
  if ! command -v brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  info "Installing Homebrew packages..."
  brew tap homebrew/bundle
  for brewfile in Brewfile Brewfile.casks */Brewfile; do
    quietly_brew_bundle "$brewfile"
  done

  pip3 install neovim

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
./link.sh

info "Installing zsh-syntax-highlighting..."
if [ ! -d ~/.zsh-plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-plugins/zsh-syntax-highlighting
fi

info "Installing tmux pugin manager..."
if [ ! -d ~/.tmux/plugins/tmp ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

info "Installing powerline..."
if [ ! -d /usr/local/bin/powerline ]; then
  pip3 install powerline-status
fi

info "Installing oh my zsh..."
if [ ! -d ~/.oh_my_zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

info "Installing wd..."
curl -L https://github.com/mfaerevaag/wd/raw/master/install.sh | sh

info "Running all setup scripts..."
for install_script in ruby/install.sh software/install.sh system/install.sh; do
  if [ -f "$install_script" ]; then
    dir=$(basename "$(dirname "$install_script")")
    info "Running setup for ${dir}..."
    . "$install_script"
  fi
done
