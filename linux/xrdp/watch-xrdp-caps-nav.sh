#!/usr/bin/env bash

set -u

if (($# != 1)) || [[ ! $1 =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 DISPLAY_NUMBER" >&2
  exit 2
fi

export DISPLAY=":$1"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(dirname -- "$script_path")
map_file="$script_dir/xrdp-caps-nav.Xmodmap"

while xdpyinfo >/dev/null 2>&1; do
  if ! xmodmap -pke 2>/dev/null |
    grep -Eq '^keycode +66 = Mode_switch .*Mode_switch' ||
    ! xmodmap -pke 2>/dev/null |
      grep -Eq '^keycode +43 = h H Left Left' ||
    ! xmodmap -pke 2>/dev/null |
      grep -Eq '^keycode +26 = e E End End'; then
    xmodmap "$map_file" || true
  fi

  sleep 2
done
