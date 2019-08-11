export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

source /home/xma11/dev/tool/antigen/antigen.zsh
antigen use oh-my-zsh
antigen bundle autojump
antigen bundle aws
antigen bundle colored-man-pages
antigen bundle docker
antigen bundle docker-compose
antigen bundle git
antigen bundle golang
#antigen bundle gradle
#antigen bundle history
#antigen bundle kops
antigen bundle mvn
antigen bundle npm
antigen bundle web-search
antigen bundle yarn
antigen bundle z
antigen bundle shrink-path
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme https://github.com/maxiaohao/my-conf-files.git xma
antigen apply

DISABLE_AUTO_UPDATE="true"

# completion
if [ -d ~/.zsh/completion ]; then
  fpath=(~/.zsh/completion $fpath)
  autoload -U compinit
  compinit
fi

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

function dec_api_key() {
  TMP_BIN_FILE=".tmp.kms.encrypted.bin.$RANDOM"
  echo $1 | xxd -r -p - $TMP_BIN_FILE
  aws kms decrypt --ciphertext-blob fileb://$TMP_BIN_FILE --output text --query Plaintext --region ap-southeast-2 | base64 --decode
  rm -f $TMP_BIN_FILE
}

function jqf() {
   echo $1 | jq .
}

function list_ecr_images() {
  if [ -z $1 ]; then
    echo "usage: list_ecr_images <repo>"
    return 1
  fi
  aws ecr describe-images --query 'sort_by(imageDetails,& imagePushedAt)[*]' --repository-name $1-service
}

#source ~/dev/tool/aws-cli-mfa/clearaws
#source ~/dev/tool/aws-cli-mfa/getaws
#alias awstoken="getaws default"
awstoken() {
  identity=$(aws sts get-caller-identity --profile original)
  username=$(echo -- "$identity" | sed -n 's!.*"arn:aws:iam::.*:user/\(.*\)".*!\1!p')
  echo You are: $username >&2

  mfa=$(aws iam list-mfa-devices --user-name "$username" --profile original)
  device=$(echo -- "$mfa" | sed -n 's!.*"SerialNumber": "\(.*\)".*!\1!p')
  echo Your MFA device is: $device >&2
  echo -n "Enter your MFA code now: " >&2
  read code
  tokens=$(aws sts get-session-token --serial-number "$device" --token-code $code --profile original)
  secret=$(echo -- "$tokens" | sed -n 's!.*"SecretAccessKey": "\(.*\)".*!\1!p')
  session=$(echo -- "$tokens" | sed -n 's!.*"SessionToken": "\(.*\)".*!\1!p')
  access=$(echo -- "$tokens" | sed -n 's!.*"AccessKeyId": "\(.*\)".*!\1!p')
  expire=$(echo -- "$tokens" | sed -n 's!.*"Expiration": "\(.*\)".*!\1!p')
  TEMP=$(uuidgen)
  sed -n 1,3p ~/.aws/credentials >~/.$TEMP
  echo "[default]" >>~/.$TEMP
  echo "aws_access_key_id=$access" >>~/.$TEMP
  echo "aws_secret_access_key=$secret" >>~/.$TEMP
  echo "aws_session_token=$session" >>~/.$TEMP

  mv ~/.$TEMP ~/.aws/credentials

  echo Keys valid until $expire >&2

  # login ecr
  $(echo $(aws ecr get-login --region ap-southeast-2) | sed -e 's/-e none //g')
}

alias gcmsg 2>/dev/null >/dev/null && unalias gcmsg
gcmsg() {
  repo_name=$(basename $(git rev-parse --show-toplevel))
  if [[ "$?" != "0" ]]; then
    return $?
  fi
  # prepend sub-project name to the git commit message only if we are in sub-prodjct in mono repo
  prefix_msg=""
  if [[ ! -d $PWD/.git && ( "$repo_name" == "commons" || "$repo_name" == "mono-project" ) ]]; then
    last_dir=$PWD
    dir=$PWD/..
    while [[ ! -d $dir/.git ]]; do
      if [[ "$(readlink -f $dir)" == "/" ]]; then
        break
      fi
      last_dir=$dir
      dir=$dir/..
    done

    sub_project_name=$(basename $(readlink -f $last_dir))
    if [[ -n $sub_project_name && "$sub_project_name" != "/" ]]; then
      prefix_msg="["$(echo $sub_project_name | tr a-z A-Z)"] "
    fi
  fi
  git commit -m $prefix_msg$1
}

gdl() {
	if [[ "$#" -eq 1 || "$#" -eq 2 ]]; then
		GDL_CMD="./gradlew"
		GDL_OPTS="--no-daemon --no-build-cache"
	  SUB_PROJ_PREFIX=""
	  if [[ "$#" -eq 2 ]]; then
	    SUB_PROJ_PREFIX=":"$2":"
	  fi
    case $1 in
	    c)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean"
	      ;;
	    cc)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean ${SUB_PROJ_PREFIX}compileJava"
	      ;;
	    ct)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean ${SUB_PROJ_PREFIX}test"
	      ;;
	    cb)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean ${SUB_PROJ_PREFIX}build"
	      ;;
	    cj)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean ${SUB_PROJ_PREFIX}jib"
	      ;;
	    lq)
        bash -c "$GDL_CMD $GDL_OPTS ${SUB_PROJ_PREFIX}clean ${SUB_PROJ_PREFIX}diffChangeLog"
	      ;;
	    *)
	      echo "Usage: gdl <c|cc|ct|cb|cj> [sub_project_name]"
    esac
  else
	  echo "Usage: gdl <c|cc|ct|cb|cj> [sub_project_name]"
  fi
}

alias aws_enc=aws_enc
alias aws_dec=aws_dec

# more aliases
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
export MY_CONF_FILES=~/dev/xma11-projects/my-conf-files
export CLUSTER_SECRET_DIR=/home/xma11/.cluster
export KUBE_EDITOR="vim"
export GOPATH=~/dev/tool/go_path
export PROMPT_EOL_MARK=""

#export PATH=~/dev/tool/IN_PATH:~/dev/xma-projects/my-conf-files:$JAVA_HOME/bin:$GRADLE_HOME/bin:$M2_HOME/bin:$ANT_HOME/bin:$NODE_HOME/bin:$FIREFOX_HOME:$GOPATH/bin:$PATH
export PATH=~/dev/tool/IN_PATH:~/dev/xma-projects/my-conf-files:$FIREFOX_HOME:$GOPATH/bin:$PATH

export PATH="$PATH:$HOME/.rvm/bin"

kubectl () {
    if [[ -z $KUBECTL_COMPLETE ]]
    then
        source <($commands[kubectl] completion zsh)
        KUBECTL_COMPLETE=1
    fi
    $commands[kubectl] $*
}

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

true
