
# Zellij sets TERM=xterm-256color but does not pass COLORTERM through, so every
# program inside a pane detects only 256 colours even though Windows Terminal and
# zellij both render 24-bit fine. Copilot CLI in particular downgrades to its
# fallback theme tokens below truecolor, which leaves user prompts with no
# background highlight and renders the transcript scrollbar as an undifferentiated
# solid block. Advertise truecolor so full palettes resolve.
if (-not $env:COLORTERM) { $env:COLORTERM = 'truecolor' }

$env:BAT_STYLE = "plain"
$env:BAT_OPTS = "--paging=always"

Set-Alias which Get-Command
Set-Alias v vim
Set-Alias vi vim
Set-Alias b busybox
Set-Alias lg lazygit
Set-Alias ll dir

#function ll { eza --icons -alo @args }
#function ls { eza @args }
function bc { b bc -l }

# Run Copilot directly, without the Agency wrapper. Pin the standalone 1.0.83
# binary because 1.0.86+ regressed theme rendering behind zellij when OSC
# palette queries cannot pass through the multiplexer. --no-auto-update stops
# this executable from downloading or switching to a newer bundle.
$script:CopilotCli = Join-Path $HOME '.copilot-cli\1.0.83\copilot.exe'

function Invoke-PinnedCopilot {
  if (-not (Test-Path -LiteralPath $script:CopilotCli -PathType Leaf)) {
    throw "Pinned Copilot CLI 1.0.83 is missing: $script:CopilotCli"
  }
  & $script:CopilotCli --no-auto-update --yolo @args
}

function c {
  Invoke-PinnedCopilot @args
}

function cai {
  Set-Location -LiteralPath (Join-Path $HOME 'ai-test')
  Invoke-PinnedCopilot @args
}

# cps: list top-level Copilot CLI sessions. New sessions are direct copilot.exe
# processes; legacy Agency-hosted sessions are still recognized until closed.
function cps {
  $snapshot = @(Get-CimInstance Win32_Process |
    Select-Object ProcessId, ParentProcessId, Name, CreationDate, CommandLine)
  $byId = @{}
  foreach ($process in $snapshot) { $byId[[int]$process.ProcessId] = $process }

  $roots = @($snapshot | Where-Object {
    $_.Name -eq 'agency.exe' -and $_.CommandLine -match '\bcopilot\b'
  })

  foreach ($process in ($snapshot | Where-Object { $_.Name -eq 'copilot.exe' })) {
    $ancestor = [int]$process.ParentProcessId
    $underAgency = $false
    for ($i = 0; $i -lt 20 -and $byId.ContainsKey($ancestor); $i++) {
      $parent = $byId[$ancestor]
      if ($parent.Name -eq 'agency.exe' -and $parent.CommandLine -match '\bcopilot\b') {
        $underAgency = $true
        break
      }
      $ancestor = [int]$parent.ParentProcessId
    }
    if (-not $underAgency) { $roots += $process }
  }

  if (-not $roots) {
    Write-Host 'No Copilot CLI sessions are running.' -ForegroundColor DarkGray
    return
  }

  $now = Get-Date
  $roots | Sort-Object CreationDate | ForEach-Object {
    [pscustomobject]@{
      PID     = $_.ProcessId
      Started = $_.CreationDate
      Age     = '{0:N1}h' -f ($now - $_.CreationDate).TotalHours
      Host    = $_.Name
    }
  } | Format-Table -AutoSize
}

