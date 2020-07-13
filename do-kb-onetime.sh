#!/bin/bash

declare -ri _all_trace=${_all_trace:-0}
if (( _all_trace )); then set -x; fi

# This is initial one-time setup on the /rw volume, so does not disappear on virt reboot (hence
# only needs to happen once, or at least once per new virt instance).  After a successful run, the
# install package and signature will end up in $install_dir.
#
# Inputs (all optional)
#   - install_dir: where to cache install files, defaults to $HOME/installs/keybase

_lib_dir=$(cd "$(dirname "$0")"; pwd)
declare -r _lib_dir
# shellcheck source=./do-kb.lib.sh
. "$_lib_dir/do-kb.lib.sh"


# downloads the given url to the current directory as the remote filename
download_file() {
    local -r _url="$1"
    local -r bn=$(basename "$1")

    if [ ! -e "$bn" ]; then
        curl --tlsv1.2 --remote-name-all "$_url"
    else
        : 'already exists, assuming ok (FIXME), later verification will catch if not'
    fi
}


# This function downloads and imports the keybase signing key into the user's gpg keyring and, on
# rpm systems, the system gpg keys.
download_keybase_key() {
    local -r key_file=code_signing_key.asc
    download_file "https://keybase.io/docs/server_security/$key_file"

    # After visual inspection (as of 2018-06-25)
    declare -ri expected_key_file_size=6950
    declare -r expected_key_file_sha512='06c450ee5d65923938fc39bb81d393566dae73c8c86b561e3ade282a144c5564c99027f5606c8810e4b92431ba65a0bee3e146be0d751f166e4ae5c3ff54e4e5'

    echo "Known-good sha512sum: $expected_key_file_sha512"
    echo "Known-good size: $expected_key_file_size"

    # belt-and-suspenders...
    local -ri actual_size=$(stat --format '%s' "$key_file")
    if (( actual_size != expected_key_file_size )); then
        bail "$ERROR_KEY_VERIFICATION_FAILED" \
             "keybase signing key size mismatch, maybe download failed, try rm $install_dir/keybase-*.{deb,rpm}{,.sig}"
    else
        echo "key file size matches"
    fi

    if ! echo "$expected_key_file_sha512 $key_file" | sha512sum --check; then
        bail "$ERROR_KEY_VERIFICATION_FAILED" 'keybase signing key verification failed!'
    else
        echo "key file signature matches"
    fi
    
    echo 'Here are the first 20 lines of the keybase public key file:'
    cat -nA "$key_file" | head -n 20 | head -c 5000
    echo
    echo
    echo 'If the above looks ok, then enter YES (anything else aborts):'
    read -r looks_ok

    # '[' to have simple '=' semantics
    if [ "$looks_ok" = 'YES' ]; then
        echo 'Ok, confirmed'
    else
        bail "$ERROR_NO_CONFIRMATION" 'Uh-oh, aborting!'
    fi

    gpg --import "$key_file"
    if is_deb_based; then
        : 'FIXME: apt-key add, maybe?'
    else
        sudo rpm --import "$key_file"
    fi
}


download_keybase() {
    local kb_url local_name
    kb_url=$(keybase_package_url)
    local_name=$(basename "$kb_url")
    local -r kb_url local_name

    download_file "$kb_url"
    download_file "$kb_url.sig"
    gpg --verify "$local_name.sig" "$local_name"
    if is_deb_based; then
        : 'FIXME: dpkg-sig --verify ..., maybe?'
    else
        rpm --checksig "$local_name"
    fi
}


main() {
    mkdir -p "$install_dir"
    cd "$install_dir"

    download_keybase_key
    download_keybase

    echo 'if the above succeeded, now run do-kb.sh'

    exit $ERROR_NONE
}


main
