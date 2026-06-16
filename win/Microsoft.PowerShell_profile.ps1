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

function c { & agency copilot --yolo @args }
function cai { cd ~\ai-test ; & agency copilot --yolo @args }
function sg { slngen **\*.csproj -vs "C:\Program Files\Microsoft Visual Studio\18\Enterprise\Common7\IDE\devenv.exe" }

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

function tm { $h=$env:COMPUTERNAME.ToLower(); $s=@(zellij ls -s 2>$null) -contains $h; if ($s) { zellij attach $h } else { zellij -s $h } }


atuin init --disable-up-arrow powershell | Out-String | Invoke-Expression

Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit

#Invoke-Expression (&starship init powershell)

Invoke-Expression (& { (zoxide init powershell | Out-String) })

