#!/usr/bin/env bash

set -euo pipefail

if ((EUID == 0)); then
  echo "Run this script as your login user, not as root." >&2
  exit 1
fi

for command_name in getent groupadd install kanata modprobe sudo systemctl udevadm usermod; do
  if ! command -v "$command_name" >/dev/null; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
login_user=$(id -un)
service_name=kanata-caps-nav.service

link_file() {
  local source=$1
  local destination=$2

  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -e "$destination" && ! -L "$destination" ]]; then
    echo "Refusing to replace existing file: $destination" >&2
    exit 1
  fi

  ln -sfn -- "$source" "$destination"
  echo "Linked $destination -> $source"
}

ensure_system_group() {
  local group_name=$1

  if ! getent group "$group_name" >/dev/null; then
    sudo groupadd --system "$group_name"
  fi
}

ensure_system_group input
ensure_system_group uinput

sudo usermod -aG input,uinput "$login_user"
sudo modprobe uinput

tmp_dir=$(mktemp -d)
cleanup() {
  rm -f -- "$tmp_dir/kanata.conf" "$tmp_dir/99-kanata-uinput.rules"
  rmdir -- "$tmp_dir"
}
trap cleanup EXIT

printf '%s\n' uinput >"$tmp_dir/kanata.conf"
cat >"$tmp_dir/99-kanata-uinput.rules" <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo install -m 0644 "$tmp_dir/kanata.conf" /etc/modules-load.d/kanata.conf
sudo install -m 0644 "$tmp_dir/99-kanata-uinput.rules" /etc/udev/rules.d/99-kanata-uinput.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

kanata --cfg "$script_dir/caps-nav.kbd" --check

link_file "$script_dir/caps-nav.kbd" "$HOME/.config/kanata/caps-nav.kbd"
link_file "$script_dir/kanata-caps-nav.service" \
  "$HOME/.config/systemd/user/$service_name"

systemctl --user daemon-reload
systemctl --user enable "$service_name"

current_groups=" $(id -nG) "
if [[ "$current_groups" == *" input "* && "$current_groups" == *" uinput "* ]]; then
  systemctl --user restart "$service_name"
  systemctl --user --no-pager --full status "$service_name"
else
  cat <<EOF

Kanata is installed and enabled, but this login session does not yet have the
new input/uinput group memberships. Log out completely and log back in, then run:

  systemctl --user start $service_name
  systemctl --user status $service_name
EOF
fi
