<#
.SYNOPSIS
Points the real Windows Terminal settings.json at this repo's windows-terminal/settings.json,
via a \\wsl.localhost\ symlink.

.DESCRIPTION
Windows Terminal is a native Win32 app and reads settings.json from the Windows side
(AppData\Local\Packages\...\LocalState\settings.json), so stow's WSL-side symlinking can't
reach it. This script does the equivalent by hand: back up the existing settings.json, then
replace it with a symlink into the WSL checkout via \\wsl.localhost\, so Windows Terminal
writes settings-UI changes straight back into this repo.

Run from PowerShell — as admin, or with Developer Mode enabled for non-admin symlinks.

.PARAMETER Distro
WSL distro name (as shown by `wsl -l`). Defaults to your default WSL distro.

.PARAMETER RepoPath
Absolute path to this repo inside WSL. Defaults to /root/code/config.

.EXAMPLE
.\setup.ps1
.\setup.ps1 -Distro archlinux -RepoPath /home/jack/code/config
#>
param(
    [string]$Distro,
    [string]$RepoPath = "/root/code/config"
)

$ErrorActionPreference = "Stop"

if (-not $Distro) {
    $Distro = (wsl -l -q | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1) -replace "`0", ""
    $Distro = $Distro.Trim()
    Write-Host "No -Distro given, using default WSL distro: $Distro"
}

$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$target = "\\wsl.localhost\$Distro$RepoPath\windows-terminal\settings.json"

if (-not (Test-Path -LiteralPath $target)) {
    Write-Error "Target not found: $target`nCheck -Distro/-RepoPath, and that WSL is running (wsl -l -v)."
}

$existing = Get-Item -LiteralPath $wt -ErrorAction SilentlyContinue
if ($existing -and $existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $target) {
    Write-Host "Already linked to $target"
    exit 0
}

if (Test-Path -LiteralPath $wt) {
    if (-not (Test-Path -LiteralPath "$wt.bak")) {
        Copy-Item -LiteralPath $wt -Destination "$wt.bak"
        Write-Host "Backed up existing settings.json to $wt.bak"
    } else {
        Write-Host "Backup already exists at $wt.bak, leaving it alone"
    }
    Remove-Item -LiteralPath $wt
}

New-Item -ItemType SymbolicLink -Path $wt -Target $target | Out-Null
Write-Host "Linked $wt -> $target"
Write-Host ""
Write-Host "Windows Terminal does not hot-reload a symlinked settings.json (WT #5625, #6209)."
Write-Host "Fully quit Windows Terminal (all windows, including the tray icon) and reopen it."
