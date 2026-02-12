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

# Aliases
alias ..="cd .."
alias reload="source ~/.zshrc"
alias vact="source .venv/bin/activate"
alias refresh='git fetch origin $(git_main_branch):$(git_main_branch)'
alias dcu="docker compose up"
alias dcd="docker compose down"

# Use Windows SSH in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    alias ssh="ssh.exe"
    alias ssh-add="ssh-add.exe"
fi

# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"

# nvm (requires ~/.local/bin/hash wrapper for zsh compatibility)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Machine-specific config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# pnpm
export PNPM_HOME="/Users/jack.burgess/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
