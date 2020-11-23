umask 0022

# TODO: 重複箇所で定義 home_dir
home_dir="${HOME:-/root}/home"

root_pub="${home_dir}/sbin/pub"
root_crt="${home_dir}/sbin/ca.crt"

secrets_dir="${HOME:-/root}/.secrets"

home_yml="${secrets_dir}/home.yml"
node_key="${secrets_dir}/pki/key"
node_pub="${secrets_dir}/pki/pub"
node_csr="${secrets_dir}/pki/csr"
node_crt="${secrets_dir}/pki/crt"

export LANG='ja_JP.UTF-8'

if [[ -d "${home_dir}" ]]; then

  # TODO: 既に定義されている場合
  PATH="${home_dir}/bin:${PATH}"
  PATH="${home_dir}/local/bin:${PATH}"

  # TODO: 既に定義されている場合
  export CLASSPATH
  CLASSPATH="${home_dir}/lib/*"
  CLASSPATH="${home_dir}/local/lib/*:${CLASSPATH}"
  CLASSPATH="./*:${CLASSPATH}"
  CLASSPATH=".:${CLASSPATH}"

fi

function git_cat() {

  local path="${1}"

  # TODO: 重複箇所で定義 home_dir
  local home_dir="${HOME:-/root}/home"

  if [[ -v DOCKER_BUILDING && -f "/workdir${path}" ]]; then
    cat "/workdir${path}"

  elif [[ -f "${home_dir}${path}" ]]; then
    cat "${home_dir}${path}"

  elif ping -c 1 -q source.tkyz.jp > /dev/null 2>&1; then
    curl "https://source.tkyz.jp${path}" 2> /dev/null

  elif ping -c 1 -q github.jp > /dev/null 2>&1; then
    curl "https://raw.githubusercontent.com/tkyz/home/master${path}" 2> /dev/null

  else
    false
  fi

}
export -f git_cat

function reload() {
  source /dev/stdin < <(git_cat /sbin/profile.sh)
  echo reloaded.
}
export -f reload

# color
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
txtrst='\e[0m'    # Reset

# ID=<distribution>
source /etc/os-release 2> /dev/null || true

function pushd() {
  mkdir -p "${1}"
  command pushd "${1}" > /dev/null
}
function popd() {
  command popd > /dev/null
}

# trap
function trap_err() {

  local status="${?}"

  local txtset="\033[91m"

  printf   "${txtset}%s${txtrst}\n" "error:"
  printf   "${txtset}%s${txtrst}\n" "  timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  printf   "${txtset}%s${txtrst}\n" "  \${0}: ${0}"
  printf   "${txtset}%s${txtrst}\n" "  \${SHELL}: ${SHELL}"
  printf   "${txtset}%s${txtrst}\n" "  \${SHLVL}: ${SHLVL}"
  printf   "${txtset}%s${txtrst}\n" "  \${PWD}: ${PWD}"
  printf   "${txtset}%s${txtrst}\n" "  \${BASH_COMMAND}: ${BASH_COMMAND}"
  printf   "${txtset}%s${txtrst}\n" "  \${BASH_SOURCE}: ${BASH_SOURCE}"
  printf   "${txtset}%s${txtrst}\n" "  \${$}: ${$}"
  printf   "${txtset}%s${txtrst}\n" "  \${@}:"
  for arg in "${@}"; do
    printf "${txtset}%s${txtrst}\n" "    - ${arg}"
  done
  printf   "${txtset}%s${txtrst}\n" "  \${FUNCNAME[1]}: ${FUNCNAME[1]}"
  printf   "${txtset}%s${txtrst}\n" "  exit: ${status}"

}
trap trap_err ERR

#----------------------------------------------------------------
# alias

shopt -s expand_aliases

# sudo
if [[ 0 == "$(id -u)" || -v DOCKER_BUILDING ]]; then
  alias sudo=' '
else
  alias sudo='sudo '
fi

alias reboot='sudo shutdown now -r '
alias relogin='exec "${SHELL}" -l '

