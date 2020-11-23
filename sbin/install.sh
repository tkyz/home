#!/bin/bash -eu

reload

#----------------------------------------------------------------
# .secrets

umask 0077

# RSAキーペア
if true; then

  if [[ ! -f "${node_key}" ]]; then
    mkdir -p "${node_key%/*}"
    openssl genrsa -rand /dev/urandom -out "${node_key}" 4096
  fi
  openssl rsa -in "${node_key}" -pubout -out "${node_pub}"                  2> /dev/null
# openssl rsa -in "${node_key}"         -out "${node_key}.der" -outform der 2> /dev/null
# openssl rsa -in "${node_key}" -pubout -out "${node_pub}.der" -outform der 2> /dev/null

fi

# 自己証明書
if [[ ! -f "${node_crt}" ]]; then

  cn='tkyz-node-ca' # ${node_hash}"
  if is_root; then
    cn='tkyz-root-ca'
  fi

  openssl req -new -key "${node_key}" -out "${node_csr}" -subj "/CN=${cn}"
  openssl x509 -days 3650 -req -in "${node_csr}" -signkey "${node_key}" -out "${node_crt}"

fi

# ソース管理させる
if false; then
  cp -f "${node_pub}" "${root_pub}"
  cp -f "${node_crt}" "${root_crt}"
  chmod 644 "${root_pub}" "${root_crt}"
fi

mkdir -p "${HOME}/.ssh/"

# ssh-config
if true; then

  line="Include ${home_dir}/etc/ssh/config"
  file="${HOME}/.ssh/config"

  # TODO: function化
  if [[ ! -f "${file}" ]] || ! cat "${file}" | grep -q "${line}"; then
    echo "${line}" | tee -a "${file}"
  fi

fi

# authorized_keys
if true; then

  org_file="${HOME:-/root}/.ssh/authorized_keys"
  tmp_file="$(mktemp)"

  cp "${org_file}" "${tmp_file}"

  # secure
  echo "$(cat "${node_pub}" | ssh-keygen -f /dev/stdin -i -m pkcs8) node-pub ${USER:-root}@$(hostname -f)" >> "${tmp_file}"

  # insecure
  echo "$(cat "${root_pub}" | ssh-keygen -f /dev/stdin -i -m pkcs8) root-pub" >> "${tmp_file}"
  curl https://github.com/tkyz.keys | sed 's/$/ tkyz@github.com/g' >> "${tmp_file}" || true

  sort "${tmp_file}" | uniq > "${org_file}"

  # TODO: 重複登録される
  if false; then
    cat "${org_file}" #| ssh "${USER}@keys.tkyz.jp" 'mkdir -p ~/.ssh/; cat >> ~/.ssh/authorized_keys'
  fi

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
# git config --global user.name       'tkyz'
# git config --global user.email      '36824716+tkyz@users.noreply.github.com'
fi

# home
if true; then

  # repositories
  origin_bare="${home_dir}/mnt/home.git"
  origin_file="file://${origin_bare}"
# origin_ssh='ssh://git.repos.tkyz.jp/home.git'
  origin_ssh="ssh://git.repos.tkyz.jp${origin_bare}"
  origin_git='git://git.repos.tkyz.jp/home.git'
  origin_https='https://git.repos.tkyz.jp/home.git'
  github_ssh='ssh://git@github.com/tkyz/home.git'
  github_https='https://github.com/tkyz/home.git'

  # リモートリポジトリ
  if is_root; then
    origin_repo="${origin_bare}"
    github_repo="${github_ssh}"
  elif ! is_docker && ! is_wsl && is_tcp git.repos.tkyz.jp 22; then # TODO: 鍵がない判定
    origin_repo="${origin_ssh}"
    github_repo="${github_ssh}"
  else
    origin_repo="${origin_git}"
    github_repo="${github_https}"
  fi

  mkdir -p "${home_dir}"

  # ベアリポジトリ
  if is_root && [[ ! -d "${origin_bare}" ]]; then

