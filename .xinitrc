#!/bin/sh

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS="@im=ibus"

# No use in .xinitrc
#[[ -h "$HOME/.Xmodmap" ]] && xmodmap $HOME/.Xmodmap

#export GTK_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx
#export XMODIFIERS="@im=fcitx"

#/usr/bin/i3

# for fix flameshot
#exec dbus-launch /usr/bin/i3

# load .Xresources after xorg and BEFORE i3 for correct cursor size
[[ -s "$HOME/.Xresources" ]] && xrdb $HOME/.Xresources

xset +fp $HOME/.local/share/fonts

mkdir -p $HOME/tmp/i3_log
DISPLAY_NUM=$(echo ${DISPLAY} | cut -c2-)
TIMESTAMP_STR=$(date +'%F_%H%M%S')

# exec /usr/bin/i3 >$HOME/tmp/i3_log/i3.${TIMESTAMP_STR}.${USER}.display${DISPLAY_NUM}.log 2>&1
exec dbus-launch /usr/bin/i3 >$HOME/tmp/i3_log/i3.${TIMESTAMP_STR}.${USER}.display${DISPLAY_NUM}.log 2>&1

