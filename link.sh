#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"
VERBOSE=false
DRY_RUN=false

# Files to link - whitelist approach
DOTFILES_TO_LINK=(
    # Shell configuration
    "zshrc"
    "alias"
    "env"
    
    # Git configuration
    "gitconfig"
    "gitignore"
    
    # Development tools
    "ctags"
    "ackrc"
    "curlrc"
    "tmux.conf"
    "railsrc"
    
    # Ruby configuration
    "tag-ruby/gemrc"
    "tag-ruby/irbrc"
    "tag-ruby/pryrc"
    "tag-ruby/rspec"
    "tag-ruby/rbenv/default-gems"
)

# Directories to link recursively
DIRECTORIES_TO_LINK=(
    "config/nvim"
)

usage() {
    echo "Usage: $0 [-v] [-n] [-h]"
    echo "  -v, --verbose    Show verbose output"
    echo "  -n, --dry-run    Show what would be done without actually doing it"
    echo "  -h, --help       Show this help message"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    local relative_path="$3"
    
    # Create target directory if it doesn't exist
    local target_dir="$(dirname "$target")"
    if [ ! -d "$target_dir" ]; then
        verbose "Creating directory: $target_dir"
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$target_dir"
        fi
    fi
    
    # Handle existing files/symlinks
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_link="$(readlink "$target")"
            if [ "$current_link" = "$source" ]; then
                verbose "identical: $relative_path"
                return 0
            else
                warning "Removing existing symlink: $target -> $current_link"
                if [ "$DRY_RUN" = false ]; then
                    rm "$target"
                fi
            fi
        else
            warning "Backing up existing file: $target -> $target.backup"
            if [ "$DRY_RUN" = false ]; then
                mv "$target" "$target.backup"
            fi
        fi
    fi
    
    # Create the symlink
    if [ "$DRY_RUN" = true ]; then
        success "would link: $relative_path -> $target"
    else
        ln -s "$source" "$target"
        success "linked: $relative_path -> $target"
    fi
}

get_target_path() {
    local relative_path="$1"
    
    # Handle special cases
    case "$relative_path" in
        config/*)
            # Config files go to ~/.config/
            echo "$TARGET_DIR/.$relative_path"
            ;;
        gitconfig)
            echo "$TARGET_DIR/.gitconfig"
            ;;
        gitignore)
            echo "$TARGET_DIR/.gitignore"
            ;;
        tag-ruby/*)
            # Ruby files get dot prefix
            local file_name="$(basename "$relative_path")"
            echo "$TARGET_DIR/.$file_name"
            ;;
        *)
            # Default: add dot prefix
            echo "$TARGET_DIR/.$(basename "$relative_path")"
            ;;
    esac
}

link_file() {
    local relative_path="$1"
    local source="$DOTFILES_DIR/$relative_path"
    
    if [ ! -e "$source" ]; then
        warning "Source file does not exist: $source"
        return 1
    fi
    
    local target="$(get_target_path "$relative_path")"
    create_symlink "$source" "$target" "$relative_path"
}

link_directory() {
    local relative_path="$1"
    local source_dir="$DOTFILES_DIR/$relative_path"
    
    if [ ! -d "$source_dir" ]; then
        warning "Source directory does not exist: $source_dir"
        return 1
    fi
    
    verbose "Linking directory: $relative_path"
    
    # Find all files in the directory
    while IFS= read -r -d '' file; do
        local file_relative="${file#$DOTFILES_DIR/}"
        local target="$(get_target_path "$file_relative")"
        create_symlink "$file" "$target" "$file_relative"
    done < <(find "$source_dir" -type f -print0)
}

link_dotfiles() {
    log "Linking dotfiles from $DOTFILES_DIR to $TARGET_DIR"
    
    
    # Link individual files
    for file in "${DOTFILES_TO_LINK[@]}"; do
        link_file "$file"
    done
    
    # Link directories
    for dir in "${DIRECTORIES_TO_LINK[@]}"; do
        link_directory "$dir"
    done
    
    success "Dotfiles linking complete!"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    if [ "$DRY_RUN" = true ]; then
        log "Running in dry-run mode - no changes will be made"
    fi
    
    link_dotfiles
}

main "$@"