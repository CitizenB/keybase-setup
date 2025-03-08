#!/bin/bash

# Note: this is sourced not executed, but we keep the shebang line above for shellcheck.

# common settings and initialization
set -o pipefail
set -o errexit

# export (-x) to get rid of shellcheck warnings
declare -rxi \
    ERROR_NONE=0 \
    ERROR_KEY_VERIFICATION_FAILED=1 \
    ERROR_NO_CONFIRMATION=2

declare -r install_dir=${install_dir:-$HOME/installs/keybase}

# These are the latest versions from https://prerelease.keybase.io as of 2025-03-08 (ignoring non-amd64, FIXME)
declare -r version='6.4.0'
declare -r extra_version='20240821175720.3212f60cc5'
declare -rx \
    rpm_url="https://s3.amazonaws.com/prerelease.keybase.io/linux_binaries/rpm/keybase-${version}.${extra_version}-1.x86_64.rpm" \
    deb_url="https://s3.amazonaws.com/prerelease.keybase.io/linux_binaries/deb/keybase_${version}-${extra_version}_amd64.deb"

set -o nounset


# print msg to stderr and exit with the given exit code
bail() {
    local -ri _exit_code="$1"
    local -r _msg="$2"

    echo "$_msg" 1>&2
    exit "$_exit_code"
}


is_deb_based() {
    # FIXME: really crude, just check for something likely to be on a debian-based system.  I
    # suspect rpm is more likely to be found on debian than vice versa, per LSB requirements.
    if type dpkg &>/dev/null ; then
        return 0
    else
        return 1
    fi
}


# print the url of the package appropriate for this OS to stdout
keybase_package_url() {
    if is_deb_based; then
        echo "$deb_url"
    else
        echo "$rpm_url"
    fi
}
