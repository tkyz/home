# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=debian

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/home:${DOCKER_TAG}

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

EXPOSE 3389

ENTRYPOINT ["/entrypoint.sh"]

# 外部参照

COPY "./${DOCKER_TAG}/" /workdir/
COPY ./entrypoint.sh    /entrypoint.sh

RUN \
  /workdir/provision.sh && \
  rm -rf /workdir/
