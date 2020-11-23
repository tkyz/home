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
  git clone --branch "${LITECOIN_VERSION}" https://github.com/litecoin-project/litecoin.git && \
  cd litecoin && \
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
ENV PATH            "${PATH}:/usr/local/litecoin/bin/"

# mainnet p2p/rpc
EXPOSE   9333
#EXPOSE  9332

# testnet p2p/rpc
#EXPOSE 19335
#EXPOSE 19332

# regtest p2p/rpc
#EXPOSE 19444
#EXPOSE 19443

ENTRYPOINT ["/entrypoint.sh"]

# 外部参照

RUN \
  apk --no-cache add \
    boost \
    libevent \
    openssl

COPY --from=berkeleydb /usr/local/berkeleydb/lib/ /usr/local/berkeleydb/lib/
COPY --from=builder    /usr/local/bin/            /usr/local/litecoin/bin/
COPY ./entrypoint.sh /entrypoint.sh
