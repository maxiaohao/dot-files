# Restore every GlazeWM-managed window back to tiling state.
# Bound to alt+shift+m via config.yaml.
#
# Phase 1: Win32 EnumWindows + SW_RESTORE pass over every minimised
#   top-level window on the desktop. Some apps (notably new Teams
#   "ms-teams" and new Outlook "olk", which are WebView2/UWP-style) do
#   not appear in `glazewm query windows` while minimised, so the
#   GlazeWM-only pass below misses them. EnumWindows is used (rather
#   than `Get-Process | MainWindowHandle`) so we catch every top-level
#   hwnd, including multi-window apps where the visible/iconic hwnd
#   isn't the process's primary one. Restoring them at the OS level
#   first makes them visible, which fires GlazeWM's window-created
#   event so window_rules can place them.
#
# Phase 2: GlazeWM pass: set-tiling on every known non-tiling window,
#   then wm-reload-config to re-apply window_rules so each window lands
#   on its configured workspace (same effect as pressing alt+shift+r).

$ErrorActionPreference = 'SilentlyContinue'

# ---- Phase 1: OS-level restore of minimised windows ----
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
'@
}

# SW_RESTORE = 9. Use EnumWindows (not Get-Process MainWindowHandle) so we
# enumerate every top-level window on the desktop, including secondary
# windows of multi-window apps (e.g. Outlook's compose / popup windows)
# and apps whose visible hwnd is not the process's "main" hwnd.
$SW_RESTORE = 9
$iconicHandles = New-Object System.Collections.Generic.List[System.IntPtr]
$enumProc = [Win32Restore+EnumWindowsProc]{
    param($h, $lp)
    if ([Win32Restore]::IsWindowVisible($h) -and [Win32Restore]::IsIconic($h)) {
        $iconicHandles.Add($h)
    }
    return $true
}
[Win32Restore]::EnumWindows($enumProc, [System.IntPtr]::Zero) | Out-Null

foreach ($h in $iconicHandles) {
    [Win32Restore]::ShowWindowAsync($h, $SW_RESTORE) | Out-Null
}

# Brief settle so GlazeWM's window-created events can be ingested before
# we start asking it to query and re-tile.
Start-Sleep -Milliseconds 400

# ---- Phase 2: GlazeWM-managed re-tile + config reload ----
$glazewm = Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe'
if (-not (Test-Path $glazewm)) {
    $glazewm = 'glazewm'
}

$raw = & $glazewm query windows 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    $resp = $raw | ConvertFrom-Json
    if ($resp.success) {
        foreach ($w in $resp.data.windows) {
            if ($w.state.type -ne 'tiling') {
                & $glazewm command --id $w.id set-tiling | Out-Null
            }
        }
    }
}

# Reload config to re-apply window_rules, which auto-allocates windows
# back to their default workspaces (same effect as pressing alt+shift+r).
& $glazewm command wm-reload-config | Out-Null
