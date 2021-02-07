#!/bin/sh

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

for dotfile in .*; do
  if [[ -f $dotfile ]]; then
    fn_link "$dotfile";
  fi
done

# fonts files need to be copied rather than linked
echo "Copying .fonts files and updating fontscache ..."
mkdir -p $HOME/.fonts
\cp -f .fonts/* $HOME/.fonts
fc-cache -f

# copy IN_PATH scripts
mkdir -p $HOME/dev/tool/IN_PATH
echo "Copying IN_PATH scripts ..."
\cp -f IN_PATH/* $HOME/dev/tool/IN_PATH/
