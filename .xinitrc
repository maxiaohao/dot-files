#!/bin/sh

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS="@im=ibus"

#export GTK_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx
#export XMODIFIERS="@im=fcitx"

#/usr/bin/i3

# for fix flameshot
#exec dbus-launch /usr/bin/i3

# normal i3
#exec /usr/bin/i3
exec /usr/bin/i3 >~/tmp/i3log-$(date +'%F-%k-%M-%S') 2>&1
