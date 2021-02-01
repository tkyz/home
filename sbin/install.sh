#!/bin/bash -eu

reload

# dependencies
is_exec openssl
is_exec curl
is_exec git
is_exec yq

#----------------------------------------------------------------
# secure

umask 0077

# pki
if true; then

  function gen_pki() {

    local type="${1}"
    local name="${2}"

    local pki_dir="${HOME_DIR}/etc/pki/${name}"
    mkdir -p "${pki_dir}"

    local rsa_key="${pki_dir}/key"
    local rsa_pub="${pki_dir}/pub"
    local ca_csr="${pki_dir}/csr"
    local ca_crt="${pki_dir}/crt"

    if [[ 'crt' == "${type}" || 'rsa' == "${type}" ]]; then

      if [[ ! -f "${rsa_key}" ]]; then
        openssl genrsa -rand /dev/urandom -out "${rsa_key}" 4096
      fi

      openssl rsa -in "${rsa_key}" -pubout -out "${rsa_pub}"                  2> /dev/null
#     openssl rsa -in "${rsa_key}"         -out "${rsa_key}.der" -outform der 2> /dev/null
#     openssl rsa -in "${rsa_key}" -pubout -out "${rsa_pub}.der" -outform der 2> /dev/null

    fi

    if [[ 'crt' == "${type}" ]]; then

      openssl req -new -key "${rsa_key}" -out "${ca_csr}" -subj "/CN=${name}"

      # TODO: 有効期限:10年
      if [[ ! -f "${ca_crt}" ]]; then
        openssl x509 -days 3650 -req -in "${ca_csr}" -signkey "${rsa_key}" -out "${ca_crt}"
#       openssl ca -policy policy_anything -days 365 -cert "${ca_crt}" -keyfile "${rsa_key}" -in "${ca_csr}" -out "${ca_crt}" -extfile "${ca_san}"
      fi

    fi

  }

  if true; then
    gen_pki crt 'ca@cur.home'
  fi
  if is_root && [[ ! -f "${HOME_DIR}/etc/pki/ca@home/crt" ]]; then
    gen_pki crt 'ca@home'
  fi
  if is_root && [[ ! -f "${HOME_DIR}/etc/pki/tkyz@github.com/pub" ]]; then
    gen_pki rsa 'tkyz@github.com'
  fi

fi

# authorized_keys
if true; then

  mkdir -p "${HOME}/.ssh/"
  touch "${HOME}/.ssh/authorized_keys"

  tmp_file="$(mktemp)"
  {

    find "${HOME_DIR}/etc/pki" -type f -name pub | while read rsa_pub; do

      ssh_pub="$(cat "${rsa_pub}" | ssh-keygen -f /dev/stdin -i -m pkcs8)"
      comment="$(echo "${rsa_pub}" | awk -F '/' '{print $(NF-1)}')"

      echo "${ssh_pub} ${comment}"

    done

    cat  "${HOME}/.ssh/authorized_keys"
    curl https://github.com/tkyz.keys | sed 's/$/ tkyz@github.com/g'

  } | sort | uniq > "${tmp_file}"

  \cp -f "${tmp_file}" "${HOME}/.ssh/authorized_keys"

fi

#----------------------------------------------------------------
# home

umask 0022

mkdir -p "${HOME_DIR}"

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

# リモートリポジトリ
declare -A git_remote
if true; then

  origin_bare="${HOME_DIR}/mnt/home.git"
# origin_ssh='ssh://git.home/home.git'
  origin_ssh="ssh://git.home${origin_bare}"
  origin_git='git://git.home/home.git'
  origin_https='https://git.home/home.git'
  github_ssh='ssh://git@github.com/tkyz/home.git'
  github_https='https://github.com/tkyz/home.git'

  name='origin'
  if is_root; then
    git_remote["${name}"]="${origin_bare}"
  elif ssh git.home true 2> /dev/null; then
    git_remote["${name}"]="${origin_ssh}"
  elif is_tcp_conn git.home 9418; then
    git_remote["${name}"]="${origin_git}"
  elif is_tcp_conn git.home 443; then
    git_remote["${name}"]="${origin_https}"
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

  mnt 'home.git' "${git_remote['origin']}"

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

