$env:BAT_STYLE = "plain"
$env:BAT_OPTS = "--paging=always"

function c { & copilot --yolo @args }

Set-Alias which Get-Command
Set-Alias v nvim
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias b busybox
Set-Alias lg lazygit


function ll { eza --git --icons -alo @args }
function ls { eza @args }

function gst   { git status @args }
function gd    { git diff @args }
function ga    { git add @args }
function gcmsg { git commit -m @args }
function gco   { git checkout @args }
#function gp    { git push @args }
function gpsup {
  $branch = git symbolic-ref --short HEAD
  git push --set-upstream origin $branch @args
}
function gf   { git fetch origin --prune @args }
function glg  { git log --abbrev-commit --date=format:"%Y-%m-%d %H:%M" --pretty=format:"%C(auto)%h%Creset %C(brightblack)%cd%Creset %s %C(blue)<%an %ae>%Creset" @args }


atuin init --disable-up-arrow powershell | Out-String | Invoke-Expression

Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit

##oh-my-posh init pwsh | Invoke-Expression
Invoke-Expression (&starship init powershell)

Invoke-Expression (& { (zoxide init powershell | Out-String) })

