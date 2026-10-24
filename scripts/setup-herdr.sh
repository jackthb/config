#!/bin/bash
# Register the Stow-managed label helper and refresh a running Herdr session.
set -e

if ! command -v herdr >/dev/null 2>&1; then
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Herdr task labels need Python 3; run install.sh to install it."
    exit 0
fi

plugin_dir="$HOME/.local/share/herdr/task-labels"
[[ -f "$plugin_dir/herdr-plugin.toml" ]] || exit 0

herdr plugin link "$plugin_dir" >/dev/null

socket_path="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"
if [[ -S "$socket_path" ]]; then
    herdr server reload-config >/dev/null
    herdr plugin action invoke local.task-labels.refresh >/dev/null
fi
