# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
ZSH_THEME="xma"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
#ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git autojump gradle npm mvn docker zsh-syntax-highlighting)

# User configuration

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# don't share cmd history among windows
setopt nosharehistory

unsetopt nomatch

function screen_shot() {
  mkdir -p ~/.screenshot
  FILE_NAME="~/.screenshot/"$(date "+%Y%m%d%H%M%S-%N")".png"
  import $FILE_NAME && xclip -selection clipboard -target image/png $FILE_NAME
}

function aws_enc() {
  aws kms encrypt --key-id alias/general-secret-passing --plaintext "$1" --output text --query CiphertextBlob
}

function aws_dec() {
  TEMP_BINARY_FILE=$(uuidgen)
  echo $1 | base64 --decode > $TEMP_BINARY_FILE
  aws kms decrypt --ciphertext-blob fileb://$TEMP_BINARY_FILE --output text --query Plaintext --region ap-southeast-2 | base64 --decode
  echo
  rm $TEMP_BINARY_FILE
}

function kp() {
  kops export kubecfg --state s3://citrusad.net.state au.citrusad.net
  kubectl proxy --port=8081
}

function kl() {
  row_num=1
  if [ "" != "$3" ]; then
    row_num=$3
  fi
  pod=`kubectl get pods --namespace $1|grep $2|grep Running|awk 'NR=='$row_num'{print $1}'`
  kubectl logs --namespace $1 -c $2 $pod
}

function klf() {
  row_num=1
  if [ "" != "$3" ]; then
    row_num=$3
  fi
  pod=`kubectl get pods --namespace $1|grep $2|grep Running|awk 'NR=='$row_num'{print $1}'`
  kubectl logs --namespace $1 -c $2 -f $pod
}

function appcfg() {
  KMS_KEY_ID=812045f4-178f-4241-bed4-2096e5a6cf03
  ENV=$1
  SERVICE_NAME=$2
  CURRENT_TIME=$(date "+%Y%m%d%H%M%S-%N")
  HISTORY_DIR=~/.appcfg_history
  WORK_DIR=$HISTORY_DIR/$SERVICE_NAME-$CURRENT_TIME
  if [ "$ENV" = "" ]; then
    echo "Usage: appcfg <env> <service>"
    return 2
  fi
  if [ "$SERVICE_NAME" = "" ]; then
    echo "Usage: appcfg <env> <service>"
    return 2
  fi
  mkdir $WORK_DIR -p
  aws s3 sync s3://citrusad.net/$ENV/$SERVICE_NAME-service $WORK_DIR &> /dev/null
  if [ "$?" != "0" ]; then
    echo "Failed to sync from S3"
    return 1
  fi
  if [ -f $WORK_DIR/application.properties ]; then
    aws kms decrypt --ciphertext-blob fileb://$WORK_DIR/application.properties --output text --query Plaintext --region ap-southeast-2 | base64 --decode > $WORK_DIR/application.properties.plain.old
    if [ "$?" != "0" ]; then
      echo "Failed to decrypt file using KMS"
      return 1
    fi
    cp -f $WORK_DIR/application.properties.plain.old $WORK_DIR/application.properties.plain.new
    vi $WORK_DIR/application.properties.plain.new
    diff $WORK_DIR/application.properties.plain.old $WORK_DIR/application.properties.plain.new > /dev/null 2>&1
    if [ "$?" != "0" ]; then
      aws kms encrypt --key-id $KMS_KEY_ID --plaintext fileb://$WORK_DIR/application.properties.plain.new --output text --query CiphertextBlob | base64 --decode > $WORK_DIR/pplication.properties.new
      aws s3 cp $WORK_DIR/pplication.properties.new s3://citrusad.net/$ENV/$SERVICE_NAME-service/application.properties &> /dev/null
      if [ "$?" = "0" ]; then
        echo "application.properties for '$SERVICE_NAME' in '$ENV' changed successfully"
      else
        echo "ERROR: failed to change file"
        return 1
      fi
    else
      echo "Nothing changed"
      rm -rf $WORK_DIR
    fi
    return 0
  else
    echo "application.properties for '$SERVICE_NAME' in '$ENV' not found"
    rm -rf $WORK_DIR
    return 1
  fi
}

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

source ~/dev/tool/aws-cli-mfa/clearaws
source ~/dev/tool/aws-cli-mfa/getaws
alias awstoken="getaws default"

alias aws_enc=aws_enc
alias aws_dec=aws_dec

# some more ls aliases
alias vi='vim'
alias ll='ls -alF'
alias lll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep -v grep | grep -i --color'
alias ack='ack -i'
alias gti='git'
alias cp='cp -i'
alias dock='sudo docker'
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
alias gitss='git submodule init && git submodule update'
alias gitpss='git pull && git submodule init && git submodule update'
alias gitmp='git checkout master && gitss'
alias gitmpss='git checkout master && gitpss'
alias getwindowpid='xprop _NET_WM_PID'
alias getms='echo $(($(date +%s%N)/1000000))'
alias diff='diff --color=auto'

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
export JAVA_HOME=~/dev/tool/jdk-current
export GRADLE_HOME=~/dev/tool/gradle-current
export M2_HOME=~/dev/tool/apache-maven-current
export ANT_HOME=~/dev/tool/apache-ant-current
export NODE_HOME=~/dev/tool/node-current
export FIREFOX_HOME=~/dev/tool/firefox-current
export MY_CONF_FILES=~/dev/xma11-projects/my-conf-files
export CLUSTER_SECRET_DIR=/home/xma11/.cluster

export PATH=~/dev/tool/IN_PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin:$M2_HOME/bin:$ANT_HOME/bin:$NODE_HOME/bin:$FIREFOX_HOME:$PATH

#source ~/.aws-conf


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

#source <$(kubectl completion zsh)
kubectl () {
    if [[ -z $KUBECTL_COMPLETE ]]
    then
        source <($commands[kubectl] completion zsh)
        KUBECTL_COMPLETE=1
    fi
    $commands[kubectl] $*
}

