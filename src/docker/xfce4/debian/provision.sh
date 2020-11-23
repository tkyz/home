#!/bin/bash -eu

shopt -s expand_aliases
if [[ 0 == "$(id -u)" || 1 == "${DOCKER_BUILDING:-0}" || -f /.dockerenv ]]; then
  alias sudo=''
fi

sudo apt update
sudo apt upgrade -y

#----------------------------------------------------------------
# xfce4
if true; then

  sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    task-xfce-desktop

fi

#----------------------------------------------------------------
# xrdp
if true; then

  sudo apt install -y \
    xrdp

fi

#----------------------------------------------------------------
# 日本語入力
if true; then

  sudo apt install -y \
    fonts-vlgothic \
    ibus-mozc

fi

#----------------------------------------------------------------
# その他
if true; then

  sudo apt install -y \
    blueman \
    keepass2 \
    telegram-desktop

fi

#----------------------------------------------------------------
# vnc
if false; then

  sudo apt install -y \
    tightvncserver

fi

#----------------------------------------------------------------
# google-chrome
if false; then

  curl 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo apt-key add -
  echo 'deb http://dl.google.com/linux/chrome/deb/ stable non-free main' | sudo tee /etc/apt/sources.list.d/google-chrome.list

  sudo apt update
  sudo apt install -y google-chrome-stable

fi

#----------------------------------------------------------------
# eclipse
if false; then

  dir="${HOME}/home/opt/eclipse"

  # main
  {

    curl --silent --show-error \
      --location 'http://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2019-06/R/eclipse-java-2019-06-R-linux-gtk-x86_64.tar.gz' | tar zxf - -C "${dir}" --strip-components 1 \

    sed -i \
      -e "s#^-vmargs#-data\n${HOME}/home/var/local.cache.eclipse/\n-vmargs#g" \
      -e 's/^-Xms.*/-Xms4G/g' \
      -e 's/^-Xmx.*/-Xmx4G/g' \
      -e '$a -Xverify:none' \
      "${dir}/eclipse.ini"

  }

  # pleiades
  {

#   curl --silent --show-error \
#     --location 'http://ftp.jaist.ac.jp/pub/mergedoc/pleiades/build/stable/pleiades.zip' | tar zxf - -C "${dir}" --strip-components 1 \

    sed -i \
      -e '$a -javaagent:plugins/jp.sourceforge.mergedoc.pleiades/pleiades.jar' \
      "${dir}/eclipse.ini"

    sed -i \
      -e 's/"ᴜ"/" "/g' \
      "${dir}/plugins/jp.sourceforge.mergedoc.pleiades/conf/pleiades-config.xml"

  }

fi
