#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi
set -e

cd "$(dirname "$0")"
CONFIG_DIR="$(pwd)"
PACKAGES=(zsh starship claude)

# Detect package manager
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

echo "Using package manager: $PKG_MANAGER"

native_install() {
    case "$PKG_MANAGER" in
        brew)   brew install "$@" ;;
        apt)    sudo apt install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm --needed "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
    esac
}

native_sync() {
    case "$PKG_MANAGER" in
        apt) sudo apt update ;;
    esac
}

# Install Homebrew on macOS (or as Linux fallback)
if [[ "$PKG_MANAGER" == "brew" ]]; then
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
fi

# Collect and install missing base packages (cmd:pkg — all distros share these names)
MAPPINGS=("zsh:zsh" "stow:stow" "nvim:neovim" "tmux:tmux")
PKGS_TO_INSTALL=()
for entry in "${MAPPINGS[@]}"; do
    cmd="${entry%%:*}"
    pkg="${entry##*:}"
    command -v "$cmd" &> /dev/null || PKGS_TO_INSTALL+=("$pkg")
done

if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
    echo "Installing ${PKGS_TO_INSTALL[*]}..."
    native_sync
    native_install "${PKGS_TO_INSTALL[@]}"
fi

# GitHub CLI (package name differs on pacman)
if ! command -v gh &> /dev/null; then
    echo "Installing gh..."
    case "$PKG_MANAGER" in
        pacman) native_install github-cli ;;
        *)      native_install gh ;;
    esac
fi

# Starship: packaged on brew/pacman, upstream installer elsewhere
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    case "$PKG_MANAGER" in
        brew|pacman) native_install starship ;;
        *)           curl -sS https://starship.rs/install.sh | sh -s -- -y ;;
    esac
fi

# Claude Code: official native installer drops a symlink into ~/.local/bin.
# Unfold ~/.local/bin if a previous stow run folded the whole directory into
# the source — otherwise the installer's symlink ends up inside this repo.
if [[ -L "$HOME/.local/bin" ]]; then
    rm "$HOME/.local/bin"
fi
mkdir -p "$HOME/.local/bin"
rm -f "$CONFIG_DIR/zsh/.local/bin/claude"
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# GUI apps: 1Password + Ghostty (pacman and brew fully wired; other distros stubbed)
case "$PKG_MANAGER" in
    brew)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            for cask in 1password ghostty; do
                if ! brew list --cask "$cask" &> /dev/null; then
                    echo "Installing $cask..."
                    brew install --cask "$cask"
                fi
            done
        else
            echo "Skipping 1Password/Ghostty: linuxbrew doesn't support casks."
        fi
        ;;
    pacman)
        # Ghostty is in the extra repo
        if ! command -v ghostty &> /dev/null; then
            echo "Installing ghostty..."
            native_install ghostty
        fi
        # 1Password lives in the AUR — needs paru or yay (paru ships with CachyOS)
        if ! pacman -Qi 1password &> /dev/null; then
            if command -v paru &> /dev/null; then
                echo "Installing 1Password (AUR via paru)..."
                paru -S --noconfirm --needed 1password
            elif command -v yay &> /dev/null; then
                echo "Installing 1Password (AUR via yay)..."
                yay -S --noconfirm --needed 1password
            else
                echo "Skipping 1Password: install paru or yay first, then: paru -S 1password"
            fi
        fi
        ;;
    *)
        # TODO: add repos for apt/dnf/zypper — see:
        #   1Password: https://support.1password.com/install-linux/
        #   Ghostty:   https://ghostty.org/download
        echo "Skipping 1Password/Ghostty: not wired up for $PKG_MANAGER yet."
        ;;
esac

# 1Password: allow Zen Browser to talk to the desktop app via the custom
# allowed-browsers list. Both apps must be installed natively (not flatpak/snap)
# and the file must be root-owned for 1Password's Native Core to verify it.
# https://support.1password.com/connect-browser/
if [[ "$OSTYPE" != "darwin"* ]] && command -v 1password &> /dev/null; then
    OP_BROWSERS=/etc/1password/custom_allowed_browsers
    if [[ ! -f "$OP_BROWSERS" ]] || ! grep -qx zen-bin "$OP_BROWSERS" 2>/dev/null; then
        echo "Allowing Zen Browser in 1Password..."
        {
            sudo mkdir -p /etc/1password \
                && sudo touch "$OP_BROWSERS" \
                && { grep -qx zen-bin "$OP_BROWSERS" 2>/dev/null \
                    || echo zen-bin | sudo tee -a "$OP_BROWSERS" > /dev/null; } \
                && sudo chown root:root "$OP_BROWSERS" \
                && sudo chmod 755 "$OP_BROWSERS"
        } || echo "  1Password/Zen config failed — re-run install.sh from a real terminal"
    fi
fi

# Install oh-my-zsh if not present
FRESH_ZSH_INSTALL=false
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    FRESH_ZSH_INSTALL=true
fi

# Set zsh as the login shell on Linux (macOS already defaults to zsh).
# Read the real login shell from passwd — $SHELL inherits from the parent
# process and can lie about what's actually configured for the user.
if [[ "$OSTYPE" != "darwin"* ]]; then
    ZSH_PATH="$(command -v zsh)"
    LOGIN_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ -n "$ZSH_PATH" && "$LOGIN_SHELL" != "$ZSH_PATH" ]]; then
        echo "Setting zsh as default shell (was $LOGIN_SHELL)..."
        if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        # Use sudo chsh — the sudo prompt is cacheable; the chsh PAM prompt
        # asking for the user's password isn't, and fails in non-TTY runs.
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

        # Skip if target already resolves to our file. readlink -f follows
        # symlinks in any path component, so this catches both direct symlinks
        # AND folded parent dirs (e.g. ~/.claude → source/claude/.claude/) —
        # without this, "rm -rf $target" on a folded path would delete the
        # tracked file from the source repo.
        if [[ "$(readlink -f "$target")" == "$(readlink -f "$file")" ]]; then
            continue
        fi

        # Auto-override default .zshrc if we just installed oh-my-zsh
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

# Unfold any target dirs that a previous (folded) stow run turned into
# symlinks pointing back into the source. We replace the symlink with a real
# directory so apps can write runtime data there without polluting the repo.
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

# Stow all configs. --no-folding forces stow to create real directories at
# the target and only symlink individual files — without it, stow folds whole
# directories (e.g. makes ~/.claude a symlink to source/claude/.claude/),
# which means anything the app writes there lands inside this repo.
echo "Linking config..."
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        stow -v -R --no-folding -t ~ "$pkg" 2>/dev/null || true
    fi
done

echo "Done!"
