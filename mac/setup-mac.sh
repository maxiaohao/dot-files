#!/bin/bash

set -euo pipefail

script_dir=$(dirname $(readlink -f setup-mac.sh))

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
  rm -f $full_symlink_filename
  mkdir -p $dir
  echo "Refreshing symlink: $full_symlink_filename -> $full_raw_filename ..."
  ln -s $full_raw_filename $full_symlink_filename
}

cd $script_dir

echo -n "Making symlinks for dot files (MacOSX)..." && fn_confirm && \
for dotfile in .*; do
  if [[ -f $dotfile ]]; then
    fn_link "$dotfile";
  fi
done

cd $script_dir

echo "Done!"
