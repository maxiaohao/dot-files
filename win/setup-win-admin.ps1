# run as Admin

mkdir $HOME\dev
mkdir $HOME\doc

New-Item -ItemType SymbolicLink -Target "$HOME\OneDrive - Microsoft\Documents\dev\dot-files" -Path "$HOME\dev\dot-files"
New-Item -ItemType SymbolicLink -Target "$HOME\OneDrive - Microsoft\Documents\doc\family-doc" -Path "$HOME\doc\family-doc"
New-Item -ItemType SymbolicLink -Target "$HOME\OneDrive - Microsoft\Documents\doc\personal-doc" -Path "$HOME\doc\personal-doc"


New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\win\Microsoft.PowerShell_profile.ps1" -Path "$HOME\OneDrive - Microsoft\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

mkdir $HOME\AppData\Roaming\alacritty
New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\win\alacritty.toml" -Path "$HOME\AppData\Roaming\alacritty\alacritty.toml"

New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\win\.tmux.conf" -Path "$HOME\.tmux.conf"

mkdir $HOME\.config
New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\win\.config__starship.toml" -Path "$HOME\.config\starship.toml"

New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\.ripgreprc" -Path "$HOME\.ripgreprc"
New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\.vimrc" -Path "$HOME\.vimrc"

mkdir $HOME\AppData\Roaming\atuin
New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\.config__atuin__config.toml" -Path "$HOME\AppData\Roaming\atuin\config.toml"

New-Item -ItemType SymbolicLink -Target "$HOME\dev\dot-files\.config__nvim" -Path "$HOME\AppData\Local\nvim"



New-Item -ItemType SymbolicLink -Target "$HOME\doc\personal-doc\notes_latest" -Path "$HOME\notes"
New-Item -ItemType SymbolicLink -Target "$HOME\doc\personal-doc\notes_private" -Path "$HOME\notes_private"

mkdir $HOME\.ssh
New-Item -ItemType SymbolicLink -Target "$HOME\doc\personal-doc\.ssh\config" -Path "$HOME\.ssh\config"