#   mnt 'home.git'

    git init --bare "${origin_repo}"

    pushd "$(mktemp -d)"

      git init

      git config --local user.name  'tkyz'
      git config --local user.email '36824716+tkyz@users.noreply.github.com'

      git remote add origin "${origin_repo}"
      git remote add github "${github_repo}"

#     date="$(date '+%F %T %z')"
      date='2012-04-22 02:00:08 +0900'
      comment='first commit'

      GIT_COMMITTER_DATE="${date}" \
        git commit \
          --date="${date}" \
          --allow-empty \
          --message "${comment}"

      git push --force "${origin_repo}" master || true
      git push --force "${github_repo}" master || true

    popd

  fi

  # ワークツリー
  pushd "${home_dir}"

    git init

    git config --local user.name  'tkyz'
    git config --local user.email '36824716+tkyz@users.noreply.github.com'

    git remote add origin "${origin_repo}" || git remote set-url origin "${origin_repo}"
    git remote add github "${github_repo}" || git remote set-url github "${github_repo}"

    git fetch --all --prune || true

    git remote set-head origin master || true
    git remote set-head github master || true

    if git checkout --no-track -b master origin/master; then
      git branch --set-upstream-to=origin/master master || true
    elif git checkout --no-track -b master github/master; then
      git branch --set-upstream-to=github/master master || true
    fi

    git merge origin || true
    git merge github || true

  popd

  # ディレクトリ作成
  mkdir -p \
    "${home_dir}/bin/" \
    "${home_dir}/lib/" \
    "${home_dir}/local/bin/" \
    "${home_dir}/local/lib/" \
    "${home_dir}/local/sbin/" \
    "${home_dir}/local/src/" \
    "${home_dir}/mnt/" \
    "${home_dir}/opt/" \
    "${home_dir}/tmp/" \
    "${home_dir}/var/cache/" \
    "${home_dir}/var/log/"

  # シンボリックリンクの張り直し
  find "${home_dir}/.dotfiles/" -mindepth 1 -maxdepth 1 | while read item; do

    name="${item##*/}"

    if [[ -f "${item}" && "${name}" == .minttyrc ]] && ! is_cygwin; then
      continue
    fi
    if [[ -f "${item}" && "${name}" =~ .cmd$ ]]; then
      continue
    fi

    if [[ -f "${item}" ]]; then
      ln -fs  "${home_dir}/.dotfiles/${name}" "${HOME}/${name}"
    elif [[ -d "${item}" ]] && ! is_cygwin; then
      ln -fsn "${home_dir}/.dotfiles/${name}" "${HOME}/${name}"
    elif [[ -d "${item}" ]] && is_cygwin; then
      cmd /d /s /c mklink /d "$(cygpath -w "${HOME}/${name}")" "$(cygpath -w "${item}")" |& iconv -f cp932 -t utf-8
    fi

  done

  # umask
  if true; then

    chmod 700 "${HOME}"

    # 0077
    find "${HOME}/.ssh/"  -type d -print0 | xargs --no-run-if-empty -0 chmod 700
    find "${HOME}/.ssh/"  -type f -print0 | xargs --no-run-if-empty -0 chmod 600
    find "${secrets_dir}" -type d -print0 | xargs --no-run-if-empty -0 chmod 700
    find "${secrets_dir}" -type f -print0 | xargs --no-run-if-empty -0 chmod 600

    # 0022
#   chmod -R go-w "${home_dir}" || true

  fi

  # profile
  if is_sudoer; then
    sudo ln -fs "${home_dir}/sbin/profile.sh" /etc/profile.d/home.sh
  fi

  # 自己証明書をインストール
  if is_sudoer; then

#   output_crt='/etc/pki/tls/certs' # cygwin
    output_dir='/usr/share/ca-certificates/tkyz'
    sudo mkdir -p "${output_dir}"

    sudo ln -fs "${node_crt}" "${output_dir}/node-ca.crt"
    sudo ln -fs "${root_crt}" "${output_dir}/root-ca.crt"

    sudo chmod 755 "${output_dir}"
