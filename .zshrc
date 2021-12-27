DISABLE_AUTO_UPDATE=true

source /usr/share/zsh/share/zgen.zsh

if ! zgen saved; then
  zgen oh-my-zsh
  #zgen oh-my-zsh plugins/autojump
  zgen oh-my-zsh plugins/aws
  zgen oh-my-zsh plugins/colored-man-pages
  zgen oh-my-zsh plugins/docker
  zgen oh-my-zsh plugins/docker-compose
  zgen oh-my-zsh plugins/gcloud
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/git-extras
  zgen oh-my-zsh plugins/git-flow
  zgen oh-my-zsh plugins/golang
  zgen oh-my-zsh plugins/kubectl
  zgen oh-my-zsh plugins/mvn
  zgen oh-my-zsh plugins/npm
  zgen oh-my-zsh plugins/shrink-path
  zgen oh-my-zsh plugins/yarn
  zgen oh-my-zsh plugins/terraform
  zgen oh-my-zsh plugins/z
  zgen load zsh-users/zsh-autosuggestions
  zgen load zsh-users/zsh-completions
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load maxiaohao/my-conf-files xma
  zgen load larkery/zsh-histdb sqlite-history.zsh
  #zgen load larkery/zsh-histdb histdb-interactive.zsh (TODO: https://github.com/larkery/zsh-histdb#reverse-isearch + fzf)
  zgen save
fi

# speeds up pasting w/ autosuggest: https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

compinit

# don't share cmd history among windows
# setopt nosharehistory

HISTFILE="$HOME/.zsh_history"
HISTSIZE=500000
SAVEHIST=500000

unsetopt nomatch

alias ack='ack -i'
#alias cat='bat'
alias cda='cd ~/dev/citrus/adread'
alias cdd='cd ~/dev/citrus/devops'
alias cddm='cd ~/dev/citrus/devops/module'
alias cdg='cd ~/dev/citrus/adread'
alias cdm='cd ~/dev/citrus/mono-project'
alias cdw='cd ~/dev/citrus/web'
alias cp='cp -i'
alias date-my='date "+%Y-%m-%d %H:%M:%S%z"'
alias diff='diff --color=auto'
alias getms='echo $(($(date +%s%N)/1000000))'
alias getwindowpid='xprop _NET_WM_PID'
alias gfm='git fetch origin master:master'
alias gfd='git fetch origin develop:develop'
alias gitmp='git checkout master && gitss'
alias gitmpss='git checkout master && gitpss'
alias gitpp='git pull && git push && git status'
alias gitpss='git pull && git submodule init && git submodule update'
alias gitss='git submodule init && git submodule update'
alias gla='git --no-pager log --date=iso8601 --pretty="%C(Yellow)%h %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s"'
alias grep='grep -i --color'
alias gti='git'
alias k='kubectl'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias lll='ls -alF'
alias mvncc='mvn clean compile'
alias mvncd='mvn clean deploy'
alias mvnce='mvn clean eclipse:clean eclipse:eclipse'
alias mvnci='mvn clean install'
alias mvncp='mvn clean package'
alias mvnct='mvn clean test'
alias mvncv='mvn clean verify'
alias mvnec='mvn clean eclipse:clean eclipse:eclipse'
alias mvnit='mvn clean test-compile failsafe:integration-test failsafe:verify'
alias mvnlq='mvn clean compile && rm -f src/main/resources/db/temp/liquibase-diff-changeLog.xml && mvn liquibase:diff'
alias t='devops-environment terraform'
alias gsmedit='devops-environment gsmedit.sh'
alias gls='gsutil ls -l'
alias tmux='tmux -2'
alias v='vim'
alias vi='vim'
alias watch='watch '
alias gs='gsutil'
alias curl='curlie'

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

export LC_ALL=en_AU.UTF-8
export LC_CTYPE=en_AU.UTF-8
export LANG=en_AU.UTF-8
export VISUAL="vim"
export FLUTTER_HOME=$HOME/dev/tool/flutter
export CLUSTER_SECRET_DIR=$HOME/.cluster
export KUBE_EDITOR="vim"
export GOPATH=$HOME/dev/tool/go_path
export GOPRIVATE="github.com/citrus-international"
export PROMPT_EOL_MARK=""
export CHROME_BIN="chromium"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export BAT_STYLE="plain"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export PATH=$PATH:$HOME/dev/tool/IN_PATH:$FIREFOX_HOME:$GOPATH/bin:$FLUTTER_HOME/bin
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:/home/xma11/.dotnet/tools"

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

[[ -s $HOME/.localrc ]] && source $HOME/.localrc

[[ -x /usr/bin/jump ]] && eval "$(jump shell)"

# custom functions
[[ -s $HOME/.custom_functions.sh ]] && source $HOME/.custom_functions.sh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

[[ -f $HOME/dev/citrus/devops/script/devops-environment/rc ]] && source $HOME/dev/citrus/devops/script/devops-environment/rc

# # nvm (slow)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GPG_TTY=$(tty)

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

true

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# fix Home/End keys in zsh in tmux
bindkey "\E[1~" beginning-of-line
bindkey "\E[4~" end-of-line

if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi
