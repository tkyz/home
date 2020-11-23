if [[ -n "${BASH_VERSION:-}" && -f "${HOME}/.bashrc" ]]; then
  source "${HOME}/.bashrc"
fi

# disabled
if false; then

  if [[ -d "${HOME}/bin" ]]; then
    PATH="${HOME}/bin:${PATH}"
  fi

  if [[ -d "${HOME}/.local/bin" ]]; then
    PATH="${HOME}/.local/bin:${PATH}"
  fi

fi
