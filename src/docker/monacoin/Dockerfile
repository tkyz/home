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
  git clone --branch "${MONACOIN_VERSION}" https://github.com/monacoinproject/monacoin.git && \
  cd monacoin && \
  # https://github.com/litecoin-project/litecoin/issues/632
  if [[ '0.17.1' == "${DOCKER_TAG}" ]]; then sed -i -e '17i #include <deque>' src/httpserver.cpp; fi && \
  ./autogen.sh && \
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

ENV LD_LIBRARY_PATH /usr/local/berkeleydb/lib/
ENV PATH            "${PATH}:/usr/local/monacoin/bin/"

# mainnet p2p/rpc
EXPOSE   9401
#EXPOSE

# testnet p2p/rpc
#EXPOSE 19402
#EXPOSE

# regtest p2p/rpc
#EXPOSE
#EXPOSE

ENTRYPOINT ["/entrypoint.sh"]

# 外部参照

RUN \
  apk --no-cache add \
    boost \
    libevent \
    openssl

COPY --from=berkeleydb /usr/local/berkeleydb/lib/ /usr/local/berkeleydb/lib/
COPY --from=builder    /usr/local/bin/            /usr/local/monacoin/bin/
COPY ./entrypoint.sh /entrypoint.sh
