# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=latest

#----------------------------------------------------------------
FROM alpine:latest as worker

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

WORKDIR /workdir/

COPY "./${DOCKER_TAG}/" /workdir/

# 外部参照

RUN \
  apk update && \
  apk upgrade && \
  apk add --no-cache \
    curl && \
  source "${PWD}/env" && \
  curl --silent --show-error \
    --location "https://archive.apache.org/dist/archiva/${APACHE_ARCHIVA_VERSION}/binaries/apache-archiva-${APACHE_ARCHIVA_VERSION}-bin.tar.gz" | tar zxf - && \
  mv "apache-archiva-${APACHE_ARCHIVA_VERSION}" 'apache-archiva' && \
  true

#----------------------------------------------------------------
FROM openjdk:8-jre as packager

# 内部完結

EXPOSE 8080

ENTRYPOINT ["/usr/local/apache-archiva/bin/archiva", "console"]

# 外部参照

RUN \
  apt update && \
  apt upgrade -y && \
  apt install -y procps && \
  true

COPY --from=worker /workdir/apache-archiva/ /usr/local/apache-archiva/
