#!/usr/bin/env bash
#===============================================================================
#          FILE: torproxy.sh
#
#         USAGE: ./torproxy.sh
#
#   DESCRIPTION: Entrypoint for torproxy docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### bandwidth: set the BW available for relaying
# Arguments:
#   KiB/s) KiB/s of data that can be relayed
# Return: Updated configuration file
bandwidth() { local kbs="${1:-10}" file=/etc/tor/torrc
    sed -i '/^RelayBandwidth/d' $file
    echo "RelayBandwidthRate $kbs KB" >>$file
    echo "RelayBandwidthBurst $(( kbs * 2 )) KB" >>$file
}

### exitnode: Allow exit traffic
# Arguments:
#   N/A)
# Return: Updated configuration file
exitnode() { local file=/etc/tor/torrc
    sed -i '/^ExitPolicy/d' $file
}

### hidden_service: setup a hidden service
# Arguments:
#   port) port to connect to service
#   host) host:port where service is running
# Return: Updated configuration file
hidden_service() { local port="$1" host="$2" file=/etc/tor/torrc
    sed -i '/^HiddenServicePort '"$port"' /d' $file
    grep -q '^HiddenServiceDir' $file ||
        echo "HiddenServiceDir /var/lib/tor/hidden_service" >>$file
    echo "HiddenServicePort $port $host" >>$file
}

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() { local timezone="${1:-EST5EDT}"
    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified: $timezone" >&2
        return
    }

    if [[ $(cat /etc/timezone) != $timezone ]]; then
        echo "$timezone" >/etc/timezone
        ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
    fi
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -b \"\"       Configure tor relaying bandwidth in KB/s
                possible arg: \"[number]\" - # of KB/s to allow
    -e          Allow this to be an exit node for tor traffic
    -s \"<port>;<host:port>\" Configure tor hidden service
                required args: \"<port>;<host:port>\"
                <port> - port for .onion service to listen on
                <host:port> - destination for service request
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of torproxy
" >&2
    exit $RC
}

cd /tmp

while getopts ":b:es:ht:" opt; do
    case "$opt" in
        h) usage ;;
        b) bandwidth "$OPTARG" ;;
        e) exitnode ;;
        s) eval hidden_service $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${BW:-""}" ]] && bandwidth "$BW"
[[ "${EXITNODE:-""}" ]] && exitnode
[[ "${TZ:-""}" ]] && timezone "$TZ"
[[ "${SERVICE:-""}" ]] && eval hidden_service \
            $(sed 's/^\|$/"/g; s/;/" "/g' <<< $SERVICE)
[[ "${USERID:-""}" =~ ^[0-9]+$ ]] && usermod -u $USERID debian-tor
[[ "${GROUPID:-""}" =~ ^[0-9]+$ ]] && usermod -g $GROUPID debian-tor

chown -Rh debian-tor. /var/lib/tor /var/log/tor 2>&1 | grep -iv 'Read-only' || :

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v 'grep|torproxy.sh' | grep -q tor; then
    echo "Service already running, please restart container to apply changes"
else
    su -l ${TORUSER:-debian-tor} -s /bin/bash -c "exec /usr/bin/tor \
                --defaults-torrc /usr/share/tor/tor-service-defaults-torrc"
    [[ -e /srv/tor/hidden_service/hostname ]] && {
        echo -en "\nHidden service hostname: "
        cat /srv/tor/hidden_service/hostname; echo; }
    exec /usr/sbin/privoxy --user privoxy --no-daemon /etc/privoxy/config
fi
