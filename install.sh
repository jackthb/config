#!/bin/bash
set -e

cd "$(dirname "$0")"
CONFIG_DIR="$(pwd)"
PACKAGES=(zsh starship)
FORCE=false

if [[ "$1" == "--force" ]]; then
    FORCE=true
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# Install stow if not present
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    brew install stow
fi

# Handle conflicts if --force flag is set
if [[ "$FORCE" == true ]]; then
    for pkg in "${PACKAGES[@]}"; do
        if [[ ! -d "$pkg" ]]; then
            continue
        fi

        while IFS= read -r -d '' file; do
            rel_path="${file#$pkg/}"
            target="$HOME/$rel_path"

            # Skip if target doesn't exist
            [[ ! -e "$target" ]] && continue

            # Skip if already a symlink to our file
            if [[ -L "$target" ]]; then
                link_target="$(readlink -f "$target")"
                our_file="$(readlink -f "$file")"
                [[ "$link_target" == "$our_file" ]] && continue
            fi

            echo "========================================="
            echo "Conflict: $target already exists"
            echo "========================================="

            if [[ -f "$target" && -f "$file" ]]; then
                echo "Differences (existing -> new):"
                diff --color=auto "$target" "$file" || true
                echo ""
            fi

            read -p "Override $target? [y/N] " -n 1 -r
            echo ""

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Removing $target..."
                rm -rf "$target"
            else
                echo "Skipping $pkg..."
                continue 2
            fi
        done < <(find "$pkg" -type f -print0)
    done
fi

# Stow all configs
echo "Linking config..."
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        stow -v "$pkg"
    fi
done

echo "Done!"
