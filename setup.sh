#!/bin/bash

script_dir=$(dirname $(readlink -f setup.sh))

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

# TODO: Investigate why fonts in home dir don't work as expected.
# mkfontdir $HOME/.local/share/fonts

# Workaround: Directly copy fonts into system font dir.
cd $script_dir
FONT_SYS_DIR_MODK="/usr/share/fonts/modk"
sudo mkdir -p $FONT_SYS_DIR_MODK
sudo cp -f *modk*.bdf $FONT_SYS_DIR_MODK/
sudo mkfontdir $FONT_SYS_DIR_MODK

fc-cache -rf
sudo SOURCE_DATE_EPOCH=$(date +%s) fc-cache -rs

#TODO refactor both loops to use fn_link

# copy xkb file to sys folder
echo "Copying xkb files..."
[[ -e /usr/share/X11/xkb/symbols/us.old ]]    || sudo \cp -n /usr/share/X11/xkb/symbols/us    /usr/share/X11/xkb/symbols/us.old
[[ -e /usr/share/X11/xkb/types/iso9995.old ]] || sudo \cp -n /usr/share/X11/xkb/types/iso9995 /usr/share/X11/xkb/types/iso9995.old
sudo \cp -f xkb/symbols/us    /usr/share/X11/xkb/symbols/us
sudo \cp -f xkb/types/iso9995 /usr/share/X11/xkb/types/iso9995

echo "All done!"