# ckill: terminate every direct or legacy Agency-hosted Copilot CLI session and
# its MCP/tool subprocesses.
# A separate helper process performs the kill so this also works when invoked
# through `!ckill` from inside a Copilot session: the caller can terminate
# itself without stopping halfway through the remaining process trees.
function ckill {
  $snapshot = @(Get-CimInstance Win32_Process |
    Select-Object ProcessId, ParentProcessId, Name, CommandLine)
  $byId = @{}
  $childrenOf = @{}
  foreach ($process in $snapshot) {
    $byId[[int]$process.ProcessId] = $process
    $parent = [int]$process.ParentProcessId
    if (-not $childrenOf.ContainsKey($parent)) { $childrenOf[$parent] = @() }
    $childrenOf[$parent] += $process
  }

  $roots = @($snapshot | Where-Object {
    $_.Name -eq 'agency.exe' -and $_.CommandLine -match '\bcopilot\b'
  })

  foreach ($process in ($snapshot | Where-Object { $_.Name -eq 'copilot.exe' })) {
    $ancestor = [int]$process.ParentProcessId
    $underAgency = $false
    for ($i = 0; $i -lt 20 -and $byId.ContainsKey($ancestor); $i++) {
      $parent = $byId[$ancestor]
      if ($parent.Name -eq 'agency.exe' -and $parent.CommandLine -match '\bcopilot\b') {
        $underAgency = $true
        break
      }
      $ancestor = [int]$parent.ParentProcessId
    }
    if (-not $underAgency) { $roots += $process }
  }

  if (-not $roots) {
    Write-Host 'No Copilot CLI sessions are running.' -ForegroundColor DarkGray
    return
  }

  $depthById = @{}
  $queue = [System.Collections.Generic.Queue[object]]::new()
  foreach ($root in $roots) {
    $id = [int]$root.ProcessId
    if (-not $depthById.ContainsKey($id)) {
      $depthById[$id] = 0
      $queue.Enqueue([pscustomobject]@{ Id = $id; Depth = 0 })
    }
  }
  while ($queue.Count -gt 0) {
    $node = $queue.Dequeue()
    if (-not $childrenOf.ContainsKey([int]$node.Id)) { continue }
    foreach ($child in $childrenOf[[int]$node.Id]) {
      $id = [int]$child.ProcessId
      $depth = [int]$node.Depth + 1
      if (-not $depthById.ContainsKey($id) -or $depthById[$id] -lt $depth) {
        $depthById[$id] = $depth
        $queue.Enqueue([pscustomobject]@{ Id = $id; Depth = $depth })
      }
    }
  }

  $ids = @($depthById.GetEnumerator() |
    Sort-Object Value -Descending |
    ForEach-Object { [int]$_.Key })
  $code = @"
Start-Sleep -Milliseconds 300
@($($ids -join ',')) | ForEach-Object {
  Stop-Process -Id `$_ -Force -ErrorAction SilentlyContinue
}
"@
  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
  $pwsh = (Get-Process -Id $PID).Path
  Start-Process -FilePath $pwsh -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-EncodedCommand', $encoded
  ) | Out-Null

  Write-Host "Stopping $($roots.Count) Copilot session(s) and $($ids.Count - $roots.Count) child process(es)." -ForegroundColor Yellow
}

function sg { slngen **\*.csproj -vs "C:\Program Files\Microsoft Visual Studio\18\Enterprise\Common7\IDE\devenv.exe" }

# caps: clear a stuck CapsLock. The kanata caps-nav layer maps CapsLock to a
# layer key, so it never sends a capslock keypress and cannot toggle itself off.
# If the OS toggle latches ON while kanata is not running (during a restart,
# before the logon task fires, or on the UAC/lock secure desktop) it stays ON.
# This synthesises the keypress that clears it.
function caps {
  if (-not ('CapsLockToggle' -as [type])) {
    Add-Type -Name CapsLockToggle -Namespace Win32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern short GetKeyState(int key);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
'@
  }
  $vk = 0x14
  $wasOn = ([Win32.CapsLockToggle]::GetKeyState($vk) -band 1) -ne 0
  if (-not $wasOn) {
    Write-Host 'CapsLock is already off.' -ForegroundColor DarkGray
    return
  }
  [Win32.CapsLockToggle]::keybd_event($vk, 0x3A, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [Win32.CapsLockToggle]::keybd_event($vk, 0x3A, 2, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 200
  if ((([Win32.CapsLockToggle]::GetKeyState($vk) -band 1) -ne 0)) {
    Write-Host 'CapsLock is still on.' -ForegroundColor Yellow
  } else {
    Write-Host 'CapsLock cleared.' -ForegroundColor Green
  }
}

# fo (Find and Open): fd for files matching the given pattern, then open the pick in vim.
# No match -> message only; exactly one match -> open it straight away; otherwise pick via fzf.
# Extra arguments are passed through to fd, e.g. `fo config -e toml`.
function fo {
  if ($args.Count -eq 0) {
    Write-Host 'usage: fo <pattern> [extra fd args...]' -ForegroundColor Yellow
    return
  }

  $found = @(fd --type f --hidden --no-ignore @args)

  if ($found.Count -eq 0) {
    Write-Host "fo: no files found" -ForegroundColor DarkYellow
    return
  }

  if ($found.Count -eq 1) {
    vim -- $found[0]
    return
  }

  $picked = $found | fzf --prompt 'fo> ' --height 60% --reverse --no-multi --no-sort
  if ($picked) { vim -- $picked }
}

# cdf (Change Dir to File): cd into the directory holding the given file,
# e.g. `cdf foo/bar/baz.txt` lands in foo/bar. A directory argument is entered
# directly, and a bare file name with no directory part leaves you where you are.
function cdf {
  if ($args.Count -eq 0) {
    Write-Host 'usage: cdf <path-to-file>' -ForegroundColor Yellow
    return
  }

  $target = [string]$args[0]

  if (Test-Path -LiteralPath $target -PathType Container) {
    Set-Location -LiteralPath $target
    return
  }

  $dir = Split-Path -Path $target -Parent
  if ([string]::IsNullOrEmpty($dir)) { $dir = '.' }

  if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
    Write-Host "cdf: no such directory: $dir" -ForegroundColor DarkYellow
    return
  }

  Set-Location -LiteralPath $dir
}

function gst   { git status @args }
function gd    { git diff @args }
function ga    { git add @args }
function gcmsg { git commit -m @args }
function gco   { git checkout @args }

if (Test-Path Alias:gl) { Remove-Item Alias:gl -Force }
function gl { git pull @args }
if (Test-Path Alias:gp) { Remove-Item Alias:gp -Force }
function gp {
  $branch = git symbolic-ref --short HEAD
  git push --set-upstream origin $branch @args
}
function gpsup {
  $branch = git symbolic-ref --short HEAD
  git push --set-upstream origin $branch @args
}
function gf   { git fetch origin --prune @args }
function glg  { git log --abbrev-commit --date=format:"%Y-%m-%d %H:%M" --pretty=format:"%C(auto)%h%Creset %C(brightblack)%cd%Creset %s %C(blue)<%an %ae>%Creset" @args }


function tm {
    $name = if ($args.Count -gt 0) { $args[0] } else { 'main' }
    if (-not $env:TERM) { $env:TERM = 'xterm-256color' }

    $exists = @(zellij list-sessions -ns 2>$null) -contains $name

    if (-not $exists -and -not $env:ZELLIJ) {
        # Brand-new session, launched from outside zellij: start it with 15
        # initialized tabs. This layout is used only at session creation; a
        # later `tm` attaches to the existing session without re-running any
        # command or resetting any tab's working directory.
        $layout = @'
layout {
    default_tab_template {
        children
        pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
        }
    }
    tab name="  1  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  2  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  3  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  4  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  5  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  6  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  7  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  8  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  9  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "cai"
        }
    }
    tab name="  a  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "Set-Location -LiteralPath 'Q:/src/XStore'"
        }
    }
    tab name="  b  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "Set-Location -LiteralPath 'Q:/src/XLifecycle'"
        }
    }
    tab name="  c  " {
        pane command="C:/tool/powershell/pwsh.exe" {
            args "-NoExit" "-Command" "Set-Location -LiteralPath 'Q:/src/OneDCMT'"
        }
    }
    tab name="  d  "
    tab name="  e  "
    tab name="  f  "
}
'@
        zellij --layout-string $layout attach --create $name
    } else {
        # Existing session (just attach) or nested call (avoid injecting tabs).
        zellij attach --create $name
    }
}

function prompt {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch) {
        Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation) " -NoNewline
        Write-Host "[$branch]" -NoNewline -ForegroundColor DarkYellow
        return "> "
    } else {
        "PS $($executionContext.SessionState.Path.CurrentLocation)> "
    }
}


# ## Keep zellij's default_shell pointing at the real pwsh binary (the
# ## WindowsApps app-execution-alias shim is a zero-byte reparse point that
# ## zellij can't launch, which silently downgrades sessions to Windows
# ## PowerShell 5.1). Re-resolve the versioned WindowsApps install path on
# ## every shell start so the config survives pwsh upgrades.
# function Sync-ZellijShell {
#   $real = (Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue |
#     Where-Object { $_.Source -like '*\WindowsApps\Microsoft.PowerShell_*\pwsh.exe' } |
#     Select-Object -First 1).Source
#   if (-not $real) { return }
#   $cfg = Join-Path $env:APPDATA 'Zellij\config\config.kdl'
#   if (-not (Test-Path $cfg)) { return }
#   $line = 'default_shell "' + ($real -replace '\\','/') + '"'
#   $content = Get-Content $cfg -Raw
#   $pattern = '(?m)^default_shell\s+".*"'
#   if ($content -match $pattern -and $Matches[0] -ne $line) {
#     $new = [regex]::Replace($content, $pattern, $line.Replace('$','$$'))
#     Set-Content -Path $cfg -Value $new -NoNewline -Encoding UTF8
#   }
# }
# Sync-ZellijShell




atuin init --disable-up-arrow powershell | Out-String | Invoke-Expression

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit

#Invoke-Expression (&starship init powershell)

Invoke-Expression (& { (zoxide init powershell | Out-String) })
