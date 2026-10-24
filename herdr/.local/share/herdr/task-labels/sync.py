"""Copy live task/directory details into sidebar metadata, leaving names intact."""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


SOURCE = "plugin:local.task-labels"
HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"


def call(*args):
    result = subprocess.run(
        [HERDR, *args], check=True, capture_output=True, text=True, timeout=10
    )
    # report-metadata succeeds silently; read commands return JSON.
    return json.loads(result.stdout)["result"] if result.stdout.strip() else None


def directory(pane):
    return pane.get("foreground_cwd") or pane.get("cwd") or ""


def task(pane):
    # Herdr strips the activity spinner; remove the trailing folder when present.
    title = pane.get("terminal_title_stripped") or ""
    folder = Path(directory(pane)).name
    suffix = " | " + folder
    if folder and title.endswith(suffix):
        title = title[:-len(suffix)]
    if title.lower() in {"codex", "claude", "zsh", "bash", "fish"}:
        return ""
    return title


def report(kind, resource, resource_id, desired):
    current = resource.get("tokens") or {}
    args = []
    for key, value in desired.items():
        if value and current.get(key) != value:
            args += ["--token", key + "=" + value]
        elif not value and key in current:
            args += ["--clear-token", key]
    if args:
        call(kind, "report-metadata", resource_id, "--source", SOURCE, *args)


def main():
    if os.environ.get("HERDR_ENV") != "1":
        return
    socket_path = os.environ.get("HERDR_SOCKET_PATH", "default")
    lock_key = hashlib.sha256(socket_path.encode()).hexdigest()[:16]
    lock_path = Path(tempfile.gettempdir()) / ("herdr-task-labels-" + str(os.getuid()) + "-" + lock_key + ".lock")
    with lock_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        snapshot = call("api", "snapshot")["snapshot"]
        panes = snapshot["panes"]
        for pane in panes:
            report("pane", pane, pane["pane_id"], {"directory": directory(pane)})
        for workspace in snapshot["workspaces"]:
            members = [p for p in panes if p["workspace_id"] == workspace["workspace_id"]]
            active = [p for p in members if p["tab_id"] == workspace.get("active_tab_id")]
            candidates = sorted(active or members, key=lambda p: not p.get("focused", False))
            selected = candidates[0] if candidates else {}
            report("workspace", workspace, workspace["workspace_id"], {
                "task": task(selected) or workspace.get("label") or Path(directory(selected)).name,
                "directory": directory(selected),
            })


if __name__ == "__main__":
    main()