alias timestamp='date "+%Y%m%d_%H%M%S" '

alias sstatus=' sudo systemctl status '
alias sstart='  sudo systemctl start '
alias sstop='   sudo systemctl stop '
alias srestart='sudo systemctl restart '

alias ..='cd .. '
alias ls='ls --color=auto --show-control-chars --time-style=+%Y-%m-%d\ %H:%M:%S '
alias la='ls -a '
alias ll='la -lFh '
alias curl='curl -fL '
alias vi='vim '
alias gs='git status '

# if is_xxx; then ...
alias is_root='    ( diff -q "${root_pub}" "${node_pub}" > /dev/null 2>&1 ) '
alias is_ssh='     ( test -v SSH_CLIENT || test -v SSH_CONNECTION ) '
alias is_sudoer='  ( sudo true ) '
alias is_alpine='  ( grep -q "^ID=alpine$"   /etc/os-release 2> /dev/null ) '
alias is_debian='  ( grep -q "^ID=debian$"   /etc/os-release 2> /dev/null ) '
alias is_ubuntu='  ( grep -q "^ID=ubuntu$"   /etc/os-release 2> /dev/null ) '
alias is_raspbian='( grep -q "^ID=raspbian$" /etc/os-release 2> /dev/null ) '
alias is_gcp='     ( grep -q "^google-sudoers:.*$" /etc/group ) '
alias is_aws='     ( grep -q "^ec2-user:.*$"       /etc/group ) '
alias is_vagrant=' ( grep -q "^vagrant:.*$"        /etc/group ) '
alias is_docker='  ( test -v DOCKER_BUILDING || test -f /.dockerenv ) '
alias is_wsl='     ( test -d /mnt/c/ ) '
alias is_cygwin='  ( test -d /cygdrive/ || test "cygwin" == "${OSTYPE:-}" ) '

function is_cmd() {
  type "${1}" > /dev/null 2>&1
}

function is_tcp() {
  timeout 1 bash -c "cat /dev/null > /dev/tcp/${1}/${2}"
}

#----------------------------------------------------------------
# 端末

# prompt
if true; then

  PS1=''
# PS2=
# PS3=
# PS4=

  # TODO: IPの範囲で色変えたい
  # ssh接続情報
  if is_ssh; then
    PS1+="[${txtylw}$(echo "${SSH_CONNECTION}" | awk -F ' ' '{print $1 ":" $2}')${txtrst}->${txtylw}$(echo "${SSH_CONNECTION}" | awk -F ' ' '{print $4 ":" $3}')${txtrst}]"
  fi

  # 仮想・シミュレート環境
  if is_cygwin; then
    PS1+="[${txtgrn}Cygwin${txtrst}]"
  elif is_wsl; then
    PS1+="[${txtgrn}WSL${txtrst}]"
  elif is_docker; then
    PS1+="[${txtgrn}Docker${txtrst}]"
  elif is_vagrant; then
    PS1+="[${txtgrn}Vagrant${txtrst}]"
  # ホスト
  elif is_raspbian; then
    PS1+="[${txtylw}Pi${txtrst}]"
  elif is_gcp; then
    PS1+="[${txtylw}GCP${txtrst}]"
  elif is_aws; then
    PS1+="[${txtylw}AWS${txtrst}]"
  fi

  if is_cygwin && openfiles > /dev/null 2>&1; then
    PS1+="${txtred}\u${txtrst}@$(hostname -f):\w # "
  elif ! is_cygwin && [[ 0 == "$(id -u)" ]]; then
    PS1+="${txtred}\u${txtrst}@$(hostname -f):\w # "
  else
    PS1+="${txtcyn}\u${txtrst}@$(hostname -f):\w $ "
  fi

fi

# history
if [[ -t 0 ]]; then

  touch "${HOME:-/root}/.bash_history"

  export HISTSIZE=16777216
  export HISTFILESIZE=16777216
  export HISTCONTROL=ignoreboth
  export HISTTIMEFORMAT='%Y-%m-%d %T: '

  stty start undef
  stty stop  undef

  share_history() {
    history -a
    history -c
    history -r
  }
  shopt -u histappend
  PROMPT_COMMAND=share_history

