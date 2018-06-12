#!/bin/bash
SESS_NAME=$HOSTNAME
if [ -z "$TMUX" ]; then
  tmux has-session -t $SESS_NAME > /dev/null 2>&1
  if [ $? != 0 ]; then
    cd $HOME
    tmux new-session -s $SESS_NAME -d
    tmux neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; neww \; next \; attach
  fi
  tmux attach -t $SESS_NAME
fi
