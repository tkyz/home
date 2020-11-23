# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/berkeleydb:4.8.30 as berkeleydb

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/builder:alpine as builder

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

WORKDIR /workdir/

# 外部参照

COPY ./${DOCKER_TAG}/ /workdir/
COPY --from=berkeleydb /usr/local/berkeleydb/ /usr/local/berkeleydb/

RUN \
  source "${PWD}/env" && \
  git clone --branch "${BITCOIN_VERSION}" https://github.com/bitcoin/bitcoin.git && \
  cd bitcoin && \
  ./autogen.sh && \
  sed -i -E 's#^ac_default_prefix=/usr/local$#ac_default_prefix=/usr/local/bitcoin#g' ./configure && \
  ./configure \
    CPPFLAGS='-I/usr/local/berkeleydb/include/ -O2' \
    LDFLAGS='-L/usr/local/berkeleydb/lib/' \
    --without-gui && \
  make && \
  make install && \
  true

#----------------------------------------------------------------
FROM alpine:latest as packager

# 内部完結

ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/usr/local/berkeleydb/lib/"
ENV PATH            "${PATH}:/usr/local/bitcoin/bin/"

# mainnet p2p/rpc
EXPOSE   8333
#EXPOSE  8332

# testnet p2p/rpc
#EXPOSE 18333
#EXPOSE 18332

# regtest p2p/rpc
#EXPOSE 18444
#EXPOSE 18332

ENTRYPOINT ["/entrypoint.sh"]

# 外部参照

RUN \
  apk --no-cache add \
    boost \
    libevent

COPY --from=berkeleydb /usr/local/berkeleydb/lib/ /usr/local/berkeleydb/lib/
COPY --from=builder    /usr/local/bitcoin/bin/    /usr/local/bitcoin/bin/
COPY ./entrypoint.sh /entrypoint.sh
