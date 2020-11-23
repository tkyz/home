#!/bin/sh -eu

if [ 0 != "$(id -u)" ]; then
  false
fi

apt update
apt upgrade -y

apt install -y \
  openssl \
  curl \
  bash

apt install -y \
  git \
  jq \
  python3.7 \
  python3-pip

pip3 install yq

if [ 0 == "${DOCKER_BUILDING:-0}" ] && [ ! -f /.dockerenv ]; then

  apt install -y sudo

  # TODO: /etc/sudoers.d/
  if false; then

#   useradd -m "${USER}"
    adduser -D "${USER}"

#   sudo sed -ri \
#     -e 's///g' \
#     /etc/sudoers.d/

  fi

fi
