#!/usr/bin/env bash
set -e

function build_paludis_config()
{
    HOSTDIR="$( cd "$( dirname "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )" >/dev/null 2>&1 && pwd )"
    CONFDIR="$HOSTDIR/paludis"
    ROOTDIR=../..
    REPODIR=../../../repositories

    HOST="$(basename "$HOSTDIR")"
    DESTDIR=$([[ ${ALL_HOSTS:-} == 1 ]] && echo "/etc/paludis-$HOST" || echo "/etc/paludis")

    mkdir -p "$CONFDIR"
    pushd "$CONFDIR"
    ln -sfv $ROOTDIR/licences.conf
    ln -sfv $ROOTDIR/mirrors.conf
    ln -sfv $ROOTDIR/options.conf
    ln -sfv $ROOTDIR/output.conf
    ln -sfv $ROOTDIR/package_unmask.conf
    ln -sfv $ROOTDIR/package_mask.conf
    ln -sfv $ROOTDIR/platforms.conf
    ln -sfv $ROOTDIR/repository_defaults.conf
    ln -sfv $ROOTDIR/repository.template
    ln -sfv $ROOTDIR/suggestions.conf
    ln -sfv ../bashrc
    ln -sfv ../world
    echo "world = \${root}$DESTDIR/world" > general.conf

    mkdir -p hooks/sync_all_post
    pushd hooks/sync_all_post
    ln -sfv ../../$ROOTDIR/index.bash
    popd

    mkdir -p options.conf.d
    pushd options.conf.d
    ln -sfv ../$ROOTDIR/jobs.conf
    ln -sfv ../$ROOTDIR/test.conf
    ln -sfv ../$ROOTDIR/zzz.conf
    ln -sfv ../../options.conf $HOST.conf
    popd

    if [[ -f ../package_mask.conf ]]; then
        mkdir -p package_mask.conf.d
        pushd package_mask.conf.d
        ln -sfv ../../package_mask.conf $HOST.conf
        popd
    fi

    mkdir -p repositories
    pushd repositories
    ln -sfv $REPODIR/accounts.conf
    ln -sfv $REPODIR/graveyard.conf
    ln -sfv $REPODIR/installed_accounts.conf
    ln -sfv $REPODIR/repository.conf
    ln -sfv $REPODIR/unavailable-unofficial.conf
    ln -sfv $REPODIR/unavailable.conf
    ln -sfv $REPODIR/unpackaged.conf
    ln -sfv $REPODIR/unwritten.conf
    ln -sfv ../../arbor.conf

    if ! [[ -e "$DESTDIR" ]]; then
        echo "$CONFDIR -> $DESTDIR"
        sudo ln -sT "$CONFDIR" "$DESTDIR"
    fi

    install_host_repos

    set +e
    for e in $REPODIR/e/*.conf; do
        local repo=$(basename $e .conf)
        if ! [[ -d /var/db/paludis/repositories/e/$repo ]]; then
            echo "resolve repository/$repo"
            sudo cave resolve -x1 repository/$repo
        fi
        [[ -e $repo.conf ]] && ! [[ -L $repo.conf  ]] && rm -vf $repo.conf
        [[ -d /var/db/paludis/repositories/e/$repo ]] && ln -svf $e
    done
    set -e
    popd
    popd

    return 0
}

function install_pbin_repo()
{
    local repo_name=$1
    local repo_path=/var/db/paludis/repositories/pbin/$repo_name
    if ! [[ -d $repo_path ]]; then
        sudo mkdir -p $repo_path/{metadata,packages,profiles}
        sudo sh -c "echo pbin-$repo_name > $repo_path/profiles/repo_name"
        sudo touch $repo_path/{profiles/options.conf,metadata/categories.conf}
        sudo cave fix-cache
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    export ALL_HOSTS=1
    ./musl/install.sh
    ./pinebook/install.sh
    ./cubie/install.sh
    unset ALL_HOSTS
fi
