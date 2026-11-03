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
  keymap=$(xmodmap -pke 2>/dev/null)
  modifiers=$(xmodmap -pm 2>/dev/null)

  if ! grep -Eq \
      '^keycode +66 = (Mode_switch|ISO_Group_Shift) .* (Mode_switch|ISO_Group_Shift)' <<<"$keymap" ||
    ! grep -Eq '^keycode +43 = h H Left Left' <<<"$keymap" ||
    ! grep -Eq '^keycode +26 = e E End End' <<<"$keymap" ||
    ! grep -Eq '^mod5 .*ISO_Group_Shift \(0x42\)' <<<"$modifiers"; then
    xmodmap "$map_file" || true
  fi

  sleep 2
done
