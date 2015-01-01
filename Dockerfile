FROM ubuntu:trusty
MAINTAINER David Personette <dperson@dperson.com>

# Install tor and privoxy
RUN TERM=dumb apt-get update -qq && \
    TERM=dumb apt-get install -qqy --no-install-recommends tor privoxy && \
    TERM=dumb apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Configure
COPY torproxy.sh /usr/bin/
RUN sed -i 's|localhost:8118|0.0.0.0:8118|' /etc/privoxy/config && \
    sed -i 's|^logdir /var/log/privoxy|logdir /dev|' /etc/privoxy/config && \
    sed -i 's|^logfile logfile|logfile stdout|' /etc/privoxy/config && \
    sed -i '/forward *localhost\//a forward-socks5t / 127.0.0.1:1080 .' \
                /etc/privoxy/config && \
    sed -i '/forward-socks5t \//a forward 172.30.42.*/ .' /etc/privoxy/config&&\
    sed -i '/forward-socks5t \//a forward 127.*.*.*/ .' /etc/privoxy/config && \
    sed -i '/forward 172\.30\.42\.\*\//a forward localhost/ .' \
                /etc/privoxy/config && \
    echo 'SocksPort 0.0.0.0:1080' >> /etc/tor/torrc && \
    echo 'Log notice stdout' >> /etc/tor/torrc && \
    echo 'DataDirectory /var/lib/tor' >> /etc/tor/torrc && \
    echo 'ExitPolicy reject *:*' >> /etc/tor/torrc && \
    echo 'RelayBandwidthRate 10 KB' >> /etc/tor/torrc && \
    echo 'RelayBandwidthBurst 20 KB' >> /etc/tor/torrc

EXPOSE 1080 8118

VOLUME ["/var/lib/tor"]

ENTRYPOINT ["torproxy.sh"]