# skel
if [[ ! -f "${HOME_YML}" ]]; then
  if is_root; then
    cp "${HOME_DIR}/etc/skel/home.yml"     "${HOME_YML}"
  else
    cp "${HOME_DIR}/etc/skel/cur.home.yml" "${HOME_YML}"
  fi
fi

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
find "${HOME_DIR}/etc/dotfiles/" -mindepth 1 -maxdepth 1 | while read item; do

  name="${item##*/}"

  if [[ -f "${item}" && "${name}" == .minttyrc ]] && ! is_cygwin; then
    continue
  fi
  if [[ -f "${item}" && "${name}" =~ .cmd$ ]]; then
    continue
  fi

  if [[ -f "${item}" ]]; then
    ln -fs  "${item}" "${HOME}/${name}"
  elif [[ -d "${item}" ]] && ! is_cygwin; then
    ln -fsn "${item}" "${HOME}/${name}"
  elif [[ -d "${item}" ]] && is_cygwin; then
    cmd /d /s /c mklink /d "$(cygpath -w "${HOME}/${name}")" "$(cygpath -w "${item}")" |& iconv -f cp932 -t utf-8
  fi

done

# ssh-config
if true; then

  touch "${HOME}/.ssh/config"

  \cp -f "${HOME_DIR}/etc/ssh/config" "${HOME}/.ssh/config_cmn"

  line="Include ${HOME}/.ssh/config_cmn"
  if ! grep -q "${line}" "${HOME}/.ssh/config"; then

    tmp_file="$(mktemp)"
    {
      echo "${line}"
      cat  "${HOME}/.ssh/config"
    } > "${tmp_file}"

    \cp -f "${tmp_file}" "${HOME}/.ssh/config"

  fi

fi

#----------------------------------------------------------------
# sudoer

if [[ "${1:-}" == '-' ]]; then
  exit
fi

\sudo -v

source /etc/os-release

# profile.d
if true; then
  sudo ln -fs "${HOME_DIR}/sbin/profile.sh" /etc/profile.d/home.sh
fi

# apt-proxy
if ( is_debian || is_raspbian ); then

  output_file='/etc/apt/apt.conf.d/00proxy'

  # TODO: ProxyAutoDetect
  if is_tcp_conn apt.home 3142; then
    sudo ln -fs "${HOME_DIR}/etc/apt.conf.d/00proxy" "${output_file}"
  else
    sudo rm -rf "${output_file}"
  fi

fi

# ca-certificates
if true; then

  conf_file='/etc/ca-certificates.conf'
  sudo touch "${conf_file}"

  crt_dir='/usr/share/ca-certificates/home'
  sudo mkdir -p "${crt_dir}"
  sudo chmod 755 "${crt_dir}"

  sudo ln -fs "${HOME_DIR}/etc/pki/ca@home/crt"     "${crt_dir}/ca@home.crt"
  sudo ln -fs "${HOME_DIR}/etc/pki/ca@cur.home/crt" "${crt_dir}/ca@cur.home.crt"

  line='home/ca@home.crt'
  if ! grep -q "${line}" "${conf_file}"; then
    echo "${line}" | sudo tee -a "${conf_file}"
  fi
  line='home/ca@cur.home.crt'
  if ! grep -q "${line}" "${conf_file}"; then
    echo "${line}" | sudo tee -a "${conf_file}"
  fi

  sudo update-ca-certificates

fi

# パッケージ更新
if true; then
  if ( is_debian || is_raspbian ); then sudo apt update; sudo apt upgrade -y; sudo apt autoremove -y; sudo apt clean; fi
  if is_alpine;                    then sudo apk update; sudo apk upgrade; fi
fi

