<#
.SYNOPSIS
    Installs the My Diff viewer as a background service that starts at Windows boot.

.DESCRIPTION
    Node.js is not a service-aware executable, so instead of sc.exe this script registers a
    Scheduled Task that runs `node server.js <Port> <ScriptRoot>` as SYSTEM with an "At startup"
    trigger. That gives the same practical result as a service (starts at boot, no logon needed,
    auto-restarts on failure) without pulling in NSSM / WinSW / node-windows.

    The server binds to 127.0.0.1 only, so no firewall rule is needed.

.PARAMETER Port
    TCP port to listen on. Default 8777.

.PARAMETER TaskName
    Scheduled Task name. Default 'MyDiffServer'.

.PARAMETER Uninstall
    Stops the task, removes it, and kills any leftover server process.

.PARAMETER Status
    Shows the task state and probes the HTTP endpoint.

.EXAMPLE
    .\install-service.ps1
    Installs on port 8777 and starts it immediately.

.EXAMPLE
    .\install-service.ps1 -Port 9000

.EXAMPLE
    .\install-service.ps1 -Status

.EXAMPLE
    .\install-service.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$Port = 8777,

    [ValidateNotNullOrEmpty()]
    [string]$TaskName = 'MyDiffServer',

    [switch]$Uninstall,

    [switch]$Status
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$serverScript = Join-Path $root 'server.js'

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-Admin)) {
        throw "Administrator rights are required. Re-run from an elevated PowerShell: powershell -File `"$PSCommandPath`""
    }
}

function Get-NodePath {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command node -ErrorAction SilentlyContinue }
    if (-not $node) { throw 'node.exe was not found on PATH. Install Node.js first.' }
    return $node.Source
}

function Get-ServerProcesses {
    Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" |
        Where-Object { $_.CommandLine -and $_.CommandLine -like '*server.js*' -and $_.CommandLine -like "*$root*" }
}

function Test-Endpoint {
    param([int]$TimeoutSeconds = 20)

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) { return $true }
        } catch {
            Start-Sleep -Milliseconds 700
        }
    } while ((Get-Date) -lt $deadline)

    return $false
}

function Show-Status {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        if (Test-Admin) {
            Write-Host "Task '$TaskName' is not installed." -ForegroundColor Yellow
        } else {
            # A SYSTEM-owned task is not readable without elevation, and the lookup
            # fails the same way as a missing task, so don't claim it is missing.
            Write-Host "Task '$TaskName' is not visible from a non-elevated session." -ForegroundColor Yellow
            Write-Host "Re-run elevated for task details. Probing the endpoint instead ..."
        }

        if (Test-Endpoint -TimeoutSeconds 3) {
            Write-Host "Endpoint  : http://localhost:$Port/ responding" -ForegroundColor Green
        } else {
            Write-Host "Endpoint  : http://localhost:$Port/ not responding" -ForegroundColor Red
        }
        return
    }

    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    $lastResult = '0x{0:X}' -f $info.LastTaskResult
    Write-Host "Task      : $TaskName"
    Write-Host "State     : $($task.State)"
    Write-Host "Principal : $($task.Principal.UserId) / $($task.Principal.RunLevel)"
    Write-Host "Trigger   : $($task.Triggers.CimClass.CimClassName -join ', ')"
    Write-Host "Action    : $($task.Actions.Execute) $($task.Actions.Arguments)"
    Write-Host "Last run  : $($info.LastRunTime) (result $lastResult)"
    Write-Host "Processes : $((Get-ServerProcesses | Measure-Object).Count) node.exe"

    if (Test-Endpoint -TimeoutSeconds 3) {
        Write-Host "Endpoint  : http://localhost:$Port/ responding" -ForegroundColor Green
    } else {
        Write-Host "Endpoint  : http://localhost:$Port/ not responding" -ForegroundColor Red
    }
}

function Remove-Installation {
    Assert-Admin

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
    } else {
        Write-Host "Task '$TaskName' was not installed." -ForegroundColor Yellow
    }

    foreach ($proc in Get-ServerProcesses) {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped leftover server process $($proc.ProcessId)."
    }
}

function Install-Task {
    Assert-Admin

    if (-not (Test-Path -LiteralPath $serverScript)) {
        throw "server.js was not found next to this script ($serverScript)."
    }

    $node = Get-NodePath
    Write-Host "Node      : $node"
    Write-Host "Root      : $root"
    Write-Host "Port      : $Port"

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Replacing existing task '$TaskName'."
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute $node `
        -Argument "`"$serverScript`" $Port `"$root`"" `
        -WorkingDirectory $root

    $trigger = New-ScheduledTaskTrigger -AtStartup

    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' `
        -LogonType ServiceAccount -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
        -MultipleInstances IgnoreNew -Hidden `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings `
        -Description "Serves the My Diff single-page viewer on http://localhost:$Port/" | Out-Null

    Start-ScheduledTask -TaskName $TaskName

    if (Test-Endpoint) {
        Write-Host ""
        Write-Host "Installed and running: http://localhost:$Port/" -ForegroundColor Green
        Write-Host "It will start automatically at every Windows boot."
        Write-Host "Manage it with: .\install-service.ps1 -Status | -Uninstall"
    } else {
        throw "Task was registered but http://localhost:$Port/ did not respond. Check: Get-ScheduledTaskInfo -TaskName $TaskName"
    }
}

if ($Uninstall -and $Status) { throw 'Use either -Uninstall or -Status, not both.' }

if ($Status) { Show-Status }
elseif ($Uninstall) { Remove-Installation }
else { Install-Task }
