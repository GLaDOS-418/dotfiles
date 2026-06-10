# shellcheck shell=bash

_dot_configure_tools_bridge() {
  # ~/.configure_tools.sh is zsh-owned local state. Bash cannot source it
  # directly, so zsh sources it and prints shell-quoted exports for bash.
  local helper="$HOME/.configure_tools.sh"
  [[ -f "$helper" ]] || return 0
  command -v zsh >/dev/null 2>&1 || return 0

  local exports
  exports="$(
    HOME="$HOME" zsh -f -c '
      source "$HOME/.configure_tools.sh" >/dev/null
      for name in AWS_CA_BUNDLE REQUESTS_CA_BUNDLE SSL_CERT_FILE CURL_CA_BUNDLE NODE_EXTRA_CA_CERTS GIT_SSL_CAPATH; do
        if (( ${+parameters[$name]} )); then
          value="${(P)name}"
          print -r -- "export ${name}=${(qq)value}"
        else
          print -r -- "unset ${name}"
        fi
      done
    '
  )" || return 0

  [[ -n "$exports" ]] && eval "$exports"
}

_dot_configure_tools_bridge
unset -f _dot_configure_tools_bridge 2>/dev/null || true
