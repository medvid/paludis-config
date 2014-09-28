#CHOST="x86_64-pc-linux-gnu"
CFLAGS="-march=native -pipe -O2"
CXXFLAGS="${CFLAGS}"

case "${CATEGORY}/${PN}" in
    dev-lang/coq)
        scm_user_customize () {
            SCM_REPOSITORY="git://github.com/coq/cog.git"
        }
        ;;
esac

scm_user_customize() {
    # Set SCM_OFFLINE if not connected
    esandbox allow_net --connect "unix:/run/dbus/system_bus_socket" >&/dev/null
    #if ! nmcli -t -f DEVICE,STATE dev | grep :connected$ | grep -v vbox; then
    if [[ $( nmcli -t -f STATE g ) != connected ]]; then
        export SCM_OFFLINE=1
    fi
    esandbox disallow_net --connect "unix:/run/dbus/system_bus_socket" >&/dev/null

    # Call the per-package scm_user_customize hook
    if type scm_user_customize_${CATEGORY}---${PN} >&/dev/null; then
        scm_user_customize_${CATEGORY}---${PN}
    fi
}
