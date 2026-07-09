#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
set -e

cd "$(dirname "$0")"
CONFIG_DIR="$(pwd)"
PACKAGES=(zsh starship claude fastfetch ghostty tmux)

# Detect package manager (needed only for stow + oh-my-zsh prereqs)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG_MANAGER="brew"
elif command -v apt &> /dev/null && [[ -f /etc/debian_version ]]; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
else
    PKG_MANAGER="brew"
fi

native_install() {
    case "$PKG_MANAGER" in
        brew)   brew install "$@" ;;
        apt)    sudo apt install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm --needed "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
    esac
}

SYNCED=false
native_sync() {
    [[ "$SYNCED" == true ]] && return
    case "$PKG_MANAGER" in
        apt) sudo apt update ;;
    esac
    SYNCED=true
}

# Ensure stow is available (required to link configs)
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    native_sync
    native_install stow
fi

# Ensure oh-my-zsh is present (the zsh config depends on it)
FRESH_ZSH_INSTALL=false
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    FRESH_ZSH_INSTALL=true
fi

# Set zsh as the login shell on Linux (macOS already defaults to zsh)
if [[ "$OSTYPE" != "darwin"* ]] && command -v zsh &> /dev/null; then
    ZSH_PATH="$(command -v zsh)"
    LOGIN_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ -n "$ZSH_PATH" && "$LOGIN_SHELL" != "$ZSH_PATH" ]]; then
        echo "Setting zsh as default shell (was $LOGIN_SHELL)..."
        if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        sudo chsh -s "$ZSH_PATH" "$USER" || echo "  chsh failed — run manually: sudo chsh -s $ZSH_PATH $USER"
    fi
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

# Set git identity if not already configured
if [[ -z "$(git config --global user.name)" ]]; then
    git config --global user.name "jackthb"
fi
if [[ -z "$(git config --global user.email)" ]]; then
    git config --global user.email "19895932+jackthb@users.noreply.github.com"
fi
if [[ "$(git config --global core.editor)" != "nvim" ]]; then
    git config --global core.editor nvim
fi

# Unfold ~/.local/bin if a previous stow run folded it — the Claude installer
# drops a symlink there and it must be a real directory.
if [[ -L "$HOME/.local/bin" ]]; then
    rm "$HOME/.local/bin"
fi
mkdir -p "$HOME/.local/bin"
rm -f "$CONFIG_DIR/zsh/.local/bin/claude"

# Return 0 if the given path (relative to a package root, with leading `/`)
# matches any regex in that package's .stow-local-ignore.
is_stow_ignored() {
    local pkg="$1" rel="$2"
    local ignore="$pkg/.stow-local-ignore"
    [[ -f "$ignore" ]] || return 1
    local pattern
    while IFS= read -r pattern; do
        [[ -z "$pattern" || "$pattern" == \#* ]] && continue
        [[ "/$rel" =~ $pattern ]] && return 0
    done < "$ignore"
    return 1
}

# Handle conflicts
for pkg in "${PACKAGES[@]}"; do
    if [[ ! -d "$pkg" ]]; then
        continue
    fi

    while IFS= read -r -d '' file; do
        rel_path="${file#$pkg/}"
        target="$HOME/$rel_path"

        is_stow_ignored "$pkg" "$rel_path" && continue
        [[ ! -e "$target" ]] && continue

        # Skip if target already points to our file (direct or via folded parent)
        if [[ "$(readlink -f "$target")" == "$(readlink -f "$file")" ]]; then
            continue
        fi

        # Auto-override default .zshrc created by a fresh oh-my-zsh install
        if [[ "$FRESH_ZSH_INSTALL" == true && "$rel_path" == ".zshrc" ]]; then
            echo "Replacing default oh-my-zsh .zshrc with config..."
            rm -rf "$target"
            continue
        fi

        echo "========================================="
        echo "Conflict: $target already exists"
        echo "========================================="

        if [[ -f "$target" && -f "$file" ]]; then
            echo "Differences (existing -> new):"
            diff --color=auto "$target" "$file" || true
            echo ""
        fi

        if read -n 1 -r -p ">>> Override $target? [y/N] " < /dev/tty 2>/dev/null; then
            echo ""
        else
            echo "Skipping $pkg (no TTY available)..."
            continue 2
        fi

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing $target..."
            rm -rf "$target"
        else
            echo "Skipping $pkg..."
            continue 2
        fi
    done < <(find "$pkg" -type f -print0)
done

# Unfold any target dirs that a previous (folded) stow run turned into symlinks
unfold_target() {
    local target="$1" source_dir="$2"
    [[ -L "$target" ]] || return 0
    [[ "$(readlink -f "$target")" == "$(readlink -f "$source_dir")" ]] || return 0
    echo "Unfolding $target..."
    rm "$target"
    mkdir -p "$target"
}

for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || continue
    while IFS= read -r -d '' src_subdir; do
        rel="${src_subdir#$pkg/}"
        unfold_target "$HOME/$rel" "$src_subdir"
    done < <(find "$pkg" -mindepth 1 -type d -print0)
done

# Stow all configs. --no-folding forces real directories at the target so
# apps can write runtime data there without polluting the repo.
echo "Linking config..."
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        stow -v -R --no-folding -t ~ "$pkg" 2>/dev/null || true
    fi
done

# Seed stow-ignored files (copied once on first run, local edits preserved)
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || continue
    while IFS= read -r -d '' file; do
        rel_path="${file#$pkg/}"
        is_stow_ignored "$pkg" "$rel_path" || continue
        target="$HOME/$rel_path"
        [[ -e "$target" ]] && continue
        echo "Seeding $target..."
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
    done < <(find "$pkg" -type f -print0)
done

echo "Done!"
