DISABLE_AUTO_UPDATE=true

export NVM_LAZY_LOAD=true
HISTDB_TABULATE_CMD=(sed -e $'s/\x1f/\t/g')

source "${HOME}/.zgen/zgen.zsh"

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
  #zgen load lukechilds/zsh-nvm
  zgen load zsh-users/zsh-autosuggestions
  zgen load zsh-users/zsh-completions
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load maxiaohao/my-conf-files xma
  zgen load larkery/zsh-histdb sqlite-history.zsh
  zgen load larkery/zsh-histdb histdb-interactive.zsh
  zgen load m42e/zsh-histdb-fzf fzf-histdb.zsh
  zgen load junegunn/fzf shell/completion.zsh
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

#compinit

# don't share cmd history among windows
# setopt nosharehistory

HISTFILE="$HOME/.zsh_history"
HISTSIZE=500000
SAVEHIST=500000

unsetopt nomatch

alias ack='ack -i'
alias cat='bat'
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
alias l='lsd -F'
alias la='lsd -A'
alias ll='lsd -alF'
alias lll='lsd -alF'
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
alias watch='watch '
alias gs='gsutil'
alias curl='curlie'
alias b='brazil'
alias bb='brazil-build'
alias br='brazil release'
alias bs='brazil server'
alias bw='brazil workspace'
alias bbr='brazil-recursive-cmd --all brazil-build'
alias py='python3'

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

export MANPAGER='less -I'

export LC_ALL=en_AU.UTF-8
export LC_CTYPE=en_AU.UTF-8
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
export LANG=en_AU.UTF-8
export EDITOR="vim"
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
export XDG_CONFIG_HOME="$HOME/.config"
#export LDFLAGS="-L/opt/homebrew/opt/node@16/lib"
#export CPPFLAGS="-I/opt/homebrew/opt/node@16/include"

export PATH="/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export PATH=$PATH:$HOME/dev/tool/IN_PATH:$FIREFOX_HOME:$GOPATH/bin:$FLUTTER_HOME/bin
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:/home/xma11/.dotnet/tools"
export PATH="$HOME/.nix-profile/bin:$PATH"
export PATH="$HOME/.toolbox/bin:/opt/homebrew/bin:$PATH"
export PATH="$HOME/.nvm/versions/node/v18.13.0/bin:$PATH"
export PATH="$(pyenv root)/shims:${PATH}"

export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"

[[ -s $HOME/.localrc ]] && source $HOME/.localrc

[[ -x /usr/bin/jump ]] && eval "$(jump shell)"

# custom functions
[[ -s $HOME/.custom_functions.sh ]] && source $HOME/.custom_functions.sh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

[[ -f $HOME/dev/citrus/devops/script/devops-environment/rc ]] && source $HOME/dev/citrus/devops/script/devops-environment/rc

# # nvm (brew) (slow, using lukechilds/zsh-nvm zsh plugin instead)
# export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export GPG_TTY=$(tty)

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

true

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# fix Home/End keys in zsh in tmux
bindkey "\E[1~" beginning-of-line
bindkey "\E[4~" end-of-line

# histdb revserse isearch
bindkey '^[^r' _histdb-isearch

# settings for m42e/zsh-histdb-fzf
bindkey '^R' histdb-fzf-widget
HISTDB_FZF_DEFAULT_MODE=4

# fzf
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --iglob "!.DS_Store" --iglob "!.git"'
