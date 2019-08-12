# this file is ~/.oh-my-zsh/themes/xma.zsh-theme
ret_status_symbol="%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$%s)"
PROMPT='%K{white}%F{black}%m%f%k%F{green}:%f$(shrink_path -l -t)$(git_prompt_info)%  ${ret_status_symbol}%{$reset_color%} '
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[yellow]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[yellow]%}%{$fg_bold[red]%}*%{$fg_bold[yellow]%})%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[yellow]%})"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[magenta]%}[STASHED]%{$fg_bold[magenta]%}"
