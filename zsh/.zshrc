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
alias reload="source ~/.zshrc"
alias vact="source .venv/bin/activate"
alias refresh='git fetch origin $(git_main_branch):$(git_main_branch)'
alias dcu="docker compose up"
alias dcd="docker compose down"
alias zshconfig="vi ~/.zshrc"
alias zshlocal="vi ~/.zshrc.local"
alias cdconfig="cd ~/code/config"

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

_config_notify() {
  if [[ -f /tmp/.config_status ]]; then
    cat /tmp/.config_status
    rm -f /tmp/.config_status
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _config_notify

(
  config_dir="${CONFIG_DIR:-$HOME/code/config}"
  cd "$config_dir"
  green='\033[0;32m'; yellow='\033[0;33m'; reset='\033[0m'
  git fetch -q 2>/dev/null
  lines=()
  if [[ $(git rev-list HEAD..@{u} --count 2>/dev/null) -gt 0 ]]; then
    git pull --ff-only -q && for pkg in zsh starship claude; do [[ -d "$pkg" ]] && stow -R -t ~ "$pkg" 2>/dev/null; done && lines+=("${green}config: synced${reset}")
  fi
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    lines+=("${yellow}config: uncommitted changes${reset}")
  elif [[ $(git rev-list @{u}..HEAD --count 2>/dev/null) -gt 0 ]]; then
    lines+=("${yellow}config: unpushed changes${reset}")
  fi
  # Re-run install if install.sh has changed
  install_hash=$(md5sum "$config_dir/install.sh" 2>/dev/null | cut -d' ' -f1)
  last_hash=""
  [[ -f "$HOME/.config_install_hash" ]] && last_hash=$(cat "$HOME/.config_install_hash")
  if [[ "$install_hash" != "$last_hash" ]]; then
    bash "$config_dir/install.sh" &>/dev/null && echo "$install_hash" > "$HOME/.config_install_hash" && lines+=("${green}config: ran install${reset}")
  fi
  if [[ ${#lines[@]} -eq 0 ]]; then
    lines+=("${green}config: ok${reset}")
  fi
  printf '%b\n' "${lines[@]}" > /tmp/.config_status
) &!
