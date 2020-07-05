#!/bin/bash

# disable hook execution while running cave sync with params
[[ -n ${CAVE_SYNC_CMDLINE_PARAMS} ]] && exit

source "${PALUDIS_EBUILD_DIR}/echo_functions.bash"

ebegin "Generate metadata"
cave generate-metadata
eend $?

ebegin "Update search index"
cave manage-search-index --create /var/cache/paludis/search-index
eend $?
