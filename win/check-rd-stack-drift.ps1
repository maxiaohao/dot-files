<#
.SYNOPSIS
  Warn when the Remote Desktop SxS network stack has been updated since the last boot.

.DESCRIPTION
  Dev Box auto-updates the RD Infra Agent and its side-by-side (SxS) network stack
  in place on the running VM. Listener registration is only reconciled at boot, so
  between an update and the next restart the old listener can go stale. When that
  happens RDP authentication still succeeds, but the session never gets a desktop:

    TerminalServices-LocalSessionManager 36  DisconnectedLoggedDesktopLocked -> 0x80070102
    TerminalServices-LocalSessionManager 36  CsrConnected -> EvCsrInitialized 0x8007048F
    Winlogon 4005                            The Windows logon process terminated

  which shows up in Windows App as a black screen, then a timeout or
  "the remote server ended the session". Only a full restart clears it.

  Two independent signals are checked:
    1. Drift    - an RDInfra install marker is newer than LastBootUpTime.
    2. Listeners- more than one enabled rdp-sxs* WinStation is registered.

.PARAMETER Notify
  Show a dialog when a problem is detected. Without this the script is silent and
  only reports through its return object and exit code.

.PARAMETER Force
  Show the dialog even if this exact state has already been reported once.

.OUTPUTS
  A result object. Exit code is 1 when action is recommended, otherwise 0.
#>
[CmdletBinding()]
param(
    [switch]$Notify,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$rdInfraPath = Join-Path $env:ProgramFiles 'Microsoft RDInfra'
$stateFile   = Join-Path $env:LOCALAPPDATA 'rd-stack-drift.state'

$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# Install markers the agent stamps whenever it lands a new stack or agent build.
$markers = @()
if (Test-Path $rdInfraPath) {
    $markers = @(Get-ChildItem -Path $rdInfraPath -Filter '*Install*.txt' -File -ErrorAction SilentlyContinue)
}
$drifted = @($markers | Where-Object { $_.LastWriteTime -gt $boot } | Sort-Object LastWriteTime)

# A healthy host has exactly one enabled rdp-sxs listener; leftovers mean the old
# stack was never retired.
$winStations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
$enabledListeners = @()
if (Test-Path $winStations) {
    $enabledListeners = @(
        Get-ChildItem $winStations -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -like 'rdp-sxs*' } |
            ForEach-Object {
                $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                if ($props.fEnableWinStation -eq 1) { $_.PSChildName }
            }
    )
}

$result = [pscustomobject]@{
    LastBoot          = $boot
    UptimeDays        = [math]::Round(((Get-Date) - $boot).TotalDays, 2)
    DriftedMarkers    = $drifted | ForEach-Object { '{0} @ {1:yyyy-MM-dd HH:mm}' -f $_.Name, $_.LastWriteTime }
    EnabledListeners  = $enabledListeners
    StackUpdatedSinceBoot = [bool]$drifted.Count
    MultipleListeners = ($enabledListeners.Count -gt 1)
    ActionNeeded      = $false
}
$result.ActionNeeded = $result.StackUpdatedSinceBoot -or $result.MultipleListeners

$result

if (-not $result.ActionNeeded) {
    if ($Notify -and (Test-Path $stateFile)) { Remove-Item $stateFile -Force -ErrorAction SilentlyContinue }
    exit 0
}

if ($Notify) {
    # Report a given state once, so the periodic trigger does not nag every run.
    $signature = '{0:o}|{1}|{2}' -f $boot,
        (($result.DriftedMarkers | Sort-Object) -join ';'),
        (($enabledListeners | Sort-Object) -join ';')

    $alreadyReported = (Test-Path $stateFile) -and ((Get-Content $stateFile -Raw -ErrorAction SilentlyContinue).Trim() -eq $signature)

    if (-not $alreadyReported -or $Force) {
        $lines = @(
            'Your Dev Box is at risk of the "black screen / cannot connect" failure.',
            ''
        )
        if ($result.StackUpdatedSinceBoot) {
            $lines += 'The Remote Desktop SxS network stack was updated after the last boot:'
            $lines += ($result.DriftedMarkers | ForEach-Object { "    $_" })
            $lines += ''
        }
        if ($result.MultipleListeners) {
            $lines += "More than one rdp-sxs listener is still enabled ($($enabledListeners -join ', '))."
            $lines += ''
        }
        $lines += ("Last boot: {0:yyyy-MM-dd HH:mm}  (up {1} days)" -f $boot, $result.UptimeDays)
        $lines += ''
        $lines += 'Restart the Dev Box at a convenient time. Leaving it will eventually'
        $lines += 'make the session unreachable until a forced restart.'

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # A scheduled task runs in the background, so a bare MessageBox can open
        # behind whatever is already on screen. Own it with an invisible TopMost
        # form so the warning is always on top, and keep a taskbar entry as a
        # fallback in case it still gets alt-tabbed away from. The owner is placed
        # explicitly at the centre of the primary display: with several monitors
        # attached the virtual desktop has negative coordinates, and CenterScreen
        # can otherwise drop the dialog onto whichever monitor it likes.
        $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $owner = New-Object System.Windows.Forms.Form
        $owner.Text          = 'Dev Box: restart recommended'
        $owner.TopMost       = $true
        $owner.ShowInTaskbar = $true
        $owner.Opacity       = 0
        $owner.FormBorderStyle = 'None'
        $owner.Size          = New-Object System.Drawing.Size(1, 1)
        $owner.StartPosition = 'Manual'
        $owner.Location      = New-Object System.Drawing.Point(
            ($work.X + [int]($work.Width / 2)),
            ($work.Y + [int]($work.Height / 2)))
        $owner.Show()
        [void]$owner.Activate()

        [void][System.Windows.Forms.MessageBox]::Show(
            $owner,
            ($lines -join [Environment]::NewLine),
            'Dev Box: restart recommended (RD stack updated)',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)

        $owner.Close()
        $owner.Dispose()

        Set-Content -Path $stateFile -Value $signature -Encoding UTF8
    }
}

exit 1
