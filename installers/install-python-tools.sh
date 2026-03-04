#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-python-tools] %s\n' "$*"; }

command -v python3 >/dev/null 2>&1 || {
  echo '[install-python-tools][error] python3 is not installed.' >&2
  exit 1
}

python3 -m pip install --user --upgrade pip pipx
export PATH="$HOME/.local/bin:$PATH"
python3 -m pipx ensurepath >/dev/null 2>&1 || true

command -v pipx >/dev/null 2>&1 || {
  echo '[install-python-tools][error] pipx is not available on PATH after install.' >&2
  exit 1
}

install_or_upgrade() {
  local pkg="$1"
  shift || true

  if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx "$pkg"; then
    log "upgrading $pkg"
    pipx upgrade "$pkg" || true
  else
    log "installing $pkg"
    pipx install "$pkg" "$@"
  fi
}

install_or_upgrade yt-dlp
install_or_upgrade bpytop
install_or_upgrade conan
install_or_upgrade thefuck
install_or_upgrade jupyter --include-deps
install_or_upgrade animdl

log 'done'
