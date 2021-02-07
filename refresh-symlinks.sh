#!/bin/sh

fn_link() {
  raw_filename=$1
  full_raw_filename=$(readlink -f $raw_filename)
  full_target_filename="$HOME/${raw_filename//__/\/}"
  filename=$(basename $full_target_filename)
  dir=$(dirname $full_target_filename)
  echo "full_raw=$full_raw_filename, target=$full_target_filename, filename=$filename, dir=$dir"
}

for dotfile in .*; do
  if [[ -f $dotfile ]]; then
    fn_link "$dotfile";
  fi
done

# ln -s

# fonts

