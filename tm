#! /bin/bash
SESS_NAME=$HOSTNAME

if [ -z "$TMUX" ]; then

    tmux has-session -t $SESS_NAME > /dev/null 2>&1

    if [ $? != 0 ]; then
        tmux new-session -s $SESS_NAME -d
    fi

    tmux attach -t $SESS_NAME
fi
