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
antigen bundle gradle
antigen bundle history
antigen bundle kops
antigen bundle mvn
antigen bundle npm
antigen bundle web-search
antigen bundle yarn
antigen bundle z
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme https://github.com/maxiaohao/my-conf-files.git xma
antigen apply

DISABLE_AUTO_UPDATE="true"

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
  if [ "$#" != "3" ]; then
    echo "Usage: appcfg <au|us> <namespace> <service>"
    return 2
  fi
  ENVIRONMENT=$2"_"$1
  NAMESPACE=$2
  SERVICE=$3
  CURRENT_TIME=$(date "+%Y%m%d%H%M%S-%N")
  HISTORY_DIR=~/.appcfg_history
  WORK_DIR=$HISTORY_DIR/$SERVICE"_"$ENVIRONMENT"_"$CURRENT_TIME

  export KUBECONFIG=~/.kube/config-$1
  BASE64_SECRET=$(kubectl get secret $SERVICE-properties -n $NAMESPACE -o jsonpath="{.data.*}")
  if [ "$?" != "0" ]; then
    echo "Failed to fetch appcfg for "$SERVICE" in "$ENVIRONMENT
    return 1
  fi

  mkdir $WORK_DIR -p
  echo $BASE64_SECRET | base64 --decode > $WORK_DIR/application.properties.plain.old

  if [ -f $WORK_DIR/application.properties.plain.old ]; then
    cp -f $WORK_DIR/application.properties.plain.old $WORK_DIR/application.properties.plain.new
    vim $WORK_DIR/application.properties.plain.new
    diff $WORK_DIR/application.properties.plain.old $WORK_DIR/application.properties.plain.new > /dev/null 2>&1
    if [ "$?" != "0" ]; then
      NEW_SECRET=$(cat $WORK_DIR/application.properties.plain.new | base64 | tr -d '\n')
      SECRET_PAYLOAD="---\napiVersion: v1\nkind: Secret\nmetadata:\n  name: $SERVICE-properties\n  namespace: $NAMESPACE\ntype: Opaque\ndata:\n  application-$ENVIRONMENT.properties: $NEW_SECRET"
      echo $SECRET_PAYLOAD | kubectl apply -f -
      if [ "$?" = "0" ]; then
        echo "application.properties for '$SERVICE' in '$ENVIRONMENT' was changed successfully"
        echo "SECRET_PAYLOAD IS:\n$SECRET_PAYLOAD"
      else
        echo "ERROR: failed to upload file"
        return 1
      fi
    else
      echo "Nothing changed"
      rm -rf $WORK_DIR
    fi
    return 0
  else
    echo "application.properties for '$SERVICE' in '$ENVIRONMENT' not found"
    rm -rf $WORK_DIR
    return 1
  fi
}

function push_image() {
  if [ "$#" != "1" ]; then
    echo "usage: push_image <tag>"
    echo "You must run this inside the proper *-service folder."
    return 1
  fi
  SERV_NAME=$(basename "$PWD" | sed 's/-.*//')
  POSTFIX="-service"
  TAG_NAME=$1
  ECR_REPO="674466932943.dkr.ecr.ap-southeast-2.amazonaws.com"
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'

  if [ "$SERV_NAME" == "adconfig" ]; then
    SERV_NAME="campaign"
  fi

  echo -en "Are you sure to make and push docker image ${GREEN}$SERV_NAME$POSTFIX:$TAG_NAME${NC} to ECR? (y/N)"
  read yn
  yn=$(echo $yn | tr "[:upper:]" "[:lower:]")
  if [ "$yn" != "y" -a "$yn" != "yes" ]; then
    return -1
  fi
  sudo $(echo $(aws ecr get-login --region ap-southeast-2) | sed -e 's/-e none //g')
  if [ "$?" != "0" ]; then
    echo -e "${RED}ERROR: Failed to login ECR!${NC}"
    return 1
  fi
  rm -rf tmp
  mkdir -p tmp && cp target/$SERV_NAME$POSTFIX-*.jar tmp/app.jar && cp stage/docker/Dockerfile tmp/Dockerfile
  if [ "$?" != "0" ]; then
    echo -e "${RED}ERROR: Failed to find necessary jar file and Dockerfile!${NC}"
    return 1
  fi
  cd tmp && sudo docker build -t $SERV_NAME$POSTFIX:$TAG_NAME .
  sudo docker tag $SERV_NAME$POSTFIX:$TAG_NAME $ECR_REPO/$SERV_NAME$POSTFIX:$TAG_NAME
  echo "pushing $ECR_REPO/$SERV_NAME$POSTFIX:$TAG_NAME"
  sudo docker push $ECR_REPO/$SERV_NAME$POSTFIX:$TAG_NAME
  PUSH_SUCCESS=$?
  cd ../
  rm -rf tmp
  if [ "$PUSH_SUCCESS" == "0" ]; then
    echo -e "docker image ${GREEN}$SERV_NAME$POSTFIX:$TAG_NAME${NC} pushed successfully"
    return 0
  else
    echo -e "${RED}ERROR: Failed to make and push image!${NC}"
    return 1
  fi
}