#   sudo chmod 644 "${root_crt}" "${node_crt}" || true

    file='/etc/ca-certificates.conf'

    # TODO: function化したい
    line='tkyz/root-ca.crt'
    if [[ ! -f "${file}" ]] || ! cat "${file}" | grep -q "${line}"; then
      echo "${line}" | sudo tee -a "${file}"
    fi
    line='tkyz/node-ca.crt'
    if [[ ! -f "${file}" ]] || ! cat "${file}" | grep -q "${line}"; then
      echo "${line}" | sudo tee -a "${file}"
    fi

    sudo update-ca-certificates

  fi

fi

type="${1:-}"

if [[ -n "${type}" ]] && is_sudoer; then
  if is_debian; then sudo apt update; sudo apt upgrade -y; fi
  if is_alpine; then sudo apk update; sudo apk upgrade;    fi
fi

#----------------------------------------------------------------
# runtime
# TODO: runtime openjdk-latest-jre
# TODO: runtime dotnet-runtime
if [[ 'runtime' == "${type}" ]]; then

  # firewall
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l ufw | grep -q '^i.* ufw .*'; then

    sudo apt install -y ufw

    sudo systemctl enable ufw
    sstart ufw

    echo y | sudo ufw enable

    sudo ufw default deny
    sudo ufw reload

    # allowは各ブロックで記載

  fi

  # rootkit
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l rkhunter | grep -q '^i.* rkhunter .*'; then

    sudo apt install -y rkhunter

#   sudo systemctl enable rkhunter
#   sstart rkhunter

    sudo sed -ri \
      -e 's/^(UPDATE_LANG=.*)$/#\1/g' \
      -e 's/^#(PKGMGR)=NONE$/\1=DPKG/g' \
      -e 's/^(UPDATE_MIRRORS)=0$/\1=1/g' \
      -e 's/^(MIRRORS_MODE)=1$/\1=0/g' \
      -e 's#^(WEB_CMD)="/bin/false"$#\1=""#g' \
      /etc/rkhunter.conf

#   sudo systemctl reload rkhunter

    sudo rkhunter --update
    sudo rkhunter --propupd

  fi

  # antivirus
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l clamav | grep -q '^i.* clamav .*'; then

    sudo apt install -y clamav

    sudo systemctl enable clamav-freshclam
    sstart clamav-freshclam
    sudo sed -i \
      -e 's/^NotifyClamd/#NotifyClamd/g' \
      /etc/clamav/freshclam.conf

#   sudo systemctl reload clamav-freshclam

    # FIXME: ERROR: /var/log/clamav/freshclam.log is locked by another process
    sstop  clamav-freshclam
    sudo freshclam
    sstart clamav-freshclam

  fi

  # ssh-server
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l openssh-server | grep -q '^i.* openssh-server .*'; then

    sudo apt install -y openssh-server

    sudo systemctl enable ssh
    sstart ssh

    sudo sed -ri \
      -e 's/^#?(PermitRootLogin) .*/\1 no/g' \
      -e 's/^#?(PasswordAuthentication) .*/\1 no/g' \
      -e 's/^#?(PermitEmptyPasswords) .*/\1 no/g' \
      /etc/ssh/sshd_config

    sudo systemctl reload ssh

    # allow firewall
#   sudo ufw allow 22
    sudo ufw allow from 10.0.0.0/8     to any port 22
    sudo ufw allow from 172.16.0.0/12  to any port 22
    sudo ufw allow from 192.168.0.0/16 to any port 22
    sudo ufw reload

  fi

  if is_sudoer; then
    if is_debian; then sudo apt install -y     openssl openssh-client gnupg2 ca-certificates util-linux bash bash-completion curl jq sshfs cifs-utils nfs-common apt-transport-https arp-scan; fi
    if is_alpine; then sudo apk add --no-cache openssl openssh-client gnupg  ca-certificates util-linux bash bash-completion curl jq sshfs cifs-utils nfs-utils; fi
  fi

  # locale
  if is_sudoer && is_debian && ! dpkg -l locales | grep -q '^i.* locales .*'; then

    sudo apt install -y locales

    lang='ja_JP.UTF-8'

    echo "${lang} UTF-8" | sudo tee /etc/locale.gen
    sudo locale-gen ja_JP.UTF-8
    sudo localedef -f UTF-8 -i ja_JP ja_JP.utf8
    sudo update-locale LANG="${lang}"

