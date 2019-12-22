#!/usr/bin/env bash
set -e

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && source "$( dirname "${BASH_SOURCE[0]}" )/../install.sh"

function install_host_repos() {
    sed -e '/^\(name\|cross_compile_host\)/d' $REPODIR/exndbam/x86_64-pc-linux-musl.conf > installed.conf
    ln -sfv $REPODIR/pbin/pbin-x86_64-pc-linux-musl.conf
}

build_paludis_config
