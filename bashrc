CHOST="x86_64-pc-linux-gnu"
CFLAGS="-march=native -pipe -O2"
CXXFLAGS="${CFLAGS}"

scm_user_customize() {
    # Set SCM_OFFLINE if not connected
    esandbox allow_net --connect "unix:/run/dbus/system_bus_socket" >&/dev/null
    if ! networkctl --no-legend | grep routable; then
        export SCM_OFFLINE=1
    fi
    esandbox disallow_net --connect "unix:/run/dbus/system_bus_socket" >&/dev/null
}
