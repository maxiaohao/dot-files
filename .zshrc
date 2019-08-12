source /usr/share/zsh/share/zgen.zsh

if ! zgen saved; then
  zgen oh-my-zsh
  zgen oh-my-zsh plugins/autojump
  zgen oh-my-zsh plugins/aws
  zgen oh-my-zsh plugins/colored-man-pages
  zgen oh-my-zsh plugins/docker
  zgen oh-my-zsh plugins/docker-compose
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/git-extras
  zgen oh-my-zsh plugins/git-flow
  zgen oh-my-zsh plugins/golang
  zgen oh-my-zsh plugins/kubectl
  zgen oh-my-zsh plugins/mvn
  zgen oh-my-zsh plugins/npm
  zgen oh-my-zsh plugins/shrink-path
  zgen oh-my-zsh plugins/yarn
  zgen oh-my-zsh plugins/z
  zgen load zsh-users/zsh-autosuggestions
  zgen load zsh-users/zsh-completions
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  zgen load maxiaohao/my-conf-files xma
  zgen save
fi

# source /home/xma11/dev/tool/antigen/antigen.zsh
# antigen use oh-my-zsh
# antigen bundle autojump
# antigen bundle aws
# antigen bundle colored-man-pages
# antigen bundle docker
# antigen bundle docker-compose
# antigen bundle git
# antigen bundle git-extras
# antigen bundle git-flow
# antigen bundle golang
# antigen bundle kubectl
# antigen bundle mvn
# antigen bundle npm
# antigen bundle yarn
# antigen bundle z
# antigen bundle shrink-path
# antigen bundle djui/alias-tips
# antigen bundle zsh-users/zsh-autosuggestions
# antigen bundle zsh-users/zsh-completions
# antigen bundle zsh-users/zsh-syntax-highlighting
# antigen theme https://github.com/maxiaohao/my-conf-files.git xma
# antigen apply

DISABLE_AUTO_UPDATE="true"

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

# # completion
# if [ -d ~/.zsh/completion ]; then
#   fpath=(~/.zsh/completion $fpath)
#   autoload -U compinit
#   compinit
# fi

compinit

# don't share cmd history among windows
setopt nosharehistory

unsetopt nomatch

# alias aws_enc=aws_enc
# alias aws_dec=aws_dec

alias vi='vim'
alias ll='ls -alF'
alias lll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep -i --color'
alias ack='ack -i'
alias ag='ag -i'
alias gti='git'
alias cp='cp -i'
alias date-my='date +%Y%m%d%H%M%S%Z'
alias gitpp='git pull && git push && git status'
alias dock='sudo docker'
alias mvnec='mvn clean eclipse:clean eclipse:eclipse'
alias mvnce='mvn clean eclipse:clean eclipse:eclipse'
alias mvncc='mvn clean compile'
alias mvnci='mvn clean install'
alias mvncd='mvn clean deploy'
alias mvncp='mvn clean package'
alias mvnct='mvn clean test'
alias mvncv='mvn clean verify'
alias mvnit='mvn clean test-compile failsafe:integration-test failsafe:verify'
alias mvnlq='mvn clean compile && rm -f src/main/resources/db/temp/liquibase-diff-changeLog.xml && mvn liquibase:diff'
alias gitss='git submodule init && git submodule update'
alias gitpss='git pull && git submodule init && git submodule update'
alias gitmp='git checkout master && gitss'
alias gitmpss='git checkout master && gitpss'
alias getwindowpid='xprop _NET_WM_PID'
alias getms='echo $(($(date +%s%N)/1000000))'
alias diff='diff --color=auto'
alias tmux='tmux -2'
alias watch='watch '
alias cdm='cd ~/dev/citrus/mono-project'
alias gfm='git fetch origin master:master'
alias gla='git --no-pager log --date=iso8601 --pretty="%C(Yellow)%h %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s"'
alias k='kubectl'

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

export LC_ALL=en_AU.UTF-8
export LANG=en_AU.UTF-8
export VISUAL="vim"
#export JAVA_HOME=~/dev/tool/jdk-current
#export GRADLE_HOME=~/dev/tool/gradle-current
#export M2_HOME=~/dev/tool/apache-maven-current
#export ANT_HOME=~/dev/tool/apache-ant-current
#export NODE_HOME=~/dev/tool/node-current
export FIREFOX_HOME=~/dev/tool/firefox-current
export MY_CONF_FILES=~/dev/xma-projects/my-conf-files
export CLUSTER_SECRET_DIR=/home/xma11/.cluster
export KUBE_EDITOR="vim"
export GOPATH=~/dev/tool/go_path
export PROMPT_EOL_MARK=""

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export PATH=~/dev/tool/IN_PATH:$MY_CONF_FILES:$FIREFOX_HOME:$GOPATH/bin:$PATH
export PATH="$PATH:$HOME/.rvm/bin"

# kubectl () {
#     if [[ -z $KUBECTL_COMPLETE ]]
#     then
#         source <($commands[kubectl] completion zsh)
#         KUBECTL_COMPLETE=1
#     fi
#     $commands[kubectl] $*
# }

if [ -f ~/.localrc ]; then
  source ~/.localrc
fi

if [ -f ~/dev/citrus/mono-project/cluster/src/tools/bash_helper/cluster ]; then
  source ~/dev/citrus/mono-project/cluster/src/tools/bash_helper/cluster
  source ~/dev/citrus/mono-project/cluster/src/tools/bash_helper/cluster-completion.bash
fi

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/xma11/.sdkman"
[[ -s "/home/xma11/.sdkman/bin/sdkman-init.sh" ]] && source "/home/xma11/.sdkman/bin/sdkman-init.sh"

# # nvm (slow)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GPG_TTY=$(tty)

export GOOGLE_APPLICATION_CREDENTIALS="/home/xma11/.gcp-creds.json"

# custom functions
source $MY_CONF_FILES/custom_functions.sh

true
