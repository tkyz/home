# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/builder:alpine as builder

# 内部設定

ARG DOCKER_BUILDING
ARG DOCKER_TAG

WORKDIR /workdir/

# 外部設定

COPY ./${DOCKER_TAG}/ /workdir/

RUN \
  source "${PWD}/env" && \
  git clone --branch "${ETHEREUM_VERSION}" https://github.com/ethereum/go-ethereum.git && \
  cd go-ethereum && \
  make geth && \
  true

#----------------------------------------------------------------
FROM alpine:latest as packager

# 内部設定

ENV PATH "${PATH}:/usr/local/ethereum/bin/"

EXPOSE 30303

ENTRYPOINT ["/entrypoint.sh"]

# 外部設定

RUN apk --no-cache add ca-certificates

COPY --from=builder /workdir/go-ethereum/build/bin/geth /usr/local/ethereum/bin/
COPY ./entrypoint.sh /entrypoint.sh
