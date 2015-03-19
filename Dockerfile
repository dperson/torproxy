FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install tor and privoxy
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-key adv --keyserver pgp.mit.edu --recv-keys \
                A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 && \
    echo -n "deb http://deb.torproject.org/torproject.org jessie main" >> \
                /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends tor privoxy && \
    apt-get clean && \
    sed -i 's|localhost:8118|0.0.0.0:8118|' /etc/privoxy/config && \
    sed -i 's|^logdir /var/log/privoxy|logdir /dev|' /etc/privoxy/config && \
    sed -i 's|^logfile logfile|logfile stdout|' /etc/privoxy/config && \
    sed -i '/forward *localhost\//a forward-socks5t / 127.0.0.1:9050 .' \
                /etc/privoxy/config && \
    sed -i '/^forward-socks5t \//a forward 172.16.*.*/ .' /etc/privoxy/config&&\
    sed -i '/^forward 172\.16\.\*\.\*\//a forward 172.17.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.17\.\*\.\*\//a forward 172.18.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.18\.\*\.\*\//a forward 172.19.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.19\.\*\.\*\//a forward 172.20.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.20\.\*\.\*\//a forward 172.21.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.21\.\*\.\*\//a forward 172.22.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.22\.\*\.\*\//a forward 172.23.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.23\.\*\.\*\//a forward 172.24.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.24\.\*\.\*\//a forward 172.25.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.25\.\*\.\*\//a forward 172.26.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.26\.\*\.\*\//a forward 172.27.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.27\.\*\.\*\//a forward 172.28.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.28\.\*\.\*\//a forward 172.29.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.29\.\*\.\*\//a forward 172.30.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.30\.\*\.\*\//a forward 172.31.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 172\.31\.\*\.\*\//a forward 10.*.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 10\.\*\.\*\.\*\//a forward 192.168.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 192\.168\.\*\.\*\//a forward 127.*.*.*/ .' \
                /etc/privoxy/config && \
    sed -i '/^forward 127\.\*\.\*\.\*\//a forward localhost/ .' \
                /etc/privoxy/config && \
    echo 'SocksPort 9050' >> /etc/tor/torrc && \
    echo 'DataDirectory /var/lib/tor' >> /etc/tor/torrc && \
    echo 'ExitPolicy reject *:*' >> /etc/tor/torrc && \
    echo 'RelayBandwidthRate 10 KB' >> /etc/tor/torrc && \
    echo 'RelayBandwidthBurst 20 KB' >> /etc/tor/torrc && \
    rm -rf /var/lib/apt/lists/* /tmp/*
    #echo 'Log notice file /dev/stdout' >> /etc/tor/torrc && \
COPY torproxy.sh /usr/bin/

EXPOSE 8118 9050

VOLUME ["/var/lib/tor"]

ENTRYPOINT ["torproxy.sh"]