# security
if true; then

  if is_debian && ! is_docker && ! is_wsl && ! is_vagrant; then sudo apt install -y ufw rkhunter clamav; fi
  if is_debian && ! is_docker;                             then sudo apt install -y openssh-server; fi

  # firewall設定
  if is_exec ufw; then

    sudo systemctl enable ufw
    sstart ufw

    echo y | sudo ufw enable

    sudo ufw default deny
    sudo ufw reload

    # allowは各ブロックで記載

  fi

  # rootkit設定
  if is_exec rkhunter; then

    sudo sed -ri \
      -e 's/^(UPDATE_LANG=.*)$/#\1/g' \
      -e 's/^#(PKGMGR)=NONE$/\1=DPKG/g' \
      -e 's/^(UPDATE_MIRRORS)=0$/\1=1/g' \
      -e 's/^(MIRRORS_MODE)=1$/\1=0/g' \
      -e 's#^(WEB_CMD)="/bin/false"$#\1=""#g' \
      /etc/rkhunter.conf

    sudo rkhunter --update
    sudo rkhunter --propupd

  fi

  # clamav設定
  if is_exec clamav; then

    sudo sed -i \
      -e 's/^NotifyClamd/#NotifyClamd/g' \
      /etc/clamav/freshclam.conf

    sudo systemctl enable clamav-freshclam
    sstart clamav-freshclam

    # FIXME: ERROR: /var/log/clamav/freshclam.log is locked by another process
    sstop  clamav-freshclam
    sudo freshclam
    sstart clamav-freshclam

  fi

  # ssh-server設定
  if is_exec openssh-server; then

    sudo sed -ri \
      -e 's/^#?(PermitRootLogin) .*/\1 no/g' \
      -e 's/^#?(PasswordAuthentication) .*/\1 no/g' \
      -e 's/^#?(PermitEmptyPasswords) .*/\1 no/g' \
      /etc/ssh/sshd_config

    sudo systemctl enable ssh
    sstart ssh

    # allow firewall
    if is_exec ufw; then
#     sudo ufw allow 22
      sudo ufw allow from 10.0.0.0/8     to any port 22
      sudo ufw allow from 172.16.0.0/12  to any port 22
      sudo ufw allow from 192.168.0.0/16 to any port 22
      sudo ufw reload
    fi

  fi

fi

# utils
if true; then

  if is_debian; then sudo apt install -y     openssl openssh-client gnupg2 ca-certificates util-linux bash bash-completion curl jq zip sshfs cifs-utils nfs-common apt-transport-https locales; fi
  if is_alpine; then sudo apk add --no-cache openssl openssh-client gnupg  ca-certificates util-linux bash bash-completion curl jq zip sshfs cifs-utils nfs-utils; fi

  if ! is_root && is_debian; then sudo apt install -y     zsh tcsh fish gettext-base tree vim tmux git tig wget rsync htop iotop iftop tcpdump nmap dnsutils netcat; fi
  if ! is_root && is_alpine; then sudo apk add --no-cache zsh tcsh fish gettext      tree vim tmux git tig wget rsync htop iotop iftop tcpdump nmap bind-tools; fi

  # locales設定
  if is_exec locales; then

    echo "${LANG} UTF-8" | sudo tee /etc/locale.gen

    sudo locale-gen "${LANG}"
    sudo localedef -f UTF-8 -i ja_JP ja_JP.utf8
    sudo update-locale LANG="${LANG}"

#   sudo apt install -y \
#     task-japanese \
#     locales-all
#
#   sudo localectl set-locale \
#     LANG="${LANG}" \
#     LANGUAGE='ja_JP:ja'

  fi

fi

# スクリプト言語
if true; then

  # python3
  if is_debian; then sudo apt install -y     python3.7 python3-pip; fi
  if is_alpine; then sudo apk --no-cache add python3   py-pip; fi
  if is_exec pip3; then
    sudo pip3 install yq docker kubernetes
  fi

  # node.js
  if ! is_root && is_debian; then sudo apt install -y     nodejs npm; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add nodejs npm; fi

  # ruby
  if ! is_root && is_debian; then sudo apt install -y     ruby gem; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add ruby; fi # gem

  # perl
  if ! is_root && is_debian; then sudo apt install -y     perl; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add perl; fi

fi

