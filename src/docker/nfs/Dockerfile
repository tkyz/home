# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=latest

#----------------------------------------------------------------
FROM alpine:latest

# 内部完結

EXPOSE 2049

ENTRYPOINT \
  exportfs -ra && \
  tail -f /dev/null

RUN \
  mkdir -p '/mnt/nfs/' && \
  echo '/mnt/nfs/ *(rw,no_root_squash,no_subtree_check)' > /etc/exports

# 外部参照

RUN apk add --no-cache nfs-utils
