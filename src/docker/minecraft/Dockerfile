# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING
ARG DOCKER_TAG

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
    --location "https://launcher.mojang.com/v1/objects/${MINECRAFT_VERSION}/server.jar" \
    --output server.jar && \
  true

#----------------------------------------------------------------
FROM openjdk:jre-alpine as packager

# 内部完結

WORKDIR /usr/local/minecraft/

EXPOSE 25565

ENTRYPOINT ["java", "-Xmx1G", "-Xms1G", "-jar", "server.jar", "nogui"]

RUN echo 'eula=true' > eula.txt

# 外部参照

RUN \
  apk update && \
  apk upgrade

COPY --from=worker /workdir/ /usr/local/minecraft/
