local ret_status="%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$%s)"
#PROMPT='%n@%m:%{$fg[green]%}%{$fg[cyan]%}%c%{$fg[blue]%}$(git_prompt_info)%{$fg[blue]%}% ${ret_status}%{$reset_color%} '
PROMPT='%/$(git_prompt_info)% ${ret_status}%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[yellow]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[yellow]%}%{$fg_bold[red]%}*%{$fg_bold[yellow]%})%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[yellow]%}) "
