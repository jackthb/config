# Keep shell startup intentional and small: no framework, just the pieces used daily.

# Homebrew paths without forking `brew shellenv` on every new shell.
if [[ -d "/opt/homebrew" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    path=("/opt/homebrew/bin" "/opt/homebrew/sbin" $path)
elif [[ -d "/usr/local/Homebrew" || -x "/usr/local/bin/brew" ]]; then
    export HOMEBREW_PREFIX="/usr/local"
    export HOMEBREW_CELLAR="/usr/local/Cellar"
    export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
    path=("/usr/local/bin" "/usr/local/sbin" $path)
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
    export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
    path=("/home/linuxbrew/.linuxbrew/bin" "/home/linuxbrew/.linuxbrew/sbin" $path)
fi

# Local binaries
export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$PATH"

# Zsh basics formerly covered by oh-my-zsh defaults/plugins.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups hist_ignore_space hist_reduce_blanks
setopt auto_cd auto_pushd pushd_ignore_dups interactive_comments extended_glob
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Completion cache: run the expensive audit at most once per day.
autoload -Uz compinit
if [[ -n "$HOME/.zcompdump"(#qNmh-24) ]]; then
    compinit -C
else
    compinit
fi

# Key bindings.
# Ctrl+Arrow word navigation, bound to the literal escape sequences so it works
# under any $TERM (terminfo-based bindings silently break in some terminals).
bindkey '^[[1;5C' forward-word     # Ctrl+Right
bindkey '^[[1;5D' backward-word    # Ctrl+Left

# Lightweight plugins cloned by install.sh; source files directly to avoid a plugin manager/framework.
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
[[ -r "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Oh-my-zsh git aliases without loading the full framework.
OMZ_GIT="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -r "$OMZ_GIT/plugins/git/git.plugin.zsh" ]]; then
    [[ -r "$OMZ_GIT/lib/git.zsh" ]] && source "$OMZ_GIT/lib/git.zsh"
    source "$OMZ_GIT/plugins/git/git.plugin.zsh"
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
alias zshconfig="nvim ~/.zshrc"
alias zshlocal="nvim ~/.zshrc.local"
alias cdconf="cd ~/code/config"

# Use Windows SSH in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    alias ssh="ssh.exe"
    alias ssh-add="ssh-add.exe"
fi

# Starship prompt
eval "$(starship init zsh)"

# nvm — lazy-loaded to avoid multi-second startup cost.
# nvm/node/npm/npx trigger the real load on first use.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _nvm_load() {
        unset -f nvm node npm npx
        \. "$NVM_DIR/nvm.sh" --no-use
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

# Windows Terminal shell integration is useful only when `wt` exists; keep it after the fast path.
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
