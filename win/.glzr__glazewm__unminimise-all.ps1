# Reset GlazeWM-managed windows to a known state.
# Bound to alt+shift+m via config.yaml.
#
# Phase 1: Win32 EnumWindows pass over every top-level window. Restore
#   windows that are either MINIMISED (IsIconic) or SHELL-CLOAKED
#   (DWMWA_CLOAKED == DWM_CLOAKED_SHELL / 2). Modern apps like new
#   Outlook ("olk"), new Teams ("ms-teams") and Edge close-to-tray to
#   a suspended-cloaked state rather than minimising, so an iconic-only
#   check misses them. GlazeWM-managed windows are skipped: GlazeWM
#   shell-cloaks its own hidden-workspace windows, and un-cloaking those
#   from underneath it would flash them onto the wrong workspace.
#   Calling ShowWindowAsync(SW_RESTORE) on a non-managed cloaked window
#   wakes it, then GlazeWM's window-created event fires and window_rules
#   route it to its configured workspace.
#
# Phase 2: GlazeWM pass - set-tiling on every non-tiling window EXCEPT
#   those on cascade workspaces (see $WorkspaceLayouts below), then
#   wm-reload-config to re-apply window_rules so each window lands on
#   its configured workspace (same effect as pressing alt+shift+r).
#
# Phase 2.5: After the GlazeWM-pass + wm-reload-config has re-routed every
#   process with an explicit move rule to its configured workspace, sweep
#   any remaining "unspecified" windows (processes with no move/float/ignore
#   rule of their own) to workspace 9. This only happens on script run, NOT
#   on every window-created event - so freshly-opened unknown apps still
#   appear on the active workspace and you can re-park them with alt+shift+m
#   when convenient. Keep $UnspecifiedSkipProcessRegex in sync with config.yaml.
#
# Phase 3: Cascade-float every window on workspaces listed in
#   $WorkspaceLayouts. Windows are placed at hardcoded coordinates,
#   each offset down-right of the previous so all title bars stay
#   visible. Edit the literals in $WorkspaceLayouts to tweak placement.

$ErrorActionPreference = 'SilentlyContinue'

# Per-workspace cascade layout. Workspaces listed here are also skipped
# by the Phase 2 set-tiling pass. To stop cascading a workspace, remove
# its key.
#
# Coordinates are RELATIVE to the top-left of whichever monitor the
# workspace currently lives on (resolved at Phase 3 time from
# `query monitors` + workspace.parentId). This way the same script works
# on the laptop (single 1920x1200 monitor) and the desk (3440x1440 ultra-
# wide + others) without re-tuning for absolute desktop pixels.
$WorkspaceLayouts = @{
    '6' = @{ MarginX = 80; MarginY = 80; Width = 1500; Height = 800; OffsetX = 40; OffsetY = 40 }
    '9' = @{ MarginX = 80; MarginY = 80; Width = 1500; Height = 800; OffsetX = 40; OffsetY = 40 }
}

# Processes that have their OWN handling in config.yaml (an explicit
# move/float/ignore rule). Phase 2.5 sweeps every OTHER managed window to
# workspace 9. Keep this list in sync with the rules in config.yaml.
$UnspecifiedSkipProcessRegex = '^(ms-teams|msteams|Teams|OUTLOOK|olk|wezterm-gui|wezterm|WindowsApp|msrdcw|msrdc|mstsc|devenv|msedge|Code|ShareX|zebar|PowerToys|Lively|EXCEL|WINWORD|POWERPNT)$'

$glazewm = Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe'
if (-not (Test-Path $glazewm)) {
    $glazewm = 'glazewm'
}

# ---- Phase 1: OS-level restore of minimised / shell-cloaked windows ----
if (-not ([System.Management.Automation.PSTypeName]'Win32Restore').Type) {
    Add-Type -Namespace '' -Name 'Win32Restore' -MemberDefinition @'
        public delegate bool EnumWindowsProc(System.IntPtr hWnd, System.IntPtr lParam);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, System.IntPtr lParam);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool IsIconic(System.IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool IsWindowVisible(System.IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(System.IntPtr hWnd, int nCmdShow);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern void SwitchToThisWindow(System.IntPtr hWnd, bool fAltTab);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern int GetWindowTextLength(System.IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("dwmapi.dll")]
        public static extern int DwmGetWindowAttribute(System.IntPtr hWnd, int dwAttribute, out int pvAttribute, int cbAttribute);
'@
}

# Collect HWNDs that GlazeWM currently owns - we must NOT un-cloak these,
# because GlazeWM shell-cloaks its own non-displayed-workspace windows
# (config: hide_method: 'cloak') and un-cloaking would flash them onto the
# active workspace.
$managedHandles = New-Object System.Collections.Generic.HashSet[long]
$winRaw = & $glazewm query windows 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($winRaw)) {
    $winResp = $winRaw | ConvertFrom-Json
    if ($winResp.success) {
        foreach ($w in $winResp.data.windows) {
            if ($null -ne $w.handle) { [void]$managedHandles.Add([long]$w.handle) }
        }
    }
}

