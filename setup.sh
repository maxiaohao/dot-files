#!/bin/bash

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

cd $(dirname $0)

# make symlinks for dot files
for dotfile in .*; do
  if [[ -f $dotfile ]]; then
    fn_link "$dotfile";
  fi
done

# make symlinks for IN_PATH scripts
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

fc-cache -rf

#TODO refactor both loops to use fn_link
