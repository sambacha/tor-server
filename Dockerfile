# syntaxdocker/dockerfile-upstream:master-experimental
FROM alpine:3.16.2@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870 AS builder

ENV SHA256SUM=d39d38598208f4d6201d7edc6ad573b3a898a932a5c68d3074016a9525519b22
ARG TOR_VER=0.4.7.9
ARG TORGZ=https://dist.torproject.org/tor-$TOR_VER.tar.gz

RUN apk --no-cache add --update \
  alpine-sdk gnupg libevent libevent-dev zlib zlib-dev openssl openssl-dev

RUN wget $TORGZ.asc && wget $TORGZ

# Verify tar signature and install tor
RUN gpg --keyserver keys.openpgp.org --recv-keys 0x6AFEE6D49E92B601 \
  && gpg --verify tor-$TOR_VER.tar.gz.asc || { echo "Couldn't verify sig"; exit 1; }
RUN tar xfz tor-$TOR_VER.tar.gz && cd tor-$TOR_VER \
  && ./configure && make -j $(nproc --all) install

FROM alpine:3.16.2@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870 

RUN apk upgrade
RUN apk update && apk add --no-cache \
  bash alpine-sdk gnupg libevent libevent-dev zlib zlib-dev openssl openssl-dev
    && rm -rf /var/cache/*/* \
    && echo "" > /root/.ash_history;

# change default shell from ash to bash
RUN sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd
ENV LC_ALL=en_US.UTF-8

# TODO: fixup usrgroups
# RUN addgroup -g 10001 -S nonroot && adduser -u 10000 -S -G nonroot -h /home/nonroot nonroot

RUN adduser -s /bin/bash -D -u 2000 tor

RUN mkdir -p /var/run/tor && chown -R tor:tor /var/run/tor && chmod 2700 /var/run/tor
RUN mkdir -p /home/tor/tor && chown -R tor:tor /home/tor/tor  && chmod 2700 /home/tor/tor

COPY --chmod=0744 --from=builder /usr/local/ /usr/local/

USER tor