# DWMWA_CLOAKED = 14. Return values:
#   0 = not cloaked
#   1 = DWM_CLOAKED_APP       (cloaked by the app itself; usually leave alone)
#   2 = DWM_CLOAKED_SHELL     (cloaked by Windows shell - what suspended UWP /
#                              new-Outlook / new-Teams / Edge background uses)
#   4 = DWM_CLOAKED_INHERITED (inherited from parent)
# SW_RESTORE = 9.
$SW_RESTORE = 9
$DWMWA_CLOAKED = 14

# Collect wake candidates with their preferred wake method:
#   ICONIC -> ShowWindowAsync(SW_RESTORE) - quiet, no focus theft.
#   CLOAKED (shell, not iconic) -> SwitchToThisWindow. ShowWindow* alone
#     does NOT trigger the OS events GlazeWM listens for on shell-cloaked
#     modern apps (new Outlook 'olk', new Teams 'ms-teams', Edge background),
#     so without forcing a foreground change GlazeWM never picks them up.
#     Focus theft is recovered by the focus-restore at the end of Phase 3.
$iconicHandles = New-Object System.Collections.Generic.List[System.IntPtr]
$cloakedHandles = New-Object System.Collections.Generic.List[System.IntPtr]
$enumProc = [Win32Restore+EnumWindowsProc]{
    param($h, $lp)
    if (-not [Win32Restore]::IsWindowVisible($h)) { return $true }
    # Skip empty-title helper windows (Default IME, MSCTFIME UI, etc.)
    if ([Win32Restore]::GetWindowTextLength($h) -le 0) { return $true }
    # Skip windows GlazeWM is already managing.
    if ($managedHandles.Contains([long]$h)) { return $true }

    $iconic = [Win32Restore]::IsIconic($h)
    $cloaked = 0
    [void][Win32Restore]::DwmGetWindowAttribute($h, $DWMWA_CLOAKED, [ref]$cloaked, 4)

    if ($iconic) {
        $iconicHandles.Add($h)
    }
    elseif ($cloaked -eq 2) {
        # Ignore app-cloak (1) and inherited (4) - those are intentional
        # and uncloaking would fight the owning app.
        $cloakedHandles.Add($h)
    }
    return $true
}
[Win32Restore]::EnumWindows($enumProc, [System.IntPtr]::Zero) | Out-Null

foreach ($h in $iconicHandles) {
    [Win32Restore]::ShowWindowAsync($h, $SW_RESTORE) | Out-Null
}
foreach ($h in $cloakedHandles) {
    [Win32Restore]::SwitchToThisWindow($h, $true) | Out-Null
    # Small gap so each foreground transition completes and GlazeWM picks
    # up the window before the next SwitchToThisWindow yanks focus away.
    Start-Sleep -Milliseconds 100
}

# Brief settle so GlazeWM's window-created events can be ingested and
# window_rules applied before we start asking it to query and re-tile.
Start-Sleep -Milliseconds 600


# ---- Phase 2: GlazeWM-managed re-tile + config reload ----

# Recurse the workspace tree and collect every descendant window node.
function Get-WindowsInContainer($node) {
    $out = New-Object System.Collections.Generic.List[object]
    if ($node.type -eq 'window') {
        $out.Add($node) | Out-Null
    }
    elseif ($node.children) {
        foreach ($child in $node.children) {
            foreach ($w in (Get-WindowsInContainer $child)) {
                $out.Add($w) | Out-Null
            }
        }
    }
    return $out
}

# Build a flat skip-set of window ids on cascade workspaces so the Phase 2
# set-tiling sweep doesn't undo the floating placements we're about to
# (re-)apply in Phase 3.
$skipIds = New-Object System.Collections.Generic.HashSet[string]
$wsRaw = & $glazewm query workspaces 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($wsRaw)) {
    $wsResp = $wsRaw | ConvertFrom-Json
    if ($wsResp.success) {
        foreach ($ws in $wsResp.data.workspaces) {
            if (-not $WorkspaceLayouts[$ws.name]) { continue }
            foreach ($w in (Get-WindowsInContainer $ws)) {
                [void]$skipIds.Add([string]$w.id)
            }
        }
    }
}

