# home

## 概要

自分用の環境・設定です。<br>
ドメイン[`.home`](https://icannwiki.org/.home)を使用します。

頻繁に`rebase`や`squash`します。

## 設定

```yml
home:
  env:
#   HOME_YML: ${HOME}/home.yml
#   HOME_DIR: ${HOME}/home
#   LANG: ja_JP.UTF-8
#   PATH:
#     - ${HOME_DIR}/local/bin
#     - ${HOME_DIR}/bin
#   CLASSPATH:
#     - .
#     - ./*
#     - ${HOME_DIR}/local/lib/*
#     - ${HOME_DIR}/lib/*
  pki:
    root:
      pub: ${HOME_DIR}/.pki/root/pub
      crt: ${HOME_DIR}/.pki/root/crt
    node:
      key: ${HOME_DIR}/.pki/node/key
      pub: ${HOME_DIR}/.pki/node/pub
      csr: ${HOME_DIR}/.pki/node/csr
      crt: ${HOME_DIR}/.pki/node/crt
  git:
    origin:
      - ${HOME_DIR}/mnt/home.git
      - ssh://git.home/home.git
      - git://git.home/home.git
      - https://git.home/home.git
    github:
      - ssh://git@github.com/tkyz/home.git
      - https://github.com/tkyz/home.git
  dns:
    hosts:
      127.0.0.1:
        - localhost
        - home
        - dns.home
        - ntp.home
        - raw.home
        - irc.home
        - api.home
        - k8s.home
        # repositories
        - apt.home
        - git.home
        - mvn.home
        - docker.home
    resolv:
      - 1.1.1.1
#     - 8.8.8.8
#     - 8.8.4.4
  ntp:
    - pool.ntp.org
    - 0.jp.pool.ntp.org
    - 1.jp.pool.ntp.org
    - 2.jp.pool.ntp.org
    - 3.jp.pool.ntp.org
    - ntp.nict.jp
    - ntp.jst.mfeed.ad.jp
    - ntp1.jst.mfeed.ad.jp
    - ntp2.jst.mfeed.ad.jp
    - ntp3.jst.mfeed.ad.jp
    - ntp.ring.gr.jp
    - ntp0.ring.gr.jp
    - ntp1.ring.gr.jp
    - ntp2.ring.gr.jp
#   - time.google.com
#   - time1.google.com
#   - time2.google.com
#   - time3.google.com
#   - time4.google.com
```

## インストール

```bash
source /dev/stdin < <(curl https://raw.home/sbin/profile.sh); git_cat /sbin/install.sh | bash
```
<!--
```bash
source /dev/stdin < <(curl https://raw.tkyz.jp/sbin/profile.sh); git_cat /sbin/install.sh | bash
```
-->
```bash
source /dev/stdin < <(curl https://raw.githubusercontent.com/tkyz/home/master/sbin/profile.sh); git_cat /sbin/install.sh | bash
```

## Licence

[MIT](./LICENSE)
