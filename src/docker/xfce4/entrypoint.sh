#!/bin/bash -eu

if [[ ! -v XRDP_PASSWORD ]]; then

  XRDP_PASSWORD="$(cat /dev/urandom | base64 | tr -d -c '[:alnum:]' | fold -w 32 | head -n 1)"

  echo "XRDP_RANDOM_PASSWORD=${XRDP_PASSWORD}"

fi

echo "root:${XRDP_PASSWORD}" | chpasswd

/etc/init.d/xrdp start

tail -f /var/log/xrdp-sesman.log
