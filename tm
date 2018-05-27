#!/bin/bash
SESS_NAME=$HOSTNAME
if [ -z "$TMUX" ]; then
  tmux has-session -t $SESS_NAME > /dev/null 2>&1
  if [ $? != 0 ]; then
    cd $HOME
    tmux new-session -s $SESS_NAME -d
    for i in {1..10}
    do
      tmux new-window -t $SESS_NAME
    done
    tmux select-window -n -t $SESS_NAME
  fi
  tmux attach -t $SESS_NAME
fi
