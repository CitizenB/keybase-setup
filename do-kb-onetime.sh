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
        # Unfortunately, S3 isn't doing TLS 1.3 yet as of early 2023Q2
        curl --tlsv1.2 --remote-name-all "$_url"
    else
        : 'already exists, assuming ok, later verification will catch if not'
    fi
}


# This function downloads and imports the keybase signing key into the user's gpg keyring and, on
# rpm systems, the system gpg keys.
download_keybase_key() {
    local -r key_file=code_signing_key.asc
    download_file "https://keybase.io/docs/server_security/$key_file"

    # From manual inspection (as of 2023-04-08)
    local -ri expected_key_file_size=3106
    local -r expected_key_file_sha512='651b0e59d1d505a54f69e30c0cb7b40fac93b5a93c8fa6552ce01ce7fb186b1343eb3e2063a1a29634af5b05c416dcfc50bdeeec7f33d56d583ec8f76fb27b97'

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
        # FIXME: unused, we just depend on gpg verification, but if we keep this perhaps use
        # /usr/local/share/keyrings instead.
        local -r dearmored_file="${key_file%.asc}.gpg"  # if name does not end in .asc, no big deal
        gpg --dearmor < "$key_file" > "$dearmored_file"
        sudo install "$dearmored_file" /usr/share/keyrings/keybase-archive-keyring.gpg
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
    if ! is_deb_based; then
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
