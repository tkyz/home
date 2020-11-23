# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=debian

#----------------------------------------------------------------
FROM docker.repos.tkyz.jp/home:${DOCKER_TAG}

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

# 外部参照

#COPY "./${DOCKER_TAG}/*.sh" /workdir/

RUN \
  bash -eu /root/home/sbin/install.sh develop \
  rm -rf /workdir/
