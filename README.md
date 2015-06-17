[![logo](http://allthingsd.com/files/2013/10/tor-logo.png)](https://torproject.org/)

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

**NOTE**: this image is setup by default to be a relay only (not an exit node)

## Exposing the port

    sudo docker run -p 8118:8118 -p 9050:9050 -d dperson/torproxy

**NOTE**: it will take a while for tor to bootstrap...

Then you can hit privoxy web proxy at `http://host-ip:8080` with your browser or
tor via the socks protocol directly at `http://hostname:9050`.


## Complex configuration

    sudo docker run -it --rm dperson/torproxy -h
    Usage: torproxy.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -b ""       Configure tor relaying bandwidth in KB/s
                    possible arg: "[number]" - # of KB/s to allow
        -e          Allow this to be an exit node for tor traffic
        -s "<port>;<host:port>" Configure tor hidden service
                    required args: "<port>;<host:port>"
                    <port> - port for .onion service to listen on
                    <host:port> - destination for service request
        -t ""       Configure timezone
                    possible arg: "[timezone]" - zoneinfo timezone for container

    The 'command' (if provided and valid) will be run instead of torproxy

ENVIROMENT VARIABLES (only available with `docker run`)

 * `TORUSER` - If set use named user instead of 'debian-tor' (for example root)
 * `BW` - As above, set a tor relay bandwidth limit in KB, IE `50`
 * `EXITNODE` - As above, allow tor traffic to access the internet from your IP
 * `SERVICE - As above, configure hidden service, IE '80;hostname:80'
 * `TIMEZONE` - As above, set a zoneinfo timezone, IE `EST5EDT`

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec torproxy.sh` (as of version 1.3 of docker).

### Start torproxy with a specified zoneinfo timezone:

    sudo docker run -p 8118:8118 -p 9050:9050 -d dperson/torproxy -t EST5EDT

OR

    sudo docker run -p 8118:8118 -p 9050:9050 -e TIMEZONE=EST5EDT -d \
                dperson/torproxy

### Start torproxy setting the allowed bandwidth:

    sudo docker run -p 8118:8118 -p 9050:9050 -d dperson/torproxy -b 100

OR

    sudo docker run -p 8118:8118 -p 9050:9050 -e BW=100 -d dperson/torproxy

### Start torproxy configuring it to be an exit node:

    sudo docker run -p 8118:8118 -p 9050:9050 -d dperson/torproxy -e

OR

    sudo docker run -p 8118:8118 -p 9050:9050 -e EXITNODE=1 -d dperson/torproxy

## Test the proxy:

    curl -x http://<ipv4_address>:8118 http://jsonip.com/

---

If you wish to adapt the default configuration, use something like the following
to copy it from a running container:

    sudo docker cp torproxy:/etc/tor/torrc /some/torrc

Then mount it to a new container like:

    sudo docker run -p 8118:8118 -p 9050:9050 \
                -v /some/torrc:/etc/tor/torrc:ro -d dperson/torproxy

# User Feedback

## Issues

### tor failures (exits or won't connect)

If you are affected by this issue (a small percentage of users are) please try
setting the TORUSER environment variable to root, IE:

    sudo docker run -p 8118:8118 -p 9050:9050 -e TORUSER=root -d \
                dperson/torproxy

### Reporting

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/torproxy/issues).
