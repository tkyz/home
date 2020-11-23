if [[ -t 0 && -t 1 && -t 2 ]]; then

  # TODO: 重複箇所で定義 home_dir
  if [[ -f '/etc/profile.d/home.sh' ]]; then
    source '/etc/profile.d/home.sh'
  elif [[ -f "${HOME:-/root}/home/sbin/profile.sh" ]]; then
    source "${HOME:-/root}/home/sbin/profile.sh"
  fi

  if grep -q '^ID=alpine$' /etc/os-release 2> /dev/null; then
    alias ls='ls --color=auto'
  else
    alias grep='grep --color=auto --line-buffered'
    alias egrep='egrep --color=auto --line-buffered'
    alias fgrep='fgrep --color=auto --line-buffered'
  fi

  alias cp='cp -iv'
  alias mv='mv -iv'
  alias rm='rm -iv'

  alias tree='tree -C'
  alias less='less -rn'
  alias diff='diff -sq'

  alias w='w -ui'
  alias who='who -aH'
  alias df='df -h'
  alias od='od -Ax -tx1z'

  #----------------------------------------------------------------
  # ssh-agent

  if type ssh-agent > /dev/null 2>&1 && type ssh-add > /dev/null 2>&1 && [[ -d "${HOME}/.ssh" && ! -f /.dockerenv ]] && [[ ! -v SSH_CLIENT && ! -v SSH_CONNECTION && ! -v SSH_TTY ]]; then

    agent_pid=''
    if [[ "${OSTYPE}" == cygwin ]]; then
      agent_pid="$(ps     -u "${UID}" | grep ssh-agent | grep -v grep | xargs | cut -d ' ' -f 1)"
    else
      agent_pid="$(ps -ef -u "${UID}" | grep ssh-agent | grep -v grep | xargs | cut -d ' ' -f 2)"
    fi

    if [[ -z "${agent_pid}" ]]; then
      eval "$(ssh-agent)"
    else
      export SSH_AGENT_PID="${agent_pid}"
      export SSH_AUTH_SOCK="$(ls -t /tmp/ssh-*/agent.* | head -n 1 | cut -d ' ' -f 1)"
    fi

    if ! ssh-add -l > /dev/null 2>&1; then
      eval ssh-add \
        "${HOME}/.ssh/id_rsa" \
        "${HOME}/.ssh/**/id_rsa" \
        "${HOME}/.secrets/pki/key" \
        "${HOME}/.secrets/ssh/**/key" 2> /dev/null
    fi

    unset agent_pid

  fi

fi
