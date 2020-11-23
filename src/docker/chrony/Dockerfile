# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=latest

#----------------------------------------------------------------
FROM alpine:latest

# 内部完結

EXPOSE 123/udp

ENTRYPOINT ["chronyd", "-d"]

# 外部参照

RUN apk add --no-cache chrony
