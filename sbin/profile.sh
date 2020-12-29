umask 0022

export HOME_DIR="${HOME:-/root}/home"
export HOME_YML="${HOME:-/root}/home.yml"

chmod 600 "${HOME_YML}"
find "${HOME_DIR}/.pki" -type f                                 | xargs --no-run-if-empty chmod 600
find "${HOME_DIR}/.pki" -type f -name pub -or -type f -name crt | xargs --no-run-if-empty chmod 644
find "${HOME_DIR}/.pki" -type d                                 | xargs --no-run-if-empty chmod 755

export LANG='ja_JP.UTF-8'

if ! echo "${PATH}" | sed 's/:/\n/g' | grep -q "^${HOME_DIR}/bin$"       2> /dev/null; then PATH="${HOME_DIR}/bin:${PATH}"; fi
if ! echo "${PATH}" | sed 's/:/\n/g' | grep -q "^${HOME_DIR}/local/bin$" 2> /dev/null; then PATH="${HOME_DIR}/local/bin:${PATH}"; fi

export CLASSPATH
if ! echo "${CLASSPATH}" | sed 's/:/\n/g' | grep -q "^${HOME_DIR}/lib/\*$"       2> /dev/null; then CLASSPATH="${HOME_DIR}/lib/*:${CLASSPATH}"; fi
if ! echo "${CLASSPATH}" | sed 's/:/\n/g' | grep -q "^${HOME_DIR}/local/lib/\*$" 2> /dev/null; then CLASSPATH="${HOME_DIR}/local/lib/*:${CLASSPATH}"; fi
if ! echo "${CLASSPATH}" | sed 's/:/\n/g' | grep -q '^./*$'                      2> /dev/null; then CLASSPATH="./*:${CLASSPATH}"; fi
if ! echo "${CLASSPATH}" | sed 's/:/\n/g' | grep -q '^.$'                        2> /dev/null; then CLASSPATH=".:${CLASSPATH}"; fi

# home.env
if [[ -f "${HOME_YML}" ]]; then

  yml="$(yq -r '.home.env | select(. != null)' "${HOME_YML}")"

  while read key; do

    vals="$(echo "${yml}" | yq -r ".${key}")"

    while read val; do
      export "${key}"="$(echo "${val}" | envsubst)"
    done < <(echo "${vals}" | yq -r 'select(type == "string") | .')

    # TODO: +=
    while read val; do
      true
#     export "${key}"="$(echo "${val}" | envsubst)"
    done < <(echo "${vals}" | yq -r 'select(type == "array") | .[]')

  done < <(echo "${yml}" | yq -r 'keys[]')
  unset yml
  unset key
  unset val
  unset vals

fi

# color
txtred='\e[31m' # Red
txtgrn='\e[32m' # Green
txtylw='\e[33m' # Yellow
txtblu='\e[34m' # Blue
txtpur='\e[35m' # Purple
txtcyn='\e[36m' # Cyan
txtwht='\e[37m' # White
txtrst='\e[0m'  # Reset

# trap
function trap_err() {

  local status="${?}"

  local txtset='\e[91m'

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

alias ..='cd .. '
alias ls='ls --color=auto --show-control-chars --time-style=+%Y-%m-%d\ %H:%M:%S '
alias la='ls -a '
alias ll='la -lFh '
alias curl='curl -fL '
alias vi='vim '
alias gs='git status '

if [[ 0 == "$(id -u)" ]]; then
  alias sudo=' '
else
  alias sudo='sudo '
fi

alias sstatus=' sudo systemctl status '
alias sstart='  sudo systemctl start '
alias sstop='   sudo systemctl stop '
alias srestart='sudo systemctl restart '

alias reboot='sudo shutdown now -r '
alias relogin='exec "${SHELL:-bash}" -l '

alias timestamp='date "+%Y%m%d_%H%M%S" '

#----------------------------------------------------------------
# function

function pushd() {
  mkdir -p "${1}"
  command pushd "${1}" > /dev/null
}
function popd() {
  command popd > /dev/null
}

#----------------------------------------------------------------
# if is_xxx; then ...

alias is_root='    ( test ! -f "${HOME_DIR}/.pki/root@home/pub" || diff -q "${HOME_DIR}/.pki/root@home/pub" "${HOME_DIR}/.pki/node@home/pub" > /dev/null 2>&1 ) '
alias is_ssh='     ( test -v SSH_CLIENT || test -v SSH_CONNECTION ) '
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

#function is_cmd() {
#  type "${1}" > /dev/null 2>&1
#}

function is_tcp_conn() {
  timeout 1 bash -c "cat /dev/null > /dev/tcp/${1}/${2}" 2> /dev/null
}

#----------------------------------------------------------------
# reload

function git_cat() {

  local path="${1}"

  if [[ -v DOCKER_BUILDING && -f "/workdir${path}" ]]; then
    cat "/workdir${path}"

  elif [[ -f "${HOME_DIR}${path}" ]]; then
    cat "${HOME_DIR}${path}"

  elif is_tcp_conn raw.home 443; then
    curl "https://raw.home${path}" 2> /dev/null

  elif is_tcp_conn github.jp 443; then
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

#----------------------------------------------------------------
# prompt
if true; then

  PS1=''
# PS2=
# PS3=
# PS4=

  # TODO: IPの範囲で色変えたい
  # ssh接続情報
  if is_ssh; then
    PS1+="[${txtylw}$(echo "${SSH_CONNECTION}" | awk -F ' ' '{print $1 ":" $2}')${txtrst}->${txtylw}$(echo "${SSH_CONNECTION}" | awk -F ' ' '{print $3 ":" $4}')${txtrst}]"
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

#----------------------------------------------------------------
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