# コンパイラ言語
if true; then

  # コンパイラ
  if ! is_root && is_debian; then sudo apt install -y     gcc g++ autoconf automake pkg-config make patch "linux-headers-$(uname --kernel-release)"; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add gcc g++ autoconf automake pkgconf    make patch  linux-headers; fi

  # ライブラリ
  if ! is_root && is_debian; then sudo apt install -y     libssl-dev  libncurses-dev musl-dev libboost-all-dev libtool linux-libc-dev libevent-dev libxt-dev bison flex groff libc6; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add openssl-dev ncurses-dev    musl-dev boost-dev        libtool libc-dev       libevent-dev libxt-dev bison flex groff; fi
  if ! is_root && is_alpine; then sudo apk --repository http://dl-cdn.alpinelinux.org/alpine/edge/community add gnu-libiconv; fi

  # openjdk-11
  if   is_root && is_debian; then sudo apt install -y     openjdk-11-jre; fi
  if ! is_root && is_debian; then sudo apt install -y     openjdk-11-jdk ant        maven; fi
  if   is_root && is_alpine; then sudo apk --no-cache add openjdk11-jre; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add openjdk11-jdk  apache-ant maven; fi
  if is_exec mvn; then
    ln -fsn "${HOME_DIR}/etc/apache-maven" "${HOME}/.m2"
  fi

  # adopt-openjdk-8-jre
  if ! is_root; then

    output_dir="${HOME_DIR}/opt/adopt-openjdk-8-jre"
    if [[ ! -d "${output_dir}" ]]; then

      mkdir -p "${output_dir}"

      download_url="$(curl https://raw.githubusercontent.com/AdoptOpenJDK/openjdk8-binaries/master/latest_nightly.json | jq -cr '.assets[].browser_download_url' | grep hotspot | grep x64 | grep linux | grep -v jre | grep \.tar\.gz$)"
      curl "${download_url}" | tar zx --strip-components 1 --no-same-permissions --no-same-owner -C "${output_dir}"

    fi

    sudo ln -fs "${output_dir}/bin/java" '/usr/local/bin/java8'
    ln -fs "../../opt/${output_dir##*/}/bin/java" "${HOME_DIR}/local/bin/java8"

  fi

  # dotnet-core-5
  # https://docs.microsoft.com/ja-jp/dotnet/core/install/
  if is_debian && [[ 10 == "${VERSION_ID}" ]]; then

    curl "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -O
    sudo dpkg -i packages-microsoft-prod.deb
    rm -f packages-microsoft-prod.deb

    sudo apt update

  fi
  if   is_root && is_debian && [[ 10 == "${VERSION_ID}" ]]; then sudo apt install -y dotnet-runtime-5.0; fi
  if ! is_root && is_debian && [[ 10 == "${VERSION_ID}" ]]; then sudo apt install -y dotnet-sdk-5.0; fi
  if   is_root && is_alpine; then curl https://dot.net/v1/dotnet-install.sh | sudo bash -eu /dev/stdin -c Current --runtime; fi
  if ! is_root && is_alpine; then curl https://dot.net/v1/dotnet-install.sh | sudo bash -eu /dev/stdin -c Current; fi

  # go
  if ! is_root && is_debian; then sudo apt install -y     golang; fi
  if ! is_root && is_alpine; then sudo apk --no-cache add     go; fi

fi

# k8s cluster
if ! is_wsl && ! is_docker; then

  # TODO: rootless docker

  if is_debian || is_raspbian; then

    # https://docs.docker.com/engine/install/debian/
    curl "https://download.docker.com/linux/${ID}/gpg" | sudo apt-key add -
    echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list

    # https://kubernetes.io/docs/tasks/tools/install-kubectl/
    curl 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
    echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt update

  fi

  if is_debian || is_raspbian; then sudo apt install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm; fi
  if is_debian;                then sudo apt install -y kubectl; fi

  # docker設定
  if is_exec docker; then

    sudo ln -fs "${HOME_DIR}/etc/docker/daemon.json" '/etc/docker/daemon.json'

    sudo systemctl enable docker
    sstart docker

  fi

  # kubelet設定
  if is_exec kubelet; then

    sudo systemctl enable kubelet
