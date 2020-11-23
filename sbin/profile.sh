umask 0022

# TODO: 重複箇所で定義 home_dir
home_dir="${HOME:-/root}/home"
secrets_dir="${HOME:-/root}/.secrets"
home_yml="${secrets_dir}/home.yml"

root_pub="${home_dir}/sbin/pub"
root_crt="${home_dir}/sbin/ca.crt"

node_key="${secrets_dir}/pki/key"
node_pub="${secrets_dir}/pki/pub"
node_csr="${secrets_dir}/pki/csr"
node_crt="${secrets_dir}/pki/crt"

export LANG='ja_JP.UTF-8'

if [[ -d "${home_dir}" ]]; then

  if ! echo "${PATH}" | grep -q "${home_dir}/bin:"       2> /dev/null; then PATH="${home_dir}/bin:${PATH}";       fi
  if ! echo "${PATH}" | grep -q "${home_dir}/local/bin:" 2> /dev/null; then PATH="${home_dir}/local/bin:${PATH}"; fi

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
