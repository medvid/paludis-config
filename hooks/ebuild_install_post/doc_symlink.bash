#!/usr/bin/env bash

source "${PALUDIS_EBUILD_DIR}/echo_functions.bash"

function verify_dir()
{
    if [ -n "${IMAGE}" ]; then
        # Make sure we have smth real in `IMAGE'!
        local p1=`realpath -mq "${1}"`
        local p2=`realpath -mq "${IMAGE}/$1"`
        if [ "${p1}" != "${p2}" ]; then
            return 0
        fi
    fi
    return 1
}

# @param cd  -- directory to change to before making a symlink
# @param src -- source name
# @param dst -- destination name
#
function cmd_symlink()
{
    local cd="$1"
    local src="$2"
    local dst="$3"

    if ! verify_dir "${cd}"; then
        eerror "Package image dir is undefined! Skip any actions..."
        return
    fi

    if [ -d "${IMAGE}/$cd" ]; then
        #ebegin "Making the symlink [$cd]: $src --> $dst"
        cd "${IMAGE}/$cd" \
          && ln -s $src $dst \
          && cd - >/dev/null
        #eend $?
    fi
}

cmd_symlink "/usr/share/doc/" "${PNVR}" "${PN}"