function patch_deployment() {
  if [ "$#" != "3" -a "$#" != "2" ]; then
    echo "usage: patch_deployment <env> <deployment> [tag]"
    return 1
  fi
  ECR_REPO="674466932943.dkr.ecr.ap-southeast-2.amazonaws.com"
  SERV_NAME=$2
  POSTFIX="-service"
  TAG_NAME=$3
  ENV=$1
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'

  if [ "$#" == "3" ]; then
    echo -en "Are you sure to patch deployment ${GREEN}$SERV_NAME${NC} with image ${GREEN}$SERV_NAME$POSTFIX:$TAG_NAME${NC} in ${GREEN}$ENV${NC}? (y/N)"
  else
    echo -en "Are you sure to patch deployment ${GREEN}$SERV_NAME${NC} in ${GREEN}$ENV${NC}? (y/N)"
  fi
  read yn
  yn=$(echo $yn | tr "[:upper:]" "[:lower:]")
  if [ "$yn" != "y" -a "$yn" != "yes" ]; then
    return -1
  fi

  if [ "$#" == "3" ]; then
    kubectl patch deployment $SERV_NAME -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$SERV_NAME\",\"image\":\"$ECR_REPO/$SERV_NAME$POSTFIX:$TAG_NAME\"}]},\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}" --namespace $ENV
  else
    kubectl patch deployment $SERV_NAME -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}" --namespace $ENV
  fi
  return $?
}

function deploy_maven_artifact() {
  if [ "$#" != "2" ]; then
    echo "usage: deploy_maven_artifact <project> <version>"
    return 1
  fi
  M2_REPO_PATH="$HOME/.m2/repository"
  PACKAGE_PREFIX="com/citrusad"
  S3_PREFIX="s3://maven.citrusad.com/release"
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'
  if [ -d $M2_REPO_PATH"/"$PACKAGE_PREFIX"/"$1"/"$2"/" ]; then
    echo -en "Are you sure to deploy maven artifact ${GREEN}$1":"$2${NC} to S3? (y/N)"
    read yn
    yn=$(echo $yn | tr "[:upper:]" "[:lower:]")
    if [ "$yn" != "y" -a "$yn" != "yes" ]; then
      return -1
    fi
    aws s3 sync $M2_REPO_PATH"/"$PACKAGE_PREFIX"/"$1"/"$2"/" $S3_PREFIX"/"$PACKAGE_PREFIX"/"$1"/"$2"/"
  else
    echo -e "ERROR: Can't find artifact ${RED}$1":"$2${NC} in local maven repo!"
    return 1
  fi
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
export KUBE_EDITOR="vim"

export PATH=~/dev/tool/IN_PATH:~/dev/xma-projects/my-conf-files:$JAVA_HOME/bin:$GRADLE_HOME/bin:$M2_HOME/bin:$ANT_HOME/bin:$NODE_HOME/bin:$FIREFOX_HOME:$PATH

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