fi

#----------------------------------------------------------------
# コマンド

function upd() {

  if is_sudoer; then

    # パッケージマネージャーのプロキシ
    if is_debian; then

      local output_file='/etc/apt/apt.conf.d/00proxy'

      # TODO: ProxyAutoDetect
      if is_tcp debian.repos.tkyz.jp 3142; then
        sudo ln -fs "${home_dir}/etc/apt.conf.d/00proxy" "${output_file}"
      else
        sudo rm -rf "${output_file}"
      fi

    fi

    # パッケージ更新
    if is_debian; then sudo apt update; sudo apt upgrade -y; sudo apt autoremove -y; sudo apt clean; fi
    if is_alpine; then sudo apk update; sudo apk upgrade; fi

    # ウイルス定義
    if is_cmd freshclam; then
      sstop  clamav-freshclam
      sudo freshclam
      sstart clamav-freshclam
    fi

    # ルートキット
    if is_cmd rkhunter; then
      sudo rkhunter --update
      sudo rkhunter --propupd
    fi

  fi

  # home.git
  if is_cmd git; then
    git -C "${home_dir}" pull --all --prune
  fi

  reload

}

function mnt() {

  if [[ 1 == "${#}" ]]; then

    local mnt_item_yml="$(yq -r ".home.mnt[] | select(.name == \"${1}\")" "${home_yml}")"

    local def_name="$(echo "${mnt_item_yml}" | yq -r .name)"
    local def_type="$(echo "${mnt_item_yml}" | yq -r .type)"
    local def_host="$(echo "${mnt_item_yml}" | yq -r .host)"
    local def_path="$(echo "${mnt_item_yml}" | yq -r .path)"

    local mnt_target="${home_dir}/mnt/${def_name}"
    if ! mountpoint --quiet "${mnt_target}"; then

      mkdir -p "${mnt_target}"

      if [[ 'cifs' == "${def_type}" ]]; then

        local def_username="$(echo "${mnt_item_yml}" | yq -r '.username  | select(. != null)')"
        local def_password="$(echo "${mnt_item_yml}" | yq -r '.password  | select(. != null)')"
        local def_opts="$(    echo "${mnt_item_yml}" | yq -r '.opts      | select(. != null)')"
        local def_fstab="$(   echo "${mnt_item_yml}" | yq -r '.fstab     | select(. != null)')"

        local credentials="$(mktemp)"
        echo "username=${def_username}" >> "${credentials}"
        echo "password=${def_password}" >> "${credentials}"

        local mnt_source="//${def_host}${def_path}"
        local mnt_opts="$(eval echo ${def_opts})"
        mnt_opts+=",credentials=${credentials}"
        if ! echo "${mnt_opts}" | grep -q file_mode= 2> /dev/null; then mnt_opts+=',file_mode=0644'; fi
        if ! echo "${mnt_opts}" | grep -q dir_mode=  2> /dev/null; then mnt_opts+=',dir_mode=0755';  fi
        if ! echo "${mnt_opts}" | grep -q uid=       2> /dev/null; then mnt_opts+=",uid=$(id -u)";   fi
        if ! echo "${mnt_opts}" | grep -q gid=       2> /dev/null; then mnt_opts+=",gid=$(id -g)";   fi

#       if [[ 'true' == "${def_fstab}" ]]; then
#         echo "${mnt_source} ${mnt_target} ${def_type} ${mnt_opts} 0 0" | sudo tee --append /etc/fstab
#       fi
        sudo mount --types "${def_type}" --options "${mnt_opts}" "${mnt_source}" "${mnt_target}"

      elif [[ 'sshfs' == "${def_type}" ]]; then

        local user="${USER:-root}"
        local mnt_source="${user}@${def_host}:${def_path}"

        sshfs "${mnt_source}" "${mnt_target}"

      fi

    fi

  fi

}

