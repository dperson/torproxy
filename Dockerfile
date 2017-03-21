FROM debian:stretch
MAINTAINER David Personette <dperson@gmail.com>

# Install tor and privoxy
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends gnupg1 procps && \
    apt-key adv --keyserver pgp.mit.edu --recv-keys \
                A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 && \
    /bin/echo -n "deb http://deb.torproject.org/torproject.org stretch main" \
                >>/etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends privoxy tor tor-geoipdb \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    sed -i 's|^\(accept-intercepted-requests\) .*|\1 1|' /etc/privoxy/config &&\
    sed -i 's|^[^#]*\(127.0.0.1:8118\)|#\1|' /etc/privoxy/config && \
    sed -i 's|^[^#]*\[::1\]:8118|[::]:8118|' /etc/privoxy/config && \
    sed -i 's|^\(logdir\) .*|\1 /dev|' /etc/privoxy/config && \
    sed -i 's|^\(logfile\) .*|\1 stdout|' /etc/privoxy/config && \
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
    echo 'ControlSocket /etc/tor/run/control' >>/etc/tor/torrc && \
    echo 'ControlSocketsGroupWritable 1' >>/etc/tor/torrc && \
    echo 'ControlPort 9051' >>/etc/tor/torrc && \
    echo 'CookieAuthentication 1' >>/etc/tor/torrc && \
    echo 'CookieAuthFileGroupReadable 1' >>/etc/tor/torrc && \
    echo 'CookieAuthFile /etc/tor/run/control.authcookie' >>/etc/tor/torrc && \
    echo 'DataDirectory /var/lib/tor' >>/etc/tor/torrc && \
    echo 'RunAsDaemon 0' >>/etc/tor/torrc && \
    echo 'User debian-tor' >>/etc/tor/torrc && \
    echo 'AutomapHostsOnResolve 1' >>/etc/tor/torrc && \
    echo 'ExitPolicy reject *:*' >>/etc/tor/torrc && \
    echo 'RelayBandwidthRate 10 KB' >>/etc/tor/torrc && \
    echo 'RelayBandwidthBurst 20 KB' >>/etc/tor/torrc && \
    echo 'VirtualAddrNetworkIPv4 10.192.0.0/10' >>/etc/tor/torrc && \
    echo 'DNSPort 5353' >>/etc/tor/torrc && \
    echo 'SocksPort 0.0.0.0:9050 IsolateDestAddr' >>/etc/tor/torrc && \
    echo 'TransPort 9040' >>/etc/tor/torrc && \
    mkdir -p /etc/tor/run && \
    chown -Rh debian-tor. /var/lib/tor /etc/tor/run && \
    chmod 0750 /etc/tor/run && \
    apt-get purge -qqy gnupg1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
    #echo 'Log notice file /dev/stdout' >>/etc/tor/torrc && \
COPY torproxy.sh /usr/bin/

EXPOSE 8118 9050 9051

VOLUME ["/etc/tor", "/var/lib/tor"]

ENTRYPOINT ["torproxy.sh"]