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

### nickname: the name of the relay node
# Arguments:
#   nick) the name of the relay node
# Return: Updated configuration file
nickname() { local nick="$1" file=/etc/tor/torrc
  sed -i '/^Nickname/d' $file
  echo "Nickname $nick" >>$file
}

### contact_info: set the contact email address to get
# notified about down time by the tor weather service
# if the relay node goes offline for more than 48 hours
# Arguments:
#   email) the email to contact the node operator through
# Return: Updated configuration file
contact_info() { local email="$1" file=/etc/tor/torrc
  sed -i '/^ContactInfo/d' $file
  echo "ContactInfo $email" >>$file
}

### dir_port: enable and set port for directory listing
# Arguments:
#   port) the port to use for directory listing
# Return: Updated configuration file
dir_port() { local port="$1" file=/etc/tor/torrc
  sed -i '/^DirPort/d' $file
  echo "DirPort $port" >>$file
}

### dir_port: enable and set port for onion relay
# Arguments:
#   port) the port to use for onion relay
# Return: Updated configuration file
or_port() { local port="$1" file=/etc/tor/torrc
  sed -i '/^ORPort/d' $file
  echo "ORPort $port" >>$file
}

### exitnode: Allow exit traffic
# Arguments:
#   N/A)
# Return: Updated configuration file
exitnode() { local file=/etc/tor/torrc
    sed -i '/^ExitPolicy/d' $file
}

### exitnode_country: Only allow traffic to exit in a specified country
# Arguments:
#   country) country where we want to exit
# Return: Updated configuration file
exitnode_country() { local country="$1" file=/etc/tor/torrc
    sed -i '/^StrictNodes/d; /^ExitNodes/d' $file
    echo "StrictNodes 1" >>$file
    echo "ExitNodes {$country}" >>$file
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

### newnym: setup new circuits
# Arguments:
#   N/A)
# Return: New circuits for tor connections
newnym() { local file=/etc/tor/run/control.authcookie
    echo -e 'AUTHENTICATE "'"$(cat $file)"'"\nSIGNAL NEWNYM\nQUIT' |
                nc 127.0.0.1 9051
    if ps -ef | egrep -v 'grep|torproxy.sh' | grep -q tor; then exit 0; fi
}

### password: setup a hashed password
# Arguments:
#   passwd) passwd to set
# Return: Updated configuration file
password() { local passwd="$1" file=/etc/tor/torrc
    sed -i '/^HashedControlPassword/d' $file
    sed -i '/^ControlPort/s/ 9051/ 0.0.0.0:9051/' $file
    echo "HashedControlPassword $(su - tor -s/bin/bash -c \
                "tor --hash-password '$passwd' |tail -n 1")" >>$file 2>/dev/null
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC="${1:-0}"
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -b \"\"       Configure tor relaying bandwidth in KB/s
                possible arg: \"[number]\" - # of KB/s to allow
    -e          Allow this to be an exit node for tor traffic
    -l \"<country>\" Configure tor to only use exit nodes in specified country
                required args: \"<country>\" (IE, "US" or "DE")
                <country> - country traffic should exit in
    -n          Generate new circuits now
    -i \"<nick>\" Nickname of the relay node
    -c \"<info>\" Set contact info for the relay node
    -r \"<dirport>\" Enable and set port for directory mirroring
                (DirPort, port 9030)
    -o \"<orport>\"  Enable and set port for onion relay
                (ORPort, port 9001)
    -p \"<password>\" Configure tor HashedControlPassword for control port
    -s \"<port>;<host:port>\" Configure tor hidden service
                required args: \"<port>;<host:port>\"
                <port> - port for .onion service to listen on
                <host:port> - destination for service request

The 'command' (if provided and valid) will be run instead of torproxy
" >&2
    exit $RC
}

while getopts ":hb:el:np:s:i:c:r:o:" opt; do
    case "$opt" in
        h) usage ;;
        b) bandwidth "$OPTARG" ;;
        e) exitnode ;;
        l) exitnode_country "$OPTARG" ;;
        n) newnym ;;
        i) nickname "$OPTARG" ;;
        c) contact_info "$OPTARG" ;;
        r) dir_port "$OPTARG" ;;
        o) or_port "$OPTARG" ;;
        p) password "$OPTARG" ;;
        s) eval hidden_service $(sed 's/^/"/; s/$/"/; s/;/" "/g' <<< $OPTARG) ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${BW:-""}" ]] && bandwidth "$BW"
[[ "${EXITNODE:-""}" ]] && exitnode
[[ "${LOCATION:-""}" ]] && exitnode_country "$LOCATION"
[[ "${PASSWORD:-""}" ]] && password "$PASSWORD"
[[ "${NICKNAME:-""}" ]] && nickname "$NICKNAME"
[[ "${CONTACT_INFO:-""}" ]] && contact_info "$CONTACT_INFO"
[[ "${DIR_PORT:-""}" ]] && dir_port "$DIR_PORT"
[[ "${OR_PORT:-""}" ]] && or_port "$OR_PORT"
[[ "${SERVICE:-""}" ]] && eval hidden_service \
            $(sed 's/^/"/; s/$/"/; s/;/" "/g' <<< $SERVICE)
[[ "${USERID:-""}" =~ ^[0-9]+$ ]] && usermod -u $USERID -o tor
[[ "${GROUPID:-""}" =~ ^[0-9]+$ ]] && groupmod -g $GROUPID -o tor
for env in $(printenv | grep '^TOR_'); do
    name="$(cut -c5- <<< ${env%%=*})"
    val="\"${env##*=}\""
    [[ "$name" =~ _ ]] && continue
    [[ "$val" =~ ^\"([0-9]+|false|true)\"$ ]] && val="$(sed 's|"||g' <<< $val)"
    if grep -q "^$name" /etc/tor/torrc; then
        sed -i "/^$name/s| .*| $val|" /etc/tor/torrc
    else
        echo "$name $val" >>/etc/tor/torrc
    fi
done

chown -Rh tor. /etc/tor /var/lib/tor /var/log/tor 2>&1 |
            grep -iv 'Read-only' || :

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v 'grep|torproxy.sh' | grep -q tor; then
    echo "Service already running, please restart container to apply changes"
else
    [[ -e /srv/tor/hidden_service/hostname ]] && {
        echo -en "\nHidden service hostname: "
        cat /srv/tor/hidden_service/hostname; echo; }
    /usr/sbin/privoxy --user privoxy /etc/privoxy/config
    exec /usr/bin/tor
fi