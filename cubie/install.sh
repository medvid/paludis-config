#!/usr/bin/env bash
set -e

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && source "$( dirname "${BASH_SOURCE[0]}" )/../install.sh"

function install_host_repos() {
    sed -e '/^\(name\|cross_compile_host\)/d' $REPODIR/exndbam/armv7-unknown-linux-musleabihf.conf > installed.conf
    ln -sfv $REPODIR/pbin/pbin-armv7-unknown-linux-musleabihf.conf
}

build_paludis_config
