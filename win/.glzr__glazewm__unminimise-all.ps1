# Restore every GlazeWM-managed window back to tiling state.
# Bound to alt+shift+m via config.yaml. Iterates through all known windows
# and runs `set-tiling` on each one whose current state is not already
# tiling, which un-minimizes minimized windows, exits floating/fullscreen,
# and re-inserts them into their workspace's tiling layout. Finally,
# reloads the GlazeWM config (same as alt+shift+r) to re-apply window
# rules so windows are auto-allocated back to their default workspaces.

$ErrorActionPreference = 'SilentlyContinue'

$glazewm = Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe'
if (-not (Test-Path $glazewm)) {
    $glazewm = 'glazewm'
}

$raw = & $glazewm query windows 2>$null | Out-String
if ([string]::IsNullOrWhiteSpace($raw)) { return }

$resp = $raw | ConvertFrom-Json
if (-not $resp.success) { return }

foreach ($w in $resp.data.windows) {
    if ($w.state.type -ne 'tiling') {
        & $glazewm command --id $w.id set-tiling | Out-Null
    }
}

# Reload config to re-apply window_rules, which auto-allocates windows
# back to their default workspaces (same effect as pressing alt+shift+r).
& $glazewm command wm-reload-config | Out-Null