function umnt() {

  if [[ 1 == "${#}" ]]; then

    local mnt_item_yml="$(yq -r ".home.mnt[] | select(.name == \"${1}\")" "${home_yml}")"

    local def_name="$(echo "${mnt_item_yml}" | yq -r .name)"
    local def_type="$(echo "${mnt_item_yml}" | yq -r .type)"

    local mnt_target="${home_dir}/mnt/${def_name}"
    if [[ -d "${mnt_target}" ]] && mountpoint --quiet "${mnt_target}"; then

      if [[ 'cifs' == "${def_type}" ]]; then
        sudo umount "${mnt_target}"

      elif [[ 'sshfs' == "${def_type}" ]]; then
        fusermount -u "${mnt_target}"
      fi

    fi

    rm -df "${mnt_target}" > /dev/null

  fi

}

function backup() {

  mnt backup

  local backup_yml="$(yq -r '.home.backup' "${home_yml}")"

  local password="$(echo "${backup_yml}" | yq -r '.password | select(. != null)')"
# local password="$(node_hash)"

  # TODO: home.ymlに定義化
  if false; then
    local item
    echo "${backup_yml}" | yq -r '.source[] | .' | while read item; do

      item="$(eval echo "${item}")"

#     tar -zc -C "${HOME}" '.secrets' | openssl enc -e -aes-256-cbc -salt -md sha512 -pbkdf2 -k "${aes_pass}" -out "${target_file}"

    done
  else
    local target_file="${home_dir}/mnt/backup/${USER:-root}@$(hostname -f)/$(timestamp).tgz.aes256"
    tar -zc -C "${HOME}" '.secrets' | openssl enc -e -aes-256-cbc -salt -md sha512 -pbkdf2 -k "${password}" -out "${target_file}"
  fi

  cat <<EOF
decrypt.
> openssl enc -d -aes-256-cbc -salt -md sha512 -pbkdf2 -k '' -in "${target_file}" | tar -zx -C "\$(mktemp -d)"
EOF

  umnt backup

}

function build() {

  # カスタムビルド
  if [[ -f build.sh ]]; then
    ./build.sh "$@"

  # Dockerマルチステージビルド
  elif [[ -f Dockerfile ]]; then

    # 配下のディレクトリはタグとして扱う
    find . -maxdepth 1 -mindepth 1 -type d -print0 2> /dev/null | sort -z | while IFS= read -r -d $'' docker_tag; do

      local current_name="${PWD##*/}"
      local docker_tag="${docker_tag##./}"
      local docker_img="docker.repos.tkyz.jp/${current_name}:${docker_tag}"

      echo '----------------------------------------------------------------'
      echo "docker build. [image=${docker_img}]"

      tar zch . | docker build \
        --build-arg DOCKER_TAG="${docker_tag}" \
        --tag="${docker_img}" \
         "$@" -

      if ping -c 1 -q docker.repos.tkyz.jp > /dev/null 2>&1; then
        docker push "${docker_img}"
      fi

    done

    # リンク先を元にlatestタグを作成
    if [[ -L latest && -d latest ]]; then

      local source_img="docker.repos.tkyz.jp/${current_name}:$(readlink latest)"
      local target_img="docker.repos.tkyz.jp/${current_name}:latest"

      docker tag "${source_img}" "${target_img}"

      if ping -c 1 -q docker.repos.tkyz.jp > /dev/null 2>&1; then
        docker push "${target_img}"
      fi

    fi

  # 単体ビルド maven
  elif [[ -f pom.xml ]]; then

    if [[ -f /.dockerenv ]]; then

      echo '----------------------------------------------------------------'
      echo 'maven build.'

      local opts=()
      opts+=('--threads 1C')
      opts+=('compile')
      opts+=('package')
      opts+=('dependency:copy-dependencies')
      opts+=('install')
#     opts+=('deploy')

      mvn ${opts[@]}

    else

      local workdir='/workdir'

      docker run \
        --interactive \
        --tty \
        --rm \
        --volume "${home_dir}/sbin/":'/root/home/sbin/':ro \
        --volume "${home_dir}/var/cache/org.apache.maven/":'/root/home/var/cache/org.apache.maven/' \
        --volume "${PWD}":"${workdir}" \
        --workdir "${workdir}" \
        docker.repos.tkyz.jp/builder:alpine build

#       --volume "${secrets_dir}/maven-settings-security.xml":'/root/home/.dotfiles/.m2/settings-security.xml':ro \

    fi

  elif [[ -f package.json ]]; then

    if [[ -f /.dockerenv ]]; then

      echo '----------------------------------------------------------------'
      echo 'npm build.'

      npm install
      npm run build

    else

      local workdir='/workdir'

      docker run \
        --interactive \
        --tty \
        --rm \
        --volume "${home_dir}/sbin/":'/root/home/sbin/':ro \
        --volume "${PWD}":"${workdir}" \
        --workdir "${workdir}" \
        docker.repos.tkyz.jp/builder:alpine build

    fi

  fi

}

