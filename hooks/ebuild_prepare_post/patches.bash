# vim: set sw=4 sts=4 et :

(
    cd "${WORKDIR}"
    patchdir="/etc/paludis/patches/${CATEGORY}/${PN}"
    if [[ -d $patchdir ]] ; then
        einfo "Applying user patches"
        for p in $patchdir/*.patch ; do
            [[ -f "${p}" ]] || continue
            einfo "Applying $(basename ${p} )"
            patch -p1 < ${p} || exit 1
        done
        einfo "Done"
    fi
)
