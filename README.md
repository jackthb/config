# Config

Development config managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone git@github.com:jackthb/config.git ~/code/config
cd ~/code/config
./sync.sh
```

## Post-install

Create `~/.zshrc.local` for machine-specific config (AWS, pyenv, nvm, work aliases, etc).

## Windows Terminal (WSL hosts)

`windows-terminal/settings.json` tracks the real Windows Terminal config, but it lives outside `sync.sh`'s stow flow — stow only symlinks into the WSL home (`~`), while Windows Terminal reads `settings.json` from the Windows side (`AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` for the Store install), which is a native Win32 app and can't resolve a symlink pointing back into the WSL filesystem via a plain Linux path.

Instead of a second checkout, point the real settings.json at this same repo through the `\\wsl.localhost\` UNC path. Run this from PowerShell (as admin, or with Developer Mode enabled for non-admin symlinks) — replace `archlinux` with your distro name (`wsl -l` to check) and the path with wherever this repo is actually cloned:

```powershell
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-Item $wt "$wt.bak"
Remove-Item $wt
New-Item -ItemType SymbolicLink -Path $wt -Target "\\wsl.localhost\archlinux\root\code\config\windows-terminal\settings.json"
```

One file, one repo — Windows Terminal writes settings-UI changes straight into the WSL checkout, so `git status`/`git diff`/`git commit` from inside WSL pick them up like any other edit. First access after WSL has been shut down may take a moment while the VM spins back up to serve the UNC share.

## Shell performance notes

The zsh config is intentionally kept small: it avoids oh-my-zsh/plugin-manager startup work, sources only the two installed plugins directly, caches `compinit`, and lazy-loads heavier tools such as `nvm`.

Useful checks when tuning startup:

```bash
time zsh -i -c exit
hyperfine --warmup 3 'zsh -i -c exit'
```

For one-off profiling, add `zmodload zsh/zprof` to the top of `~/.zshrc` and `zprof` to the bottom, open a new shell, then remove both lines after reviewing the report.
