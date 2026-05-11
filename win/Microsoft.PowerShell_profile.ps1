$env:BAT_STYLE = "plain"
$env:BAT_OPTS = "--paging=always"

function tm {
  $sessName = (hostname).Split('.')[0]

  tmux has-session -t $sessName 2>$null
  if ($LASTEXITCODE -ne 0) {
    Set-Location $HOME
    tmux new-session -s $sessName -d
    tmux neww `; neww `; neww `; neww `; neww `; neww `; neww `; neww `; neww `; neww `; attach
  }
  tmux attach -t $sessName
}

#function c { copilot }

Set-Alias which Get-Command
Set-Alias c copilot
Set-Alias v nvim
Set-Alias vi nvim
Set-Alias vim nvim

function ll { eza --git --icons -alo @args }
function ls { eza @args }

atuin init --disable-up-arrow powershell | Out-String | Invoke-Expression

Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit

#oh-my-posh init pwsh | Invoke-Expression
Invoke-Expression (&starship init powershell)

Invoke-Expression (& { (zoxide init powershell | Out-String) })

