# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting python)
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
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"
alias reload="source ~/.zshrc"
alias vact="source .venv/bin/activate"
alias refresh='git fetch origin $(git_main_branch):$(git_main_branch)'
alias dcu="docker compose up"
alias dcd="docker compose down"
alias zshconfig="vi ~/.zshrc"
alias zshlocal="vi ~/.zshrc.local"
alias cdconf="cd ~/code/config"

# Use Windows SSH in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    alias ssh="ssh.exe"
    alias ssh-add="ssh-add.exe"
fi

# Local binaries
export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"

# nvm — lazy-loaded to avoid ~2.5s startup cost.
# nvm/node/npm/npx trigger the real load on first use.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _nvm_load() {
        unset -f nvm node npm npx
        \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    }
    nvm()  { _nvm_load && nvm "$@"; }
    node() { _nvm_load && node "$@"; }
    npm()  { _nvm_load && npm "$@"; }
    npx()  { _nvm_load && npx "$@"; }
fi

# Machine-specific config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# CachyOS-style welcome: fastfetch on top-level interactive shells.
# Logo is picked per-OS; config.jsonc's logo is used only on Linux.
if [[ -o interactive && $SHLVL -eq 1 ]] && command -v fastfetch >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    fastfetch --logo apple_small
  else
    fastfetch
  fi
fi

gcol() { git checkout "$@" }
_gcol() {
  local -a branches
  branches=(${(f)"$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ 2>/dev/null)"})
  compadd -a branches
}
compdef _gcol gcol

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi


# bun completions
[ -s "/home/jack/.bun/_bun" ] && source "/home/jack/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# tmux: bare `tmux` attaches to most-recent session, or creates `main` if none exist
tmux() {
  if [[ $# -eq 0 ]]; then
    command tmux attach 2>/dev/null || command tmux new -s main
  else
    command tmux "$@"
  fi
}
