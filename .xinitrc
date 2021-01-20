#!/bin/sh

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS="@im=ibus"

[[ -s "$HOME/.Xmodmap" ]] && xmodmap $HOME/.Xmodmap

#export GTK_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx
#export XMODIFIERS="@im=fcitx"

#/usr/bin/i3

# for fix flameshot
#exec dbus-launch /usr/bin/i3

# load .Xresources after xorg and BEFORE i3 for correct cursor size
[[ -s "$HOME/.Xresources" ]] && xrdb $HOME/.Xresources

# normal i3
mkdir -p $HOME/tmp/i3_log
exec /usr/bin/i3 >$HOME/tmp/i3_log/i3.log.${USER}.$(date +'%F_%k%M%S') 2>&1
