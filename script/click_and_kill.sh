#!/bin/bash
pid=$(xprop _NET_WM_PID | awk '{print $3}')
zenity --question --text="Force kill pid $pid?" && kill -9 $pid
