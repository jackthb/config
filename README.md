# Config

Development config managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone git@github.com:jackthb/config.git ~/code/config
cd ~/code/config
./sync.sh
```

## Post-install

`sync.sh` creates an empty `~/.zshrc.local` on first run for machine-specific config (AWS, pyenv, nvm, work aliases, etc) — it's sourced by `.zshrc` but never tracked in this repo, so edit it freely.

## Windows Terminal (WSL hosts)

Run `windows-terminal/setup.ps1` from PowerShell to link the real settings.json to this repo (pass `-Distro`/`-RepoPath` if they differ from the defaults).

**Important:** after changing `windows-terminal/settings.json`, fully quit Windows Terminal (all windows + tray icon) and reopen it — it doesn't hot-reload a symlinked settings file.

## Herdr session restore

Run `herdr` to reconnect to the default session. Close the terminal window or
press Ctrl+B, then Q to detach; exiting a pane's shell closes that pane and saves
the updated layout.

After a WSL or PC restart, Herdr restores the saved layout and directories.
This config also enables recent terminal history replay (stored locally in
`~/.config/herdr/session-history.json`, including any sensitive terminal output).
`sync.sh` installs the official Codex and Claude hooks when those agents and
their config directories exist, allowing their conversations to resume.
Already-running agents need a new start/resume to load newly installed hooks.
Check installation with `herdr integration status`.

WSL shutdown still ends running processes. Restored terminal output is a saved
screen; ordinary commands and development servers need to be started again.

## Shell performance notes

The zsh config is intentionally kept small: it avoids oh-my-zsh/plugin-manager startup work, sources only the two installed plugins directly, caches `compinit`, and lazy-loads heavier tools such as `nvm`.

Useful checks when tuning startup:

```bash
time zsh -i -c exit
hyperfine --warmup 3 'zsh -i -c exit'
```

For one-off profiling, add `zmodload zsh/zprof` to the top of `~/.zshrc` and `zprof` to the bottom, open a new shell, then remove both lines after reviewing the report.
