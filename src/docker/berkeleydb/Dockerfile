# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/builder:alpine as builder

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

WORKDIR /workdir/

# 外部参照

COPY ./${DOCKER_TAG}/ /workdir/

RUN \
  source "${PWD}/env" && \
  curl --silent --show-error \
    --location "http://download.oracle.com/berkeley-db/db-${BERKELEYDB_VERSION}.tar.gz" | tar zxf - && \
  cd "db-${BERKELEYDB_VERSION}/build_unix" && \
  sed -i -E 's#^ac_default_prefix=/usr/local/BerkeleyDB\.[0-9\.]+$#ac_default_prefix=/usr/local/berkeleydb#g' ../dist/configure && \
  sed -i -e 's/__atomic_compare_exchange(/__atomic_compare_exchange_patch(/g'                                 ../dbinc/atomic.h && \
  ../dist/configure \
    --enable-cxx && \
  make && \
  make install && \
  true

#----------------------------------------------------------------
FROM alpine:latest as packager

# 内部完結

ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/usr/local/berkeleydb/lib/"

# 外部参照

COPY --from=builder /usr/local/berkeleydb/ /usr/local/berkeleydb/
