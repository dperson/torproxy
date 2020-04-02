[![logo](https://raw.githubusercontent.com/dperson/torproxy/master/logo.png)](https://torproject.org/)

# Tor and Privoxy

Tor and Privoxy (web proxy configured to route through tor) docker container

# What is Tor?

Tor is free software and an open network that helps you defend against traffic
analysis, a form of network surveillance that threatens personal freedom and
privacy, confidential business activities and relationships, and state security.

# What is Privoxy?

Privoxy is a non-caching web proxy with advanced filtering capabilities for
enhancing privacy, modifying web page data and HTTP headers, controlling access,
and removing ads and other obnoxious Internet junk.

---

# How to use this image

**NOTE 1**: this image is setup by default to be a relay only (not an exit node)

**NOTE 2**: this image now supports relaying all traffic through the container,
see: [tor-route-all-traffic.sh](https://github.com/dperson/torproxy/blob/master/tor-route-all-traffic.sh).
For it to work, you must set `--net=host` when launching the container.

## Exposing the port

    sudo docker run -it -p 8118:8118 -p 9050:9050 -d dperson/torproxy

**NOTE**: it will take a while for tor to bootstrap...

Then you can hit privoxy web proxy at `http://host-ip:8118` with your browser or
tor via the socks protocol directly at `http://hostname:9050`.


## Complex configuration

    sudo docker run -it --rm dperson/torproxy -h
    Usage: torproxy.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -b ""       Configure tor relaying bandwidth in KB/s
                    possible arg: "[number]" - # of KB/s to allow
        -e          Allow this to be an exit node for tor traffic
        -l "<country>" Configure tor to only use exit nodes in specified country
                    required args: "<country>" (IE, "US" or "DE")
                    <country> - country traffic should exit in
        -n          Generate new circuits now
        -p "<password>" Configure tor HashedControlPassword for control port
        -s "<port>;<host:port>" Configure tor hidden service
                    required args: "<port>;<host:port>"
                    <port> - port for .onion service to listen on
                    <host:port> - destination for service request

    The 'command' (if provided and valid) will be run instead of torproxy

ENVIRONMENT VARIABLES

 * `TORUSER` - If set use named user instead of 'tor' (for example root)
 * `BW` - As above, set a tor relay bandwidth limit in KB, IE `50`
 * `EXITNODE` - As above, allow tor traffic to access the internet from your IP
 * `LOCATION` - As above, configure the country to use for exit node selection
 * `PASSWORD` - As above, configure HashedControlPassword for control port
 * `SERVICE - As above, configure hidden service, IE '80;hostname:80'
 * `TZ` - Configure the zoneinfo timezone, IE `EST5EDT`
 * `USERID` - Set the UID for the app user
 * `GROUPID` - Set the GID for the app user

Other environment variables beginning with `TOR_` will edit the configuration
file accordingly:

 * `TOR_NewCircuitPeriod=400` will translate to `NewCircuitPeriod 400`

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec -it tor torproxy.sh` (as of version 1.3 of docker).

### Setting the Timezone

    sudo docker run -it -p 8118:8118 -p 9050:9050 -e TZ=EST5EDT \
                -d dperson/torproxy

### Start torproxy setting the allowed bandwidth:

    sudo docker run -it -p 8118:8118 -p 9050:9050 -d dperson/torproxy -b 100

OR

    sudo docker run -it -p 8118:8118 -p 9050:9050 -e BW=100 -d dperson/torproxy

### Start torproxy configuring it to be an exit node:

    sudo docker run -it -p 8118:8118 -p 9050:9050 -d dperson/torproxy -e

OR

    sudo docker run -it -p 8118:8118 -p 9050:9050 -e EXITNODE=1 \
                -d dperson/torproxy

## Test the proxy:

    curl -Lx http://<ipv4_address>:8118 http://jsonip.com/

---

If you wish to adapt the default configuration, use something like the following
to copy it from a running container:

    sudo docker cp torproxy:/etc/tor/torrc /some/torrc

Then mount it to a new container like:

    sudo docker run -it -p 8118:8118 -p 9050:9050 \
                -v /some/torrc:/etc/tor/torrc:ro -d dperson/torproxy

# User Feedback

## Issues

### tor failures (exits or won't connect)

If you are affected by this issue (a small percentage of users are) please try
setting the TORUSER environment variable to root, IE:

    sudo docker run -it -p 8118:8118 -p 9050:9050 -e TORUSER=root -d \
                dperson/torproxy

### Reporting

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/torproxy/issues).