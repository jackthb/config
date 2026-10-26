#!/bin/bash
# Run in WSL to install the Pi launcher using the existing SSH authentication.
set -euo pipefail

verify_only=false
[[ "${1:-}" != "--check" ]] || verify_only=true

if [[ "$verify_only" == false && -z "${WSL_DISTRO_NAME:-}" ]] && ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    echo 'Run this setup in WSL / Ubuntu on Windows.' >&2
    exit 1
fi

# Bundle the launcher locally: installation must not start another SSH process.
# Refresh these payloads from herdr/.local/bin and herdr/.config/herdr on changes.
stage="$(mktemp -d -t herdr-pi-setup.XXXXXXXX)"
trap 'rm -rf -- "$stage"' EXIT
mkdir -p "$stage/.local/bin" "$stage/.config/herdr"

cat > "$stage/.local/bin/herdr-pi" <<'HERDR_PI_LAUNCHER'
#!/bin/bash
# Attach to the Pi's persistent Herdr session, restoring the local terminal on exit.
set -u

if [[ "${1:-}" == "--launcher-help" ]]; then
    cat <<'HELP'
herdr-pi [Herdr arguments...]
Connect to the existing Herdr session on the Pi.
HERDR_PI_HOST changes the SSH target (default: jack@pi).
HERDR_PI_SSH selects the SSH executable; WSL defaults to Windows ssh.exe.
After a connection loss, run herdr again to reattach to the same Pi session.
HELP
    exit 0
fi

target="${HERDR_PI_HOST:-jack@pi}"
ssh_transport="${HERDR_PI_SSH:-}"
if [[ -z "$ssh_transport" ]]; then
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v ssh.exe >/dev/null 2>&1; then
        ssh_transport="ssh.exe"
    else
        ssh_transport="ssh"
    fi
fi

if ! command -v "$ssh_transport" >/dev/null 2>&1; then
    echo "SSH executable not found: $ssh_transport" >&2
    exit 127
fi

terminal_fd=""
saved_tty=""
if [[ -t 0 && -t 1 ]]; then
    if { exec {terminal_fd}<>/dev/tty; } 2>/dev/null; then
        saved_tty="$(stty -g <&"$terminal_fd")"
    fi
fi

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ -n "$terminal_fd" ]]; then
        # Leave the alternate screen before disabling mouse modes: some terminals
        # restore saved mouse modes when they leave the alternate screen.
        printf '\033[?1049l\033[?1000l\033[?1002l\033[?1003l\033[?1004l\033[?1005l\033[?1006l\033[?1015l\033[?1016l\033[?2004l\033[?25h\033[0m' >&"$terminal_fd"
        [[ -z "$saved_tty" ]] || stty "$saved_tty" <&"$terminal_fd" 2>/dev/null || true
        exec {terminal_fd}>&-
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Quote each remote argument as one POSIX shell word. Do not send local HOME.
remote_command='exec "$HOME/.local/bin/herdr"'
for argument in "$@"; do
    quoted="${argument//\'/\'\\\'\'}"
    remote_command+=" '$quoted'"
done

"$ssh_transport" -tt \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o TCPKeepAlive=yes \
    -o ConnectTimeout=15 \
    "$target" "$remote_command"
status=$?
if [[ "$status" -eq 255 ]]; then
    echo 'SSH disconnected. Run herdr again to reattach to the same Pi session.' >&2
fi
exit "$status"
HERDR_PI_LAUNCHER

cat > "$stage/.config/herdr/pi-shell.sh" <<'HERDR_PI_SHELL'
# WSL shells use the Pi's persistent session when the user types `herdr`.
if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    unalias herdr 2>/dev/null || true
    function herdr {
        if [ "${1:-}" = "--local" ]; then
            shift
            command herdr "$@"
        else
            "$HOME/.local/bin/herdr-pi" "$@"
        fi
    }
fi
HERDR_PI_SHELL

bash -n "$stage/.local/bin/herdr-pi" "$stage/.config/herdr/pi-shell.sh"
if [[ "$verify_only" == true ]]; then
    echo 'Bundled launcher and shell module pass validation; no SSH or home-directory changes.'
    exit 0
fi

echo 'Installing the Pi launcher locally in WSL...'
mkdir -p "$HOME/.local/bin" "$HOME/.config/herdr"
for relative in .local/bin/herdr-pi .config/herdr/pi-shell.sh; do
    destination="$HOME/$relative"
    if [[ -e "$destination" ]] && ! cmp -s "$destination" "$stage/$relative"; then
        cp -L "$destination" "$destination.before-pi-launcher-$(date +%Y%m%d-%H%M%S)"
    fi
    # Preserve a Stow symlink if this machine already has the package installed.
    cat "$stage/$relative" > "$destination"
done
chmod 755 "$HOME/.local/bin/herdr-pi"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if ! grep -Fq '.config/herdr/pi-shell.sh' "$rc"; then
        cat >> "$rc" <<'SHELL'

# Herdr: reattach to the Pi and clean up terminal mouse modes on disconnect.
if [ -f "$HOME/.config/herdr/pi-shell.sh" ]; then
    . "$HOME/.config/herdr/pi-shell.sh"
fi
SHELL
    fi
done

echo 'Installed. Open a new WSL shell, or run:'
echo 'source ~/.config/herdr/pi-shell.sh'
echo 'Then run herdr to return to the persistent Pi session.'
