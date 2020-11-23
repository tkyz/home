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

# https://github.com/NetHack/NetHack.git
# https://github.com/jnethack/jnethack-alpha.git
RUN \
  source "${PWD}/env" && \
  git clone --branch "${JNETHACK_VERSION}" https://github.com/jnethack/jnethack-alpha.git && \
  cd jnethack-alpha && \
  sed -i \
    -e 's/cp -n/cp/g' \
    -e '/^PREFIX/s:=.*:=/usr:' \
    sys/unix/hints/linux && \
  sh sys/unix/setup.sh sys/unix/hints/linux && \
  make all && \
  make install && \
  true

#----------------------------------------------------------------
FROM alpine:latest as packager

# 内部完結

ENV NETHACKOPTIONS "kcode:u,!autopickup,color,disclose:+i +a +v +g +c,hilite_pet"
ENV PATH "${PATH}:/usr/games/"

ENTRYPOINT ["/usr/games/jnethack"]

# 外部参照

RUN apk --no-cache add ncurses

COPY --from=builder /usr/games/ /usr/games/
