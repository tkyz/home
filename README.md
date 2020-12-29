# home

## 概要

自分用の環境・設定です。<br>
ドメイン[`.home`](https://icannwiki.org/.home)を使用します。

頻繁に`rebase`や`squash`します。

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
