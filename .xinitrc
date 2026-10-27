if [ -n "${XRDP_SESSION:-}" ]; then
  display_number=${DISPLAY#:}
  display_number=${display_number%%.*}
  systemctl --user start "xrdp-caps-nav@${display_number}.service"
fi

export XCURSOR_SIZE=72
export XCURSOR_THEME=DMZ-White
xrdb -merge "$HOME/.Xresources"
exec dbus-run-session -- startlxde
