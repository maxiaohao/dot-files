#!/bin/bash

# reset kernel module hid_logitech_dj after waking from a suspension
if [[ $1 == post ]]; then
  echo "[$(date)] Resetting kernel module hid_logitech_dj..." > /var/log/custom_systemd.log
  rmmod hid_logitech_dj
  modprobe hid_logitech_dj
  echo "[$(date)] Finished resetting kernel module hid_logitech_dj." > /var/log/custom_systemd.log
fi
