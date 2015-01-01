docker-proxy
============

HTTP proxy powered by Privoxy behind Tor to be used for scraping or anonymous browsing.

## Express Mode
---

It's now available at Docker Hub, you can start by just doing this

`$ docker run -d -p 8118:8118 sinar/proxy`

##How to
---

###Build docker image
`$ docker build -t <image_name> .`


###Run
*Note it might take awhile for tor to bootstrap itself

*Known bug for host with ipv6 support, if you want it to bind to ipv4 address please replace `-p 8118:8118` with `-p <ipv4_address>:8118:8118`

`$ docker run -d -p 8118:8118 <image_name>`


###For interactive mode (debug mode)
`$ docker run -t -i -p 8118:8118 <image_name>`


##Test
---

To test with curl

`$ curl -x http://127.0.0.1:8118 http://jsonip.com/`


Have fun!
