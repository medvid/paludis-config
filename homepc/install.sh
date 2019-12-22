#!/usr/bin/env bash
set -e

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && source "$( dirname "${BASH_SOURCE[0]}" )/../install.sh"

function install_host_repos() {
    pwd
    ls $REPODIR
    sed -e '/^\(name\|cross_compile_host\)/d' $REPODIR/exndbam/x86_64-pc-linux-gnu.conf > installed.conf
    ln -sfv $REPODIR/exndbam/armv7-unknown-linux-musleabihf.conf
    ln -sfv $REPODIR/exndbam/aarch64-unknown-linux-musleabi.conf
    ln -sfv $REPODIR/exndbam/i686-pc-linux-gnu.conf
    ln -sfv $REPODIR/pbin/pbin-i686-pc-linux-gnu.conf
    sudo mkdir -p /var/db/paludis/repositories/exndbam/{x86_64-pc-linux-gnu,i686-pc-linux-gnu,armv7-unknown-linux-musleabihf,aarch64-unknown-linux-musleabi}
    install_pbin_repo i686-pc-linux-gnu
}

build_paludis_config
