# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

#----------------------------------------------------------------
FROM alpine:latest

# 内部完結

EXPOSE 6667

ENTRYPOINT ["ngircd", "-n"]

# 外部参照

RUN apk add --no-cache ngircd
