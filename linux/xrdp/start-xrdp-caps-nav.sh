#!/usr/bin/env bash

set -euo pipefail

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(dirname -- "$script_path")

xmodmap "$script_dir/xrdp-caps-nav.Xmodmap"
