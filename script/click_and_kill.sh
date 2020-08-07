#!/bin/bash
pid=$(xprop _NET_WM_PID | awk '{print $3}')
kill -9 $pid
