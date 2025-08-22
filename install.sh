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

is_osx(){
  [ "$(uname -s)" = Darwin ]
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

# Dotfile linking configuration (use current directory since we've already cloned)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"

# Files to link - whitelist approach
DOTFILES_TO_LINK=(
    # Shell configuration
    "config/zshrc"
    "config/alias"
    "config/env"
    
    # Git configuration
    "config/gitconfig"
    "config/gitignore"
    
    # Development tools
    "config/ctags"
    "config/ackrc"
    "config/curlrc"
    "config/tmux.conf"
    "config/railsrc"
    "config/aerospace.toml"
)

# Directories to link recursively
DIRECTORIES_TO_LINK=(
    "config/nvim"
    "config/alacritty"
)

get_target_path() {
    local relative_path="$1"
    
    # Handle special cases
    case "$relative_path" in
        config/nvim/*)
            # Neovim config goes to ~/.config/nvim/
            echo "$TARGET_DIR/.${relative_path}"
            ;;
        config/gitconfig)
            echo "$TARGET_DIR/.gitconfig"
            ;;
        config/gitignore)
            echo "$TARGET_DIR/.gitignore"
            ;;
        config/*)
            # Other config files get dot prefix of just the filename
            local file_name="$(basename "$relative_path")"
            echo "$TARGET_DIR/.$file_name"
            ;;
        *)
            # Default: add dot prefix
            echo "$TARGET_DIR/.$(basename "$relative_path")"
            ;;
    esac
}

create_symlink() {
    local source="$1"
    local target="$2"
    local relative_path="$3"
    
    # Create target directory if it doesn't exist
    local target_dir="$(dirname "$target")"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    # Handle existing files/symlinks
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_link="$(readlink "$target")"
            if [ "$current_link" = "$source" ]; then
                return 0  # Already linked correctly
            else
                rm "$target"
            fi
        else
            mv "$target" "$target.backup"
        fi
    fi
    
    # Create the symlink
    ln -s "$source" "$target"
}

link_file() {
    local relative_path="$1"
    local source="$DOTFILES_DIR/$relative_path"
    
    if [ ! -e "$source" ]; then
        echo "Warning: Source file does not exist: $source"
        return 1
    fi
    
    local target="$(get_target_path "$relative_path")"
    create_symlink "$source" "$target" "$relative_path"
}

link_directory() {
    local relative_path="$1"
    local source_dir="$DOTFILES_DIR/$relative_path"
    
    if [ ! -d "$source_dir" ]; then
        echo "Warning: Source directory does not exist: $source_dir"
        return 1
    fi
    
    # Find all files in the directory
    while IFS= read -r -d '' file; do
        local file_relative="${file#$DOTFILES_DIR/}"
        local target="$(get_target_path "$file_relative")"
        create_symlink "$file" "$target" "$file_relative"
    done < <(find "$source_dir" -type f -print0)
}

# Link individual files
for file in "${DOTFILES_TO_LINK[@]}"; do
    link_file "$file"
done

# Link directories
for dir in "${DIRECTORIES_TO_LINK[@]}"; do
    link_directory "$dir"
done

info "Installing zsh-syntax-highlighting..."
if [ ! -d ~/.zsh-plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-plugins/zsh-syntax-highlighting
fi

info "Installing tmux plugin manager..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

info "Installing oh my zsh..."
if [ ! -d ~/.oh_my_zsh ]; then
  if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    echo "Warning: oh-my-zsh installation failed, continuing..."
  fi
fi

info "Installing wd..."
if ! curl -L https://github.com/mfaerevaag/wd/raw/master/install.sh | sh; then
  echo "Warning: wd installation failed, continuing..."
fi

info "Running install scripts..."
for install_script in install/*.sh; do
  if [ -f "$install_script" ]; then
    info "Running $(basename "$install_script")..."
    if ! . "$install_script"; then
      echo "Warning: $(basename "$install_script") failed, continuing..."
    fi
  fi
done

if is_osx; then
  for install_script in install/macos/*.sh; do
    if [ -f "$install_script" ]; then
      info "Running macOS $(basename "$install_script")..."
      if ! . "$install_script"; then
        echo "Warning: $(basename "$install_script") failed, continuing..."
      fi
    fi
  done
fi

}

# Call main function
main "$@"

