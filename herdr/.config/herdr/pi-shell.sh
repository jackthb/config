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
