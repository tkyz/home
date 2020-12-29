#!/bin/bash -eu

reload

# dependencies
type openssl > /dev/null 2>&1
type curl    > /dev/null 2>&1
type git     > /dev/null 2>&1
type yq      > /dev/null 2>&1

mkdir -p "${HOME_DIR}"

#----------------------------------------------------------------
# pki

umask 0077

# id
if true; then

  mkdir -p "${HOME_DIR}/.pki/root@home"
  root_pub="${HOME_DIR}/.pki/root@home/pub"
  root_crt="${HOME_DIR}/.pki/root@home/crt"

  mkdir -p "${HOME_DIR}/.pki/node@home"
  node_key="${HOME_DIR}/.pki/node@home/key"
  node_pub="${HOME_DIR}/.pki/node@home/pub"
  node_csr="${HOME_DIR}/.pki/node@home/csr"
  node_crt="${HOME_DIR}/.pki/node@home/crt"

  # rsaキーペア
  if [[ ! -f "${node_key}" ]]; then
    openssl genrsa -rand /dev/urandom -out "${node_key}" 4096
  fi
  openssl rsa -in "${node_key}" -pubout -out "${node_pub}"                  2> /dev/null
# openssl rsa -in "${node_key}"         -out "${node_key}.der" -outform der 2> /dev/null
# openssl rsa -in "${node_key}" -pubout -out "${node_pub}.der" -outform der 2> /dev/null

  # 証明書署名要求
  openssl req -new -key "${node_key}" -out "${node_csr}" -subj "/CN=selfsign"

  # 自己署名
  if [[ ! -f "${node_crt}" ]]; then
    # TODO: 有効期限:10年
    openssl x509 -days 3650 -req -in "${node_csr}" -signkey "${node_key}" -out "${node_crt}"
  fi

  # ソース管理させる
  if is_root; then
    \cp -f "${node_pub}" "${root_pub}"
    \cp -f "${node_crt}" "${root_crt}"
  fi

  find "${HOME_DIR}/.pki" -type f                                 | xargs --no-run-if-empty chmod 600
  find "${HOME_DIR}/.pki" -type f -name pub -or -type f -name crt | xargs --no-run-if-empty chmod 644
  find "${HOME_DIR}/.pki" -type d                                 | xargs --no-run-if-empty chmod 755

fi

# authorized_keys
if true; then

  mkdir -p "${HOME}/.ssh/"
  touch "${HOME}/.ssh/authorized_keys"

  tmp_file="$(mktemp)"
  {

    find "${HOME_DIR}/.pki" -type f -name pub | while read pub; do

      sshpub="$(cat "${pub}" | ssh-keygen -f /dev/stdin -i -m pkcs8)"
      comment="$(echo "${pub}" | awk -F '/' '{print $(NF-1)}')"

      echo "${sshpub} ${comment}"

    done

    cat  "${HOME}/.ssh/authorized_keys"
    curl https://github.com/tkyz.keys | sed 's/$/ tkyz@github.com/g'

  } | sort | uniq > "${tmp_file}"

  \cp -f "${tmp_file}" "${HOME}/.ssh/authorized_keys"

fi

#----------------------------------------------------------------
# home

umask 0022

# .gitconfig
if true; then
  git config --global core.ignorecase false
  git config --global core.quotepath  false
  git config --global core.autocrlf   false
  git config --global core.safecrlf   true
  git config --global core.filemode   false
  git config --global color.ui        auto
  git config --global color.diff      auto
  git config --global color.status    auto
  git config --global color.branch    auto
# git config --global pull.rebase     true
fi
if is_root; then
  git config --global user.name       'tkyz'
  git config --global user.email      '36824716+tkyz@users.noreply.github.com'
fi

mkdir -p "${HOME_DIR}"

# リモートリポジトリ
declare -A git_remote
if true; then

  origin_bare="${HOME_DIR}/mnt/home.git"
# origin_ssh='ssh://git.home/home.git'
  origin_ssh="ssh://git.home${origin_bare}"
  origin_git='git://git.home/home.git'
