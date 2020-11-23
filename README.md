# home

## 概要

自分用の`${HOME}`環境です。頻繁に`rebase`や`squash`します。

## インスコ

### Linux

```bash
source /dev/stdin < <(curl https://source.tkyz.jp/sbin/profile.sh); git_cat /sbin/install.sh | bash
```

or

```bash
source /dev/stdin < <(curl https://raw.githubusercontent.com/tkyz/home/master/sbin/profile.sh); git_cat /sbin/install.sh | bash
```

### Windows

```bat
```

## pki

- [自己署名ルートCA証明書](https://raw.githubusercontent.com/tkyz/home/master/sbin/ca.crt)
- [公開鍵](https://raw.githubusercontent.com/tkyz/home/master/sbin/pub)
- [公開鍵](https://github.com/tkyz.keys) (ssh://git@github.com/tkyz)

## Licence

[MIT](./LICENSE)
