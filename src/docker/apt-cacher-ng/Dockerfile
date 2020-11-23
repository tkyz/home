# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=latest

#----------------------------------------------------------------
FROM debian:latest

# 内部完結

EXPOSE 3142

ENTRYPOINT \
  chmod 777 /var/cache/apt-cacher-ng && \
  /etc/init.d/apt-cacher-ng start && \
  tail -f /var/log/apt-cacher-ng/apt-cacher.log

# 外部参照

RUN \
  apt update && \
  apt upgrade -y && \
  apt install -y apt-cacher-ng && \
  sed -i -E "s/^# (PassThroughPattern: \.\*) #.*$/\1:443/g" /etc/apt-cacher-ng/acng.conf && \
  true
