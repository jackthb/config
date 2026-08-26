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

## Shell performance notes

The zsh config is intentionally kept small: it avoids oh-my-zsh/plugin-manager startup work, sources only the two installed plugins directly, caches `compinit`, and lazy-loads heavier tools such as `nvm`.

Useful checks when tuning startup:

```bash
time zsh -i -c exit
hyperfine --warmup 3 'zsh -i -c exit'
```

For one-off profiling, add `zmodload zsh/zprof` to the top of `~/.zshrc` and `zprof` to the bottom, open a new shell, then remove both lines after reviewing the report.
