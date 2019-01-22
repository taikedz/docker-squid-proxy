#!/usr/bin/env bash

printhelp() {
    cat <<EOHELP
$0 COMMAND OPTIONS ...
$0 --help

COMMANDs and their OPTIONS :

build
    build the docker image

run SQUIDOPTIONS ...
    run squid, optionally overriding default options

stop
    Stop the squid container

config LOCALCONFIG
    Switch in a config to use; will be mounted at next \`run\`

bash
    run a new container and start bash instead of squid

attach
    attach to existing container

log COMMAND ...
    action to perform on log. This will be carried out as

    COMMAND ... LOGFILE

    where LOGFILE is supplied internally

    e.g.

        $0 log tail -f

test URL [port [server]]
    try to fetch URL from the proxy
    PORT defaults to 3128
    SERVER defaults to localhost

    try also \`test URL | elinks\` to display the formatted page
    if you have elinks

EOHELP

}

die() {
    echo "$*" >&2
    exit 2
}

do_build() {
    docker build -t squid build/
}

do_run() {
    (
        [[ -e "$PWD/live_squid.conf" ]] &&
        [[ ! -d "$PWD/live_squid.conf" ]]
    ) || die "'$PWD/live_squid.conf' not found or not a file."

    local cmd=(
        docker run
        --rm
        -d
        -p 3128:3128 # FIXME .... we should pick this up from the config...
        -v "$PWD/live_squid.conf:/etc/squid3/squid-alt.conf"
        --name squid
        squid
        "$@"
    )
    set -x
    "${cmd[@]}"
}

cmd_log() {
    local cmd
    if [[ -n "$*" ]]; then
        cmd=("$@")
    else
        cmd=(tail -n 50)
    fi

    docker exec -it squid "${cmd[@]}" /var/log/squid/access.log
}

get_curl_as() {
    local c
    declare -n varback="$1"; shift

    for c in curl wget busybox; do
        if which "$c" &>/dev/null ; then
        case "$c" in
        wget)
            varback=(wget -O -)
            ;;
        curl)
            varback=(curl)
            ;;
        busybox)
            varback=(busybox wget -O -)
            ;;
        esac
        fi
        return 0
    done
    return 1
}

test_url() {
    local curl url port server

    if ! get_curl_as curl; then
        die "Could not get valid curl command or fallback"
    fi

    url="${1:-}"; shift || { printhelp; die "URL not specified"; }

    port="${1:-3128}"; shift || :
    server="${1:-localhost}"; shift || :

    (
        export http_proxy="http://$server:${port}"
        export https_proxy="$http_proxy"

        "${curl[@]}" "$url"
    )
}

is_running() {
    docker ps | grep -Pq '\ssquid$'
}

main() {
    cd "$(dirname "$0")"
    local cmd="$1"; shift
    case "$cmd" in
    help|--help)
        printhelp
        ;;
    build)
        do_build
        ;;
    run)
        is_running && die "Container 'squid' is already running"
        do_run "$@"
        ;;
    stop)
        is_running || die "Not running"
        docker stop squid
        ;;
    config)
        is_running && die "Stop squid before switching config"
        [[ -L live_squid.conf ]] && rm live_squid.conf
        ln -s "$1" live_squid.conf
        ;;
    bash)
        is_running && die "Squid is already running. Did you mean 'attach' ?"
        do_run bash
        ;;
    attach)
        is_running || die "Start squid before attaching"
        docker exec -it squid bash
        ;;
    test)
        is_running || die "Start squid before running a test"
        test_url "$@"
        ;;
    log)
        is_running || die "Start squid before checking logs"
        cmd_log "$@"
        ;;
    *)
        echo "Invalid command '$cmd'" >&2
        printhelp
        exit 1
        ;;
    esac
}

main "$@"
