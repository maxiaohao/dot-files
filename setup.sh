#!/bin/bash

set -euo pipefail

script_dir=$(dirname $(readlink -f setup.sh))

fn_confirm() {
  printf "Yes/No/Abort? [default=No] "
  read -r yna
  yna=$(echo "$yna" | tr "[:upper:]" "[:lower:]")
  # shellcheck disable=SC2166
  if [ "$yna" = "y" -o "$yna" = "yes" ]; then
    return 0
  elif [ "$yna" = "a" -o "$yna" = "abort" ]; then
    echo "Aborted"
    exit 1
  else
    echo "Skipped"
    return 1
  fi
}

fn_link() {
  raw_filename=$1
  full_raw_filename=$(readlink -f $raw_filename)
  full_symlink_filename="$HOME/${raw_filename//__/\/}"
  filename=$(basename $full_symlink_filename)
  dir=$(dirname $full_symlink_filename)
  # echo "full_raw=$full_raw_filename, symlink=$full_symlink_filename, filename=$filename, dir=$dir"
  rm -rf $full_symlink_filename
  mkdir -p $dir
  echo "Refreshing symlink: $full_symlink_filename -> $full_raw_filename ..."
  ln -s $full_raw_filename $full_symlink_filename
}

fn_setup_user_systemd_service() {
  raw_filename=$1
  full_raw_filename=$(readlink -f $raw_filename)
  full_new_filename="$HOME/${raw_filename//__/\/}"
  filename=$(basename $full_new_filename)
  dir=$(dirname $full_new_filename)
  rm -f $full_new_filename
  mkdir -p $dir
  echo "Copying: $full_raw_filename to $full_new_filename ..."
  \cp -f $full_raw_filename $full_new_filename
  systemctl --user enable $filename
  systemctl --user restart $filename
}


cd $script_dir

echo -n "Making symlinks for dot files..." && fn_confirm && \
for dotfile in .*; do
  if [[ -e $dotfile && $dotfile != ".git" ]]; then
    fn_link "$dotfile";
  fi
done


echo -n "Setting up user systemd service files.." && fn_confirm && \
for dotfile in .config__systemd__user__*; do
  if [[ -f $dotfile ]]; then
    fn_setup_user_systemd_service "$dotfile";
  fi
done


echo -n "Making symlinks for IN_PATH scripts..." && fn_confirm && \
if [[ -d IN_PATH ]]; then
  full_in_path=$HOME/dev/tool/IN_PATH
  mkdir -p $full_in_path
  cd IN_PATH
  for filename in *; do
    if [[ -f $filename ]]; then
      full_raw_filename=$(readlink -f $filename)
      full_symlink_filename=$full_in_path/$filename
      echo "Refreshing symlink: $full_symlink_filename -> $full_raw_filename ..."
      rm -f $full_symlink_filename
      ln -s $full_raw_filename $full_symlink_filename
    fi
  done
fi

# # TODO: Investigate why fonts in home dir don't work as expected.
# # mkfontdir $HOME/.local/share/fonts
#
# #TODO refactor both loops to use fn_link
#
# # Workaround: Directly copy fonts into system font dir.
# echo -n "Copying fonts..." && fn_confirm \
# && cd $script_dir \
# && FONT_SYS_DIR_MODK="/usr/share/fonts/modk" \
# && sudo mkdir -p $FONT_SYS_DIR_MODK \
# && sudo cp -f *modk*.bdf $FONT_SYS_DIR_MODK/ \
# && sudo mkfontdir $FONT_SYS_DIR_MODK \
# && fc-cache -rf \
# && sudo SOURCE_DATE_EPOCH=$(date +%s) fc-cache -rs


cd $script_dir

echo -n "Copying xkb files..." && fn_confirm && \
[[ -e /usr/share/X11/xkb/symbols/us.old ]]    || sudo \cp -n /usr/share/X11/xkb/symbols/us    /usr/share/X11/xkb/symbols/us.old; \
[[ -e /usr/share/X11/xkb/types/iso9995.old ]] || sudo \cp -n /usr/share/X11/xkb/types/iso9995 /usr/share/X11/xkb/types/iso9995.old; \
sudo \cp -f xkb/symbols/us    /usr/share/X11/xkb/symbols/us; \
sudo \cp -f xkb/types/iso9995 /usr/share/X11/xkb/types/iso9995


echo -n "Copying custom systemd sleep files..." && fn_confirm && \
sudo \cp -f root__lib__systemd__system-sleep__reset_mod_hid_logitech_dj.sh /lib/systemd/system-sleep/reset_mod_hid_logitech_dj.sh && \
sudo chmod a+x /lib/systemd/system-sleep/reset_mod_hid_logitech_dj.sh


echo "Done!"
