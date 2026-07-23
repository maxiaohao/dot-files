
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

function c {
  & agency copilot --yolo @args
}
function cai {
  cd ~\ai-test
  & agency copilot --yolo @args
}
function sg { slngen **\*.csproj -vs "C:\Program Files\Microsoft Visual Studio\18\Enterprise\Common7\IDE\devenv.exe" }

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
        # Brand-new session, launched from outside zellij: start it with 9 tabs
        # (compact styling, same as default_layout). Layout is inlined so no
        # extra layout file is needed.
        $layout = @'
layout {
    default_tab_template {
        children
        pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
        }
    }
    tab
    tab
    tab
    tab
    tab
    tab
    tab
    tab
    tab
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

