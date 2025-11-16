#!/usr/bin/env bash
set -Eeuo pipefail

# Dotfiles linking script
# Links dotfiles from this repository to their target locations

# Parse command line arguments
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be linked without making changes"
            echo "  --verbose    Show detailed output"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Dotfile linking configuration
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

    # Claude Code configuration
    ".claude/settings.json"
)

# Directories to link recursively
DIRECTORIES_TO_LINK=(
    "config/nvim"
    "config/alacritty"
    "config/scripts"
    ".claude/commands"
)

log_info() {
    echo "→ $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "  $1"
    fi
}

log_dry_run() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] $1"
    fi
}

get_target_path() {
    local relative_path="$1"

    # Handle special cases
    case "$relative_path" in
        .claude/*)
            # Claude config goes to ~/.claude/
            echo "$TARGET_DIR/${relative_path}"
            ;;
        config/nvim/*)
            # Neovim config goes to ~/.config/nvim/
            echo "$TARGET_DIR/.${relative_path}"
            ;;
        config/scripts/*)
            # Scripts go to ~/.config/scripts/
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
        if [ "$DRY_RUN" = true ]; then
            log_dry_run "Would create directory: $target_dir"
        else
            mkdir -p "$target_dir"
            log_verbose "Created directory: $target_dir"
        fi
    fi

    # Handle existing files/symlinks
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_link="$(readlink "$target")"
            if [ "$current_link" = "$source" ]; then
                log_verbose "Already linked: $target -> $source"
                return 0  # Already linked correctly
            else
                if [ "$DRY_RUN" = true ]; then
                    log_dry_run "Would remove old symlink: $target -> $current_link"
                else
                    rm "$target"
                    log_verbose "Removed old symlink: $target"
                fi
            fi
        else
            if [ "$DRY_RUN" = true ]; then
                log_dry_run "Would backup existing file: $target -> $target.backup"
            else
                mv "$target" "$target.backup"
                log_verbose "Backed up existing file: $target -> $target.backup"
            fi
        fi
    fi

    # Create the symlink
    if [ "$DRY_RUN" = true ]; then
        log_dry_run "Would create symlink: $target -> $source"
    else
        ln -s "$source" "$target"
        log_info "Linked: $relative_path -> $target"
    fi
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

    log_verbose "Linking directory: $relative_path"

    # Find all files in the directory
    while IFS= read -r -d '' file; do
        local file_relative="${file#$DOTFILES_DIR/}"
        local target="$(get_target_path "$file_relative")"
        create_symlink "$file" "$target" "$file_relative"
    done < <(find "$source_dir" -type f -print0)
}

# Main execution
if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
    echo ""
fi

if [ "$VERBOSE" = true ] || [ "$DRY_RUN" = true ]; then
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo "Target directory: $TARGET_DIR"
    echo ""
fi

log_info "Linking dotfiles..."
echo ""

# Link individual files
for file in "${DOTFILES_TO_LINK[@]}"; do
    link_file "$file"
done

# Link directories
for dir in "${DIRECTORIES_TO_LINK[@]}"; do
    link_directory "$dir"
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "✓ Dry run complete - no changes were made"
else
    log_info "✓ Dotfiles linked successfully"
fi