# Remember the originally-focused window so we can restore focus after
# any floating shuffles or Phase 2.5 moves change z-order / focus.
$focusedId = $null
$focRaw = & $glazewm query focused 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($focRaw)) {
    $focResp = $focRaw | ConvertFrom-Json
    if ($focResp.success -and $focResp.data.focused.type -eq 'window') {
        $focusedId = $focResp.data.focused.id
    }
}

# Set-tiling every non-tiling window EXCEPT the ones on cascade workspaces.
$raw = & $glazewm query windows 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    $resp = $raw | ConvertFrom-Json
    if ($resp.success) {
        foreach ($w in $resp.data.windows) {
            if ($skipIds.Contains([string]$w.id)) { continue }
            if ($w.state.type -ne 'tiling') {
                & $glazewm command --id $w.id set-tiling | Out-Null
            }
        }
    }
}

# Reload config to re-apply window_rules, which auto-allocates windows
# back to their default workspaces (same effect as pressing alt+shift+r).
& $glazewm command wm-reload-config | Out-Null
Start-Sleep -Milliseconds 400

# ---- Phase 2.5: park "unspecified" windows on workspace 9 ----
# Any process that has its own move/float/ignore rule in config.yaml is
# listed in $UnspecifiedSkipProcessRegex - those keep whatever workspace
# the rules just routed them to. Every OTHER managed window gets parked on
# workspace 9 so it doesn't clutter the active workspace. This is on-demand
# (not a config rule) so freshly-opened unknown apps still pop up on the
# active workspace; press alt+shift+m to sweep them away when convenient.
$raw2 = & $glazewm query windows 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($raw2)) {
    $resp2 = $raw2 | ConvertFrom-Json
    if ($resp2.success) {
        foreach ($w in $resp2.data.windows) {
            if ($w.processName -match $UnspecifiedSkipProcessRegex) { continue }
            & $glazewm command --id $w.id move --workspace 9 | Out-Null
        }
    }
}
Start-Sleep -Milliseconds 300

# ---- Phase 3: cascade-float every window on cascade workspaces ----
# Rebuild the cascade list from a fresh query so Phase 2.5's newly-parked
# windows are included, and any window the reload moved OFF of a cascade
# workspace is excluded. Also resolve each cascade workspace's current
# monitor so coordinates can be made relative to that monitor's origin
# (the script works whether ws9 lands on the desk's M3 Pool or falls back
# to the laptop monitor when M3 is disconnected).
$monsById = @{}
$monsRaw = & $glazewm query monitors 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($monsRaw)) {
    $monsResp = $monsRaw | ConvertFrom-Json
    if ($monsResp.success) {
        foreach ($m in $monsResp.data.monitors) { $monsById[$m.id] = $m }
    }
}

$cascadePlan = New-Object System.Collections.Generic.List[object]
$wsRaw3 = & $glazewm query workspaces 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($wsRaw3)) {
    $wsResp3 = $wsRaw3 | ConvertFrom-Json
    if ($wsResp3.success) {
        foreach ($ws in $wsResp3.data.workspaces) {
            $layout = $WorkspaceLayouts[$ws.name]
            if (-not $layout) { continue }
            $windows = Get-WindowsInContainer $ws
            if ($windows.Count -eq 0) { continue }
            $mon = $monsById[$ws.parentId]
            if (-not $mon) { continue }  # workspace not currently on any monitor
            $cascadePlan.Add([pscustomobject]@{
                Layout = $layout; Windows = $windows; Monitor = $mon
            }) | Out-Null
        }
    }
}

foreach ($entry in $cascadePlan) {
    $layout  = $entry.Layout
    $windows = $entry.Windows
    $mon     = $entry.Monitor
    # Clamp width/height so the window fits inside its monitor even on
    # the smaller laptop screen.
    $w = [Math]::Min($layout.Width,  $mon.width  - (2 * $layout.MarginX))
    $h = [Math]::Min($layout.Height, $mon.height - (2 * $layout.MarginY))
    for ($i = 0; $i -lt $windows.Count; $i++) {
        $x  = $mon.x + $layout.MarginX + ($i * $layout.OffsetX)
        $y  = $mon.y + $layout.MarginY + ($i * $layout.OffsetY)
        $id = $windows[$i].id

        # set-floating's --x-pos/--y-pos/--width/--height are silently
        # ignored when the target workspace isn't displayed, so issue
        # position + size separately. Those work on hidden workspaces.
        & $glazewm command --id $id set-floating --shown-on-top=false --centered=false | Out-Null
        & $glazewm command --id $id position --x-pos=$x --y-pos=$y | Out-Null
        & $glazewm command --id $id size --width=$w --height=$h | Out-Null
    }
}

if ($focusedId) {
    & $glazewm command focus --container-id $focusedId | Out-Null
}
