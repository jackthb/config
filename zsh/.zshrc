# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Homebrew
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    # macOS Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    # macOS Intel
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    # Linux/WSL
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Quick config editing
alias ohmyzsh="vi ~/.oh-my-zsh"
alias zsh="vi ~/.zshrc"

# Use Windows SSH in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    alias ssh="ssh.exe"
    alias ssh-add="ssh-add.exe"
fi

# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"