# origin_https='https://git.home/home.git'
  github_ssh='ssh://git@github.com/tkyz/home.git'
  github_https='https://github.com/tkyz/home.git'

  name='origin'
  if is_root; then
    git_remote["${name}"]="${origin_bare}"
  elif ssh git.home true 2> /dev/null; then
    git_remote["${name}"]="${origin_ssh}"
  else
    git_remote["${name}"]="${origin_git}"
  fi

  name='github'
  if ssh-add -l | grep -q tkyz@github.com; then
    git_remote["${name}"]="${github_ssh}"
  else
    git_remote["${name}"]="${github_https}"
  fi

fi

# ベアリポジトリ
if is_root && [[ ! -d "${git_remote['origin']}" ]]; then

# mnt 'home.git' "${git_remote['origin']}"

  git init --bare "${git_remote['origin']}"

  # first commit
  pushd "$(mktemp -d)"

    git init

#   date="$(date '+%F %T %z')"
    date='2012-04-22 02:00:08 +0900'
    comment='first commit'

    GIT_COMMITTER_DATE="${date}" \
      git commit \
        --date="${date}" \
        --allow-empty \
        --message "${comment}"

    for key in "${!git_remote[@]}"; do

      val="${git_remote["${key}"]}"

      git remote add "${key}" "${val}"
      git push --force "${val}" master || true

    done

  popd

fi

# ワークツリー
pushd "${HOME_DIR}"

  git init

  git config --local user.name  'tkyz'
  git config --local user.email '36824716+tkyz@users.noreply.github.com'

  for key in "${!git_remote[@]}"; do

    val="${git_remote["${key}"]}"

    git remote add "${key}" "${val}" 2> /dev/null || git remote set-url "${key}" "${val}"

    git fetch "${key}" || true

    # master
    git checkout --no-track -b master "${key}/master" 2> /dev/null || git merge master "${key}/master"
    git remote set-head "${key}" master || true

  done

popd

# ディレクトリ作成
mkdir -p \
  "${HOME_DIR}/lib/" \
  "${HOME_DIR}/local/bin/" \
  "${HOME_DIR}/local/lib/" \
  "${HOME_DIR}/local/sbin/" \
  "${HOME_DIR}/local/src/" \
  "${HOME_DIR}/mnt/" \
  "${HOME_DIR}/opt/" \
  "${HOME_DIR}/tmp/" \
  "${HOME_DIR}/var/cache/" \
  "${HOME_DIR}/var/log/"

# シンボリックリンクの張り直し
find "${HOME_DIR}/.dotfiles/" -mindepth 1 -maxdepth 1 | while read item; do

  name="${item##*/}"

  if [[ -f "${item}" && "${name}" == .minttyrc ]] && ! is_cygwin; then
    continue
  fi
  if [[ -f "${item}" && "${name}" =~ .cmd$ ]]; then
    continue
  fi

  if [[ -f "${item}" ]]; then
    ln -fs  "${HOME_DIR}/.dotfiles/${name}" "${HOME}/${name}"
  elif [[ -d "${item}" ]] && ! is_cygwin; then
    ln -fsn "${HOME_DIR}/.dotfiles/${name}" "${HOME}/${name}"
  elif [[ -d "${item}" ]] && is_cygwin; then
    cmd /d /s /c mklink /d "$(cygpath -w "${HOME}/${name}")" "$(cygpath -w "${item}")" |& iconv -f cp932 -t utf-8
  fi

done

#----------------------------------------------------------------
# sudoer

# profile.d
if true; then
  sudo ln -fs "${HOME_DIR}/sbin/profile.sh" /etc/profile.d/home.sh
fi

# ca-certificates
if true; then

  conf_file='/etc/ca-certificates.conf'
  sudo touch "${conf_file}"

  crt_dir='/usr/share/ca-certificates/home'
  sudo mkdir -p "${crt_dir}"
  sudo chmod 755 "${crt_dir}"

  sudo ln -fs "${node_crt}" "${crt_dir}/node.crt"
  sudo ln -fs "${root_crt}" "${crt_dir}/root.crt"
  sudo chmod 644 "${root_crt}" "${node_crt}"

  line='home/node.crt'
  if ! grep -q "${line}" "${conf_file}"; then
    echo "${line}" | sudo tee -a "${conf_file}"
  fi
  line='home/root.crt'
  if ! grep -q "${line}" "${conf_file}"; then
    echo "${line}" | sudo tee -a "${conf_file}"
  fi

  sudo update-ca-certificates

fi
