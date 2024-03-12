#!/bin/bash

function tm() {
  SESS_NAME=$(hostname -s)
  if [ -z "$TMUX" ]; then
    tmux has-session -t $SESS_NAME > /dev/null 2>&1
    if [ $? != 0 ]; then
      cd $HOME
      tmux new-session -s $SESS_NAME -d
      tmux neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; next \; attach
    fi
    tmux attach -t $SESS_NAME
  fi
}

function tm2() {
  SESS_NAME=$HOSTNAME"-2x2"
  if [ -z "$TMUX" ]; then
    tmux has-session -t $SESS_NAME > /dev/null 2>&1
    if [ $? != 0 ]; then
      cd $HOME
      tmux new-session -s $SESS_NAME -d
      tmux splitw \; splitw \; splitw \; selectl tiled \; selectp -t 0 \; attach
    fi
    tmux attach -t $SESS_NAME
  fi
}

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

kms_enc() {
  FILENAME_PREFIX="/tmp/citrus_kms_"
  TIMESTAMP=$(date +'%Y%m%d%H%M%S_%N')
  FILE_PLAIN="${FILENAME_PREFIX}${TIMESTAMP}.plain"
  FILE_CIPHERTEXT="${FILENAME_PREFIX}${TIMESTAMP}.ciphertext"
  echo $1 > $FILE_PLAIN
  gcloud kms encrypt --quiet --project citrus-204206 --location global --keyring citrus --key sharing --plaintext-file $FILE_PLAIN --ciphertext-file $FILE_CIPHERTEXT
  cat $FILE_CIPHERTEXT | base64 -w0
  rm -f $FILE_PLAIN $FILE_CIPHERTEXT
}
kms_dec() {
  FILENAME_PREFIX="/tmp/citrus_kms_"
  TIMESTAMP=$(date +'%Y%m%d%H%M%S_%N')
  FILE_PLAIN="${FILENAME_PREFIX}${TIMESTAMP}.plain"
  FILE_CIPHERTEXT="${FILENAME_PREFIX}${TIMESTAMP}.ciphertext"
  echo $1 | base64 -d > $FILE_CIPHERTEXT
  gcloud kms decrypt --quiet --project citrus-204206 --location global --keyring citrus --key sharing --plaintext-file $FILE_PLAIN --ciphertext-file $FILE_CIPHERTEXT
  cat $FILE_PLAIN
  rm -f $FILE_PLAIN $FILE_CIPHERTEXT
}

function dec_api_key_aws() {
  TMP_BIN_FILE=".tmp.kms.encrypted.bin.$RANDOM"
  echo $1 | xxd -r -p - $TMP_BIN_FILE
  aws kms decrypt --ciphertext-blob fileb://$TMP_BIN_FILE --output text --query Plaintext --region ap-southeast-2 | base64 --decode
  rm -f $TMP_BIN_FILE
}

function dec_api_key() {
  echo $1 | xxd -r -p - | gcloud kms decrypt --location global --keyring citrus --key everything --plaintext-file - --ciphertext-file -
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

function hub_pr() {
  if [ -z $1 ]; then
    echo "usage: hub_pr <title>"
    return 1
  fi
  hub pull-request --browse -m $1
}

function mcd() {
  mkdir -p $1
  cd $1
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

function mypr() {
  [[ -z $1 ]] && (( echo "Usage: gpr <commit_message/pr_title>" && return 1 ))
  git diff --quiet || (( echo "[Exit 1] Working tree is dirty!" && return 1 ))
  gcmsg $1 && gpsup && hub_pr $1
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

pkilled() {
  if [[ ${#1} -le 2 ]]; then
    echo "$1 is too short a process name to kill." && return 1
  fi
  pkill -u $USER $1
  max_loop=20
  force_kill_after=10
  loops=0
  while [[ $loops -lt $max_loop ]]; do
    proc_cnt=$(pgrep -c -u $USER $1)
    loops=$(($loops+1))
    [[ "$proc_cnt" == "0" ]] && return 0
    [[ $loops -gt $force_kill_after ]] && pkill -9 -u $USER $1
    sleep 0.2;
  done
  echo "Failed to kill. Process $1 is still found." && return 1
}

tshow-txt() {
  t show -no-color $1 > $1.txt
}

f() {
  file=$(fzf --preview 'bat --style=numbers --color=always --line-range :100 {}' --bind 'ctrl-j:preview-down,ctrl-k:preview-up')
  [[ "$file" != "" ]] && $EDITOR $file
}

_zsh_autosuggest_strategy_histdb_top() {
    local query="
        select commands.argv from history
        left join commands on history.command_id = commands.rowid
        left join places on history.place_id = places.rowid
        where commands.argv LIKE '$(sql_escape $1)%'
        group by commands.argv, places.dir
        order by places.dir != '$(sql_escape $PWD)', count(*) desc
        limit 1
    "
    suggestion=$(_histdb_query "$query")
}

get_token() {
    identity=$(aws sts get-caller-identity --profile default)
    username=$(echo -- "$identity" | sed -n 's!.*"arn:aws:iam::.*:user/\(.*\)".*!\1!p')
    echo You are: $username >&2

    mfa=$(aws iam list-mfa-devices --user-name "$username" --profile default)
    device=$(echo -- "$mfa" | sed -n 's!.*"SerialNumber": "\(.*\)".*!\1!p')
    echo Your MFA device is: $device >&2
    echo -n "Enter your MFA code now: " >&2
    read code
    tokens=$(aws sts get-session-token --serial-number "$device" --token-code $code --profile default)
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

ZSH_AUTOSUGGEST_STRATEGY=histdb_top
