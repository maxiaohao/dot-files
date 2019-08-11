# this file is ~/.oh-my-zsh/themes/xma.zsh-theme
local ret_status="%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$%s)"
#PROMPT='%n@%m:%{$fg[green]%}%{$fg[cyan]%}%c%{$fg[blue]%}$(git_prompt_info)%{$fg[blue]%}% ${ret_status}%{$reset_color%} '

# with git prompt status
#PROMPT='%K{white}%F{black}%m%f%k%F{green}:%f%~$(git_prompt_info)% $(git_prompt_status)%  ${ret_status}%{$reset_color%} '

# without git prompt status
#PROMPT='%K{white}%F{black}%m%f%k%F{green}:%f%~$(git_prompt_info)%  ${ret_status}%{$reset_color%} '

# shrinked path (if it has at least 5 segments, use shrinked path)
PROMPT='%K{white}%F{black}%m%f%k%F{green}:%f(5~|$(shrink_path -l -t)|%~)$(git_prompt_info)%  ${ret_status}%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[yellow]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[yellow]%}%{$fg_bold[red]%}*%{$fg_bold[yellow]%})%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[yellow]%})"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[magenta]%}[STASHED]%{$fg_bold[magenta]%}"