function entrypoint() {

  # カスタム実行
  if [[ -f entrypoint.sh ]]; then
    ./entrypoint.sh "$@"

  # docker-compose
  elif [[ -f docker-compose.yml || -f docker-compose.yaml ]]; then
    docker-compose up "$@"

  # Docker
  elif [[ -f Dockerfile ]]; then

    local current_name="${PWD##*/}"
    local docker_repo='docker.repos.tkyz.jp'

    docker run \
      --interactive \
      --tty \
      --rm \
      --name "${current_name}" \
      --hostname "${current_name}" \
      "${docker_repo}/${current_name}:latest" "$@"

  fi

}

function k8s() {

  local k8s_yml="$(yq -r .home.k8s "${home_yml}")"
  local len="$(echo "${k8s_yml}" | yq -r length)"

  local i
  for ((i = 0; i < "${len}"; i++)); do

    local enabled="$(echo "${k8s_yml}" | yq -r ".[${i}].enabled | select(. != null)")"
    local ns="$(     echo "${k8s_yml}" | yq -r ".[${i}].ns      | select(. != null)")"
    local name="$(   echo "${k8s_yml}" | yq -r ".[${i}].name    | select(. != null)")"
    local build="$(  echo "${k8s_yml}" | yq -r ".[${i}].build   | select(. != null)")"
    local url="$(    echo "${k8s_yml}" | yq -r ".[${i}].url     | select(. != null)")"
    local domain="$( echo "${k8s_yml}" | yq -r ".[${i}].domain  | select(. != null)")"
    local port="$(   echo "${k8s_yml}" | yq -r ".[${i}].port    | select(. != null)")"

    if [[ 'false' == "${enabled}" ]]; then
      continue
    fi

    sudo kubectl create ns "${ns}" || true

    # TODO: イメージがローカルになければビルド
    # TODO: イメージ名
    if false && [[ 'true' == "${build}" ]]; then
      pushd "${home_dir}/src/docker/${xxx}/"
        build --no-cache --pull
      popd
    fi

    # config-map
#   local config_map_dir="${home_dir}/k8s/configmap/${ns}/${name}"
#   if [[ -d "${config_map_dir}" ]]; then
#     sudo kubectl create configmap -n "${ns}" "${name}" --from-file="${config_map_dir}"
#   fi

    # secret tls
    local tls_key="${secrets_dir}/pki/certs/${domain}/key"
    local tls_crt="${secrets_dir}/pki/certs/${domain}/crt"
    if [[ -n "${domain}" && -n "${port}" && -f "${tls_key}" && -f "${tls_crt}" ]]; then

      local secret_name="${name}-tls"

      # TODO: 例外実装。定義化するか共通化する。
      if [[ 'kubernetes-dashboard' == "${name}" ]]; then
        secret_name='kubernetes-dashboard-certs'
      fi

      # secrets
      sudo kubectl create secret -n "${ns}" tls "${secret_name}" --key "${tls_key}" --cert "${tls_crt}" || true

      # ingress
      sudo kubectl apply -n "${ns}" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${name}
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
    - hosts:
      - ${domain}
      secretName: ${secret_name}
  rules:
    - host: ${domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${name}
                port:
                  number: ${port}
EOF

    fi

    # manifest
    # TODO: 例外実装。定義化するか共通化する。
    if [[ -n "${url}" && 'ingress-nginx' == "${ns}" ]]; then

      curl "${url}" | \
        sed -E \
          -e 's#^([ ]+type: )NodePort$#\1LoadBalancer#g' \
          -e 's#^([ ]+)(targetPort: http)$#\1nodePort: 80#g' \
          -e 's#^([ ]+)(targetPort: https)$#\1nodePort: 443#g' \
          -e 's#^([ ]+)(- /nginx-ingress-controller)$#\1\2\n\1- --enable-ssl-passthrough#g' | \
        sudo kubectl apply -n "${ns}" -f /dev/stdin

      # TODO: ingress-nginx-controllerの起動が完了するまで待機

    elif [[ -n "${url}" ]]; then
      curl "${url}" | sudo kubectl apply -n "${ns}" -f /dev/stdin

    elif [[ -f "${home_dir}/src/k8s/manifest/${ns}/${name}.yml" ]]; then
      cat "${home_dir}/src/k8s/manifest/${ns}/${name}.yml" | envsubst | sudo kubectl apply -n "${ns}" -f /dev/stdin || true
    fi

  done

}

function sandbox() {

  local workdir='/sandbox'

  docker run \
    --interactive \
    --tty \
    --rm \
    --name 'sandbox' \
    --hostname 'sandbox' \
    --volume "${home_dir}/.dotfiles/":'/root/home/.dotfiles/':ro \
    --volume "${home_dir}/bin/":'/root/home/bin/':ro \
    --volume "${home_dir}/lib/":'/root/home/lib/':ro \
    --volume "${home_dir}/sbin/":'/root/home/sbin/':ro \
    --volume "${home_dir}/src/":'/root/home/src/':ro \
    --volume "${PWD}":"${workdir}":ro \
    --workdir "${workdir}" \
    docker.repos.tkyz.jp/builder:debian "$@"

#   --volume "${home_dir}/local/bin/":'/root/home/local/bin/':ro \
#   --volume "${home_dir}/local/lib/":'/root/home/local/lib/':ro \
#   --volume "${home_dir}/local/sbin/":'/root/home/local/sbin/':ro \
#   --volume "${home_dir}/local/src/":'/root/home/local/src/':ro \
#   --volume "${home_dir}/var/log/":'/root/home/var/log/' \
#   --volume "${home_dir}/var/log/":'/var/log/' \
#   --volume "${home_dir}/var/sandbox/":'/root/home/mnt/volumes/' \
#   --volume "${home_dir}/var/sandbox/":'/mnt/volumes/' \

}

function scan-eth() {
  sudo arp-scan -l -x 2> /dev/null | while read line; do

    local ip="$( echo "${line}" | awk -F ' ' '{print $1}')"
    local mac="$(echo "${line}" | awk -F ' ' '{print $2}')"

    local hostname="$(host "${ip}" | sed -r 's/.* domain name pointer ([^\.]+)\.lan\.$/\1/g' | grep -v 'not found')"
    hostname="${hostname:-unknown}"

    nmap ${ip} | grep -E -v '^[^0-9]+' 2> /dev/null | sed -E -e '/^$/d' -e "s/^/${mac} ${ip} ${hostname} /g" -e 's|[ /]+| |g'

  done
}

# TODO: 原因不明で暗くなるので、その対応
function set_max_brightness() {
  find /sys/class/backlight/ -mindepth 1 -maxdepth 1 -type l | while read line; do
    sudo cat "${line}/max_brightness" | sudo tee "${line}/brightness"
  done
  sudo shutdown now
}

# TODO: 実装
function exec-jar-gen() {
  cat <<EOF | cat /dev/stdin "${1}" > "${home_dir}/bin/${1}.sh"
EOF
}
