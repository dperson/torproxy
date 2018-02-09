#!/usr/bin/env bash
#===============================================================================
#          FILE: tor-route-all-traffic.sh
#
#         USAGE: ./tor-route-all-traffic.sh
#
#   DESCRIPTION: Route all traffic through a docker tor container
#
#       OPTIONS: ---
#  REQUIREMENTS: running tor docker container
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 2015-07-06 05:59
#      REVISION: 0.1
#===============================================================================

set -euo pipefail                           # Treat unset variables as an error

# Most of this is from
# https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy

### set variables
# destinations you don't want routed through Tor
_non_tor="192.168.1.0/24 192.168.0.0/24"

### get the container tor runs in
_tor_container="$(docker ps | awk '/torproxy/ {print $NF; quit}')"
if [[ "$_tor_container" == "" ]]; then
    echo 'ERROR: you must start a tor proxy container first, IE:'
    echo '    docker run -d --net host --restart always dperson/torproxy'
    exit 1
fi

### get the UID that tor runs as
_tor_uid="$(docker exec $_tor_container id -u tor)"

### Tor's TransPort
_trans_port="9040"
_dns_port="5353"

### flush iptables
iptables -F
iptables -t nat -F

### set iptables *nat to ignore tor user
iptables -t nat -A OUTPUT -m owner --uid-owner $_tor_uid -j RETURN

### redirect all DNS output to tor's DNSPort
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports $_dns_port

### set iptables *filter
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

### allow clearnet access for hosts in $_non_tor
for _clearnet in $_non_tor 127.0.0.0/8; do
   iptables -t nat -A OUTPUT -d $_clearnet -j RETURN
   iptables -A OUTPUT -d $_clearnet -j ACCEPT
done

### redirect all other output to tor's TransPort
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $_trans_port

### allow only tor output
iptables -A OUTPUT -m owner --uid-owner $_tor_uid -j ACCEPT
iptables -A OUTPUT -j REJECT