#   sudo apt install -y \
#     task-japanese \
#     locales-all
#
#   sudo localectl set-locale \
#     LANG='ja_JP.UTF-8' \
#     LANGUAGE='ja_JP:ja'

  fi

  # runtime
  if is_sudoer; then

    # openjdk-11-jre
    if is_debian; then sudo apt install -y     openjdk-11-jre; fi
    if is_alpine; then sudo apk --no-cache add openjdk11-jre;  fi

    # python3
    if is_debian; then sudo apt install -y     python3.7 python3-pip; fi
    if is_alpine; then sudo apk --no-cache add python3   py-pip;      fi
    sudo pip3 install yq

    # dotnet core
    # https://docs.microsoft.com/ja-jp/dotnet/core/install/
    if is_debian && [[ 10 == "${VERSION_ID}" ]]; then

      curl "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -O
      sudo dpkg -i packages-microsoft-prod.deb
      rm packages-microsoft-prod.deb

      sudo apt install -y dotnet-runtime-5.0

    elif is_alpine; then
      curl https://dot.net/v1/dotnet-install.sh | sudo bash -eu /dev/stdin -c Current
    fi

  fi

  # docker
  # https://docs.docker.com/install/linux/docker-ce/debian/#install-docker-ce
  # TODO: rootless docker
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l docker-ce | grep -q '^i.* docker-ce .*'; then

    curl "https://download.docker.com/linux/${ID}/gpg" | sudo apt-key add -
    echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
    sudo apt update

    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # シンボリックリンクだとエラーになるのでコピー
#   sudo ln -fs "${home_dir}/etc/docker/daemon.json" '/etc/docker/daemon.json'
    sudo cp -f  "${home_dir}/etc/docker/daemon.json" '/etc/docker/daemon.json'

    # data-root (daemon.jsonではなくシンボリックリンクで変更)
    if false; then

      source_dir='/var/lib/docker'
      target_dir='/home/docker'

      if [[ -d "${source_dir}" && ! -s "${source_dir}" ]]; then
        sudo rm -rf "${source_dir}"
      fi
      sudo ln -fsn "${target_dir}" "${source_dir}"

    fi

    sudo systemctl enable docker
    srestart docker

  fi

  # kubernetes
  # https://kubernetes.io/docs/tasks/tools/install-kubectl/
  if is_sudoer && ! is_wsl && ! is_docker && is_debian && ! dpkg -l kubelet | grep -q '^i.* kubelet .*'; then

    curl 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
    echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update

    sudo apt install -y kubeadm kubelet kubectl

    sudo systemctl enable kubelet
#   srestart kubelet

    # 補完
    sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

  fi

  # kubelet-plugins
  find "${home_dir}/etc/kubelet/csi" -maxdepth 1 -mindepth 1 -type f 2> /dev/null | while read file; do

    driver_type="${file##*/}"
    output_dir="/usr/libexec/kubernetes/kubelet-plugins/volume/exec/tkyz~${driver_type}"

    sudo mkdir -p "${output_dir}"
    sudo chmod 755 "${output_dir}"
    sudo ln -fs "${file}" "${output_dir}/${driver_type}"

  done

  # k8s master
  if is_sudoer && is_root && [[ ! -f '/root/.kube/config' ]]; then

    sudo kubeadm reset -f
    sudo kubeadm init --pod-network-cidr='10.244.0.0/16'

    sudo mkdir -p '/root/.kube/'
    sudo ln -fs '/etc/kubernetes/admin.conf' '/root/.kube/config'
#   sudo kubectl config view --raw

    # TODO: 設定
    sudo kubectl taint nodes "$(hostname -f)" node-role.kubernetes.io/master:NoSchedule-
#   /etc/kubernetes/manifests/kube-apiserver.yaml
#     --service-cluster-ip-range=10.96.0.0/12
#     --service-node-port-range=1-65535
    srestart kubelet

    # allow firewall
