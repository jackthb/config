#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
set -e

cd "$(dirname "$0")"
CONFIG_DIR="$(pwd)"
PACKAGES=(zsh starship)

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG_MANAGER="brew"
elif [[ -f /etc/debian_version ]]; then
    PKG_MANAGER="apt"
else
    PKG_MANAGER="brew"
fi

# Install package manager and packages based on OS
if [[ "$PKG_MANAGER" == "brew" ]]; then
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

    # Install starship if not present
    if ! command -v starship &> /dev/null; then
        echo "Installing starship..."
        brew install starship
    fi
elif [[ "$PKG_MANAGER" == "apt" ]]; then
    # Install stow if not present
    if ! command -v stow &> /dev/null; then
        echo "Installing stow..."
        sudo apt update && sudo apt install -y stow
    fi

    # Install starship if not present
    if ! command -v starship &> /dev/null; then
        echo "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
fi

# Install oh-my-zsh if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Handle conflicts
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

        echo -n ">>> Override $target? [y/N] "
        read -n 1 -r < /dev/tty
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

# Stow all configs
echo "Linking config..."
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        stow -v -t ~ "$pkg"
    fi
done

echo "Done!"
