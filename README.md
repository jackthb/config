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

Run `codex-update` to update Codex CLI. Installation and updates use Volta when
available, otherwise npm. With Volta, Codex's built-in npm update command can
update a separate Node global copy while leaving the active Volta copy outdated;
use `codex-update` instead.

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

## Herdr labels

The `herdr` Stow package shows conversation titles and working directories
under Spaces, with compact single-line status entries under Agents.
Space task labels follow the active pane.
Directories under your home folder use `~`, for example `~/code/config`.
The title comes from the agent's terminal title, so a conversation reused for
unrelated tasks may retain its original title.

`install.sh`, `sync.sh`, and `config-sync` link the local Python helper at
`~/.local/share/herdr/task-labels`, register it with Herdr, and refresh a running
session. The helper uses Python 3's standard library and refreshes metadata on
startup, focus, pane lifecycle, workspace updates, and agent status changes.

To refresh labels manually:

```bash
herdr plugin action invoke local.task-labels.refresh
```

### WSL and the Pi session

On WSL, the optional `pi-shell.sh` module makes `herdr` attach directly to the
Pi's persistent default session. Panes and agents run on the Pi and survive a
lost SSH connection or a closed Windows Terminal window. `herdr --local` runs
the WSL binary when a local session is wanted.

The launcher uses Windows `ssh.exe` when available in WSL so existing Windows
SSH keys and SSH-agent access continue to work; otherwise it uses Linux `ssh`.
It sends keepalives every 30 seconds and restores local terminal modes on exit,
including after a broken connection. Typing `herdr` again reattaches to the same
Pi session. It does not automatically retry authentication or connection errors.

To install it from the Pi into the local WSL/Ubuntu shell:

```bash
ssh.exe -o BatchMode=yes -o ConnectTimeout=10 jack@pi 'cat /home/jack/config/scripts/setup-wsl-herdr.sh' > /tmp/setup-wsl-herdr.sh &&
bash /tmp/setup-wsl-herdr.sh &&
source ~/.config/herdr/pi-shell.sh &&
herdr
```

The default target uses your existing `pi` SSH alias or hostname. Set `HERDR_PI_HOST` to use
another SSH target, or `HERDR_PI_SSH` to select the SSH executable. The installer
adds the module to existing Bash and Zsh startup files and backs up different
launcher files before replacing them.
The installer bundles both files, so it makes no further SSH connections.
The download uses batch authentication to fail visibly rather than wait for an
unseen prompt. If it reports an authentication error, connect once interactively
with `ssh.exe jack@pi` to check keys or unlock the SSH agent.

The Pi's SSH server keepalive drop-in is recorded in
`ssh-server/20-session-keepalive.conf`; it belongs in
`/etc/ssh/sshd_config.d/`, not in a Stow package. Validate changes with
`sudo sshd -t` before applying them with `sudo systemctl reload ssh`.

## Shell performance notes

The zsh config is intentionally kept small: it avoids oh-my-zsh/plugin-manager startup work, sources only the two installed plugins directly, caches `compinit`, and lazy-loads heavier tools such as `nvm`.

Useful checks when tuning startup:

```bash
time zsh -i -c exit
hyperfine --warmup 3 'zsh -i -c exit'
```

For one-off profiling, add `zmodload zsh/zprof` to the top of `~/.zshrc` and `zprof` to the bottom, open a new shell, then remove both lines after reviewing the report.
