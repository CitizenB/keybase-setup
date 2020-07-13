#!/bin/bash

declare -ri _all_trace=${_all_trace:-0}
if (( _all_trace )); then set -x; fi

_lib_dir=$(cd "$(dirname "$0")"; pwd)
declare -r _lib_dir
# shellcheck source=./do-kb.lib.sh
. "$_lib_dir/do-kb.lib.sh"

pkg="$install_dir/$(basename "$(keybase_package_url)")"
declare -r pkg

if is_deb_based; then
    sudo apt install "$pkg"
else
    sudo dnf install "$pkg"
fi
run_keybase
