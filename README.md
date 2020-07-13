# TL;DR

`make run`, or, if you do not have `make`, just manually run `./do-kb-onetime.sh && ./do-kb.sh`.


# Overview

Very lightweight [keybase](https://keybase.io) bootstrapping.  Assumes you have sudo privileges.  Out of an abundance of
paranoia, this is interactive, prompting before importing keybase's public key into the user's gpg
keyring.


# Files

  - `do-kb-onetime.sh`:  A one-time setup which downloads and verifies the install bits.

  - `do-kb.sh`:  An "every-boot" setup for when you are running on a node where you lose non-user
    changes on each boot (so, for example, `$HOME/` is preserved, but `/usr/bin` is reset).  Run
    this on reboot to re-install the already downloaded and verified package.

    If you are not in this situation, then `do-kb.sh` changes will stick around and you do not need
    to re-run on each boot.

  - `do-kb.lib.sh`: code shared between other scripts


# Dependencies

## Run-time

  - `sha512sum` (in package `coreutils`)
  - `bash`
  - `curl`
  - `gpg`
  - `sudo`


## Dev-time

  - `make`
  - `shellcheck`


# FIXME

  - Decide on a license
  - Test via BATS and/or molecule?
  - Works better on rpm-based distros
  - These scripts need to run partly as root; an unprivileged option would be nice too.


# References

  - [Upstream docs](https://keybase.io/docs/the_app/install_linux)
  - [Running unprivileged](https://book.keybase.io/guides/linux#installing-keybase-without-root-privileges)