#   srestart kubelet

    # kubelet-plugins
    find "${HOME_DIR}/etc/kubelet/csi" -maxdepth 1 -mindepth 1 -type f 2> /dev/null | while read file; do

      driver_type="${file##*/}"
      output_dir="/usr/libexec/kubernetes/kubelet-plugins/volume/exec/home~${driver_type}"

      sudo mkdir -p "${output_dir}"
      sudo chmod 755 "${output_dir}"
      sudo ln -fs "${file}" "${output_dir}/${driver_type}"

    done

  fi

  # kubectl設定
  if is_exec kubectl; then
    sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  fi

  # kubeadm設定
  if is_exec kubeadm; then

    # k8s master-node
    if is_root && [[ ! -f '/root/.kube/config' ]]; then

      sudo kubeadm reset -f

      sudo kubeadm config images pull
      sudo kubeadm init --pod-network-cidr='10.244.0.0/16'

      sudo mkdir -p '/root/.kube/'
      sudo ln -fs '/etc/kubernetes/admin.conf' '/root/.kube/config'
#     sudo kubectl config view --raw

      # TODO: 設定
#     sudo kubectl taint nodes "$(hostname -f)" node-role.kubernetes.io/master:NoSchedule-
#     /etc/kubernetes/manifests/kube-apiserver.yaml
#       --service-cluster-ip-range=10.96.0.0/12
#       --service-node-port-range=1-65535
      srestart kubelet

      # allow firewall
      if is_exec ufw; then
        sudo ufw allow from 10.0.0.0/8 to 10.96.0.1 port 443
        sudo ufw reload
      fi

      # TODO: 選定
      # flannel
      sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

      # joinトークンの確認
      sudo kubeadm token create --print-join-command
      sudo kubeadm token list

    # k8s worker-node
    elif ! is_root && [[ ! -f '/etc/kubernetes/kubelet.conf' ]] && is_tcp_conn k8s.home 443; then

      sudo kubeadm reset -f

      join_cmd="$(curl https://k8s.home/)"
#     join_cmd="kubeadm join xxx.xxx.xxx.xxx:6443 --token [0-9a-z\.]{23} --discovery-token-ca-cert-hash sha256:[0-9a-f]{64}"

      if [[ "${join_cmd}" =~ ^kubeadm\ join\ .* ]]; then
        sudo ${join_cmd}
      fi

    fi

  fi

fi

# その他
if true; then

  # apache-drill
  if ! is_root; then

    output_dir="${HOME_DIR}/opt/apache-drill"
    if [[ ! -d "${output_dir}" ]]; then

      mkdir -p "${output_dir}"

      version='drill-1.18.0'
      curl "https://downloads.apache.org/drill/${version}/apache-${version}.tar.gz" | tar zx --strip-components 1 --no-same-permissions --no-same-owner -C "${output_dir}"

    fi

    # 設定
    if [[ -d "${output_dir}" ]]; then

      # jdbc driver
      # TODO: mvn.home
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

      # config
      ln -fs "../../../etc/apache-drill/storage-plugins-override.conf" "${output_dir}/conf/storage-plugins-override.conf"

    fi

  fi

  # embulk
  if ! is_root; then

    output_file="${HOME_DIR}/local/bin/embulk"
    if [[ ! -f "${output_file}" ]]; then
      curl 'https://dl.embulk.org/embulk-latest.jar' -o "${output_file}"
    fi

    # 設定
    if [[ -f "${output_file}" ]]; then

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

    sudo ln -fs "${output_file}" '/usr/local/bin/embulk'

  fi

  # docker-compose
  if ! is_root; then

    output_file="${HOME_DIR}/local/bin/docker-compose"
    if [[ ! -f "${output_file}" ]]; then
      # https://docs.docker.com/compose/install/
      curl "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o "${output_file}"
    fi

    # 設定
    if [[ ! -f "${output_file}" ]]; then

      chmod 755 "${output_file}"

      sudo ln -fs "${output_file}" '/usr/local/bin/docker-compose'

    fi

  fi

  # google cloud sdk
  if ! is_root; then

    if is_debian; then

      # https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
      curl 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
      echo 'deb http://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

      sudo apt update

    fi

    if is_debian || is_raspbian; then sudo apt install -y google-cloud-sdk; fi

    if is_exec gcloud && [[ ! -d "${HOME}/.config/gcloud/" ]]; then

      gcloud auth login
      gcloud auth application-default login

      # TODO: 認証
#     gcloud config set project        xxx
#     gcloud config set compute/region xxx
#     gcloud config set compute/zone   xxx
#
#     gcloud container clusters get-credentials xxx --project xxx --zone xxx

    fi

  fi

fi
