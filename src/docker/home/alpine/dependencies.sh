#!/bin/sh -eu

if [ 0 != "$(id -u)" ]; then
  false
fi

apk update
apk upgrade

apk --no-cache add \
  openssl \
  curl \
  bash

apk --no-cache add \
  git \
  jq \
  python3 \
  py-pip

pip3 install yq

if [ 0 == "${DOCKER_BUILDING:-0}" ] && [ ! -f /.dockerenv ]; then

  apk add --no-cache sudo

  # TODO: /etc/sudoers.d/
  if false; then

#   useradd -m "${USER}"
    adduser -D "${USER}"

#   sudo sed -ri \
#     -e 's///g' \
#     /etc/sudoers.d/

  fi

fi