#   sudo ufw allow from 10.0.0.0/8 to 10.96.0.1 port 443
#   sudo ufw reload

    # TODO: 選定
    # flannel
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

    # joinトークンの確認
    sudo kubeadm token create --print-join-command
    sudo kubeadm token list

  fi

  # k8s worker
  if is_sudoer && ! is_root && [[ ! -f '/etc/kubernetes/kubelet.conf' ]] && ping -c 1 -q join.tkyz.jp > /dev/null 2>&1; then

    sudo kubeadm reset -f

    join_cmd="$(curl https://join.tkyz.jp/)"
#   join_cmd="kubeadm join xxx.xxx.xxx.xxx:6443 --token [0-9a-z\.]{23} --discovery-token-ca-cert-hash sha256:[0-9a-f]{64}"

    if [[ "${join_cmd}" =~ ^kubeadm\ join\ .* ]]; then
      sudo ${join_cmd}
    fi

  fi

fi

#----------------------------------------------------------------
# develop
if [[ 'develop' == "${type}" ]]; then

  if is_sudoer; then
    if is_debian; then sudo apt install -y     zsh tcsh fish gettext-base tree vim tmux zip git tig wget rsync htop iotop iftop tcpdump nmap dnsutils netcat; fi
    if is_alpine; then sudo apk add --no-cache zsh tcsh fish gettext      tree vim tmux zip git tig wget rsync htop iotop iftop tcpdump nmap bind-tools;      fi
  fi

  # sdk
  if is_sudoer; then

    # コンパイラ
    if is_debian; then sudo apt install -y     gcc g++ autoconf automake pkg-config make patch;               fi
    if is_alpine; then sudo apk --no-cache add gcc g++ autoconf automake pkgconf    make patch linux-headers; fi
    if is_debian && ! is_wsl; then sudo apt install -y "linux-headers-$(uname --kernel-release)"; fi

    # ライブラリ
    if is_debian; then sudo apt install -y     libssl-dev  libncurses-dev musl-dev libboost-all-dev libtool linux-libc-dev libevent-dev libxt-dev bison flex groff libc6; fi
    if is_alpine; then sudo apk --no-cache add openssl-dev ncurses-dev    musl-dev boost-dev        libtool libc-dev       libevent-dev libxt-dev bison flex groff; fi
    if is_alpine; then sudo apk --repository http://dl-cdn.alpinelinux.org/alpine/edge/community add gnu-libiconv; fi

    # TODO: openjdk-latest-sdk
    if is_debian; then sudo apt install -y     openjdk-11-jdk ant        maven; fi
    if is_alpine; then sudo apk --no-cache add openjdk11-jdk  apache-ant maven; fi
    ln -fsn "${home_dir}/etc/apache-maven" "${HOME}/.m2"

    # dotnet core
    # https://docs.microsoft.com/ja-jp/dotnet/core/install/linux-debian
    if is_debian && [[ 10 == "${VERSION_ID}" ]]; then

      curl "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -O
      sudo dpkg -i packages-microsoft-prod.deb
      rm packages-microsoft-prod.deb

      sudo apt install -y dotnet-sdk-5.0

    # https://docs.microsoft.com/ja-jp/dotnet/core/install/linux-alpine
    elif is_alpine; then
      curl https://dot.net/v1/dotnet-install.sh | sudo bash -eu /dev/stdin -c Current
    fi

    # go
    if is_debian; then sudo apt install -y     golang; fi
    if is_alpine; then sudo apk --no-cache add     go; fi

    # node.js
    if is_debian; then sudo apt install -y     nodejs npm; fi
    if is_alpine; then sudo apk --no-cache add nodejs npm; fi

    # ruby
    if is_debian; then sudo apt install -y     ruby gem; fi
    if is_alpine; then sudo apk --no-cache add ruby;     fi # gem

    # perl
    if is_debian; then sudo apt install -y     perl; fi
    if is_alpine; then sudo apk --no-cache add perl; fi

  fi

  # adopt-openjdk-8-jdk
  output_dir="${home_dir}/opt/adopt-openjdk-8-jdk"
  if [[ ! -d "${output_dir}" ]]; then

    mkdir -p "${output_dir}"

    download_url="$(curl https://raw.githubusercontent.com/AdoptOpenJDK/openjdk8-binaries/master/latest_nightly.json | jq -r '.assets[].browser_download_url' | grep hotspot | grep x64 | grep linux | grep -v jre | grep \.tar\.gz$)"
    curl "${download_url}" | tar zx --strip-components 1 --no-same-permissions --no-same-owner -C "${output_dir}"

  fi
  if is_sudoer; then
    sudo ln -fs "${output_dir}/bin/java" '/usr/local/bin/java8'
  else
    ln -fs "${output_dir}/bin/java" "${home_dir}/local/bin/java8"
  fi

  # apache-drill
  output_dir="${home_dir}/opt/apache-drill"
  if [[ ! -d "${output_dir}" ]]; then

    mkdir -p "${output_dir}"

    version='drill-1.17.0'
    curl "https://downloads.apache.org/drill/${version}/apache-${version}.tar.gz" | tar zx --strip-components 1 --no-same-permissions --no-same-owner -C "${output_dir}"

    # jdbc driver
    # TODO: maven.repos.tkyz.jp
    jdbc=()
    jdbc+=('https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/8.4.1.jre11/mssql-jdbc-8.4.1.jre11.jar')
    jdbc+=('https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.21/mysql-connector-java-8.0.21.jar')
    jdbc+=('https://repo1.maven.org/maven2/net/sf/ucanaccess/ucanaccess/5.0.0/ucanaccess-5.0.0.jar')
    jdbc+=('https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.7.0/mariadb-java-client-2.7.0.jar')
    jdbc+=('https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.16/postgresql-42.2.16.jar')

    pushd "${output_dir}/jars/3rdparty" > /dev/null
      for url in "${jdbc[@]}"; do
        curl -O "${url}"
      done
    popd > /dev/null

  fi
  ln -fs "../../../etc/apache-drill/conf/storage-plugins-override.conf" "${output_dir}/conf/storage-plugins-override.conf"

  # embulk
  output_file="${home_dir}/local/bin/embulk"
  if [[ ! -f "${output_file}" ]]; then

    curl 'https://dl.embulk.org/embulk-latest.jar' -o "${output_file}"

    chmod 755 "${output_file}"

    # plugin
    java8 -jar "${output_file}" gem install \
      embulk-input-mysql \
      embulk-input-postgresql \
      embulk-input-oracle \
      embulk-input-sqlserver \
      embulk-input-db2 \
      embulk-input-mongodb \
      embulk-input-jdbc \
      embulk-input-hdfs \
      embulk-input-bigquery \
      embulk-input-gcs \
      embulk-input-dynamodb \
      embulk-output-mysql \
      embulk-output-postgresql \
      embulk-output-oracle \
      embulk-output-sqlserver \
      embulk-output-db2 \
      embulk-output-mongodb \
      embulk-output-jdbc \
      embulk-output-hdfs \
      embulk-output-bigquery \
      embulk-output-gcs \
      embulk-output-dynamodb \
      embulk-output-cassandra \
      embulk-filter-column \
      embulk-filter-mask \
      embulk-filter-eval

  fi
  if is_sudoer; then
    sudo ln -fs "${output_file}" '/usr/local/bin/embulk'
  fi

  # docker-compose
  if is_cmd docker; then

    output_file="${home_dir}/local/bin/docker-compose"
    if [[ ! -f "${output_file}" ]]; then

      # https://docs.docker.com/compose/install/
      curl "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o "${output_file}"

      chmod 755 "${output_file}"

    fi
    if is_sudoer; then
      sudo ln -fs "${output_file}" '/usr/local/bin/docker-compose'
    fi

  fi

  # google cloud sdk
  if ! is_cmd gcloud; then

    if is_debian; then

      # https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
      curl 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
      echo 'deb http://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
      sudo apt update

      sudo apt install -y google-cloud-sdk

    fi

    # TODO: 認証
#   gcloud auth login

  fi

fi

# 掃除
if [[ -n "${type}" ]] && is_sudoer; then
  if is_debian; then sudo apt autoremove -y; sudo apt clean; fi
  if is_alpine; then true; fi
fi
