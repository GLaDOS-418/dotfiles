#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-snap] %s\n' "$*"; }
warn() { printf '[install-snap][warn] %s\n' "$*" >&2; }

command -v snap >/dev/null 2>&1 || {
  echo '[install-snap][error] snap is not installed.' >&2
  exit 1
}

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now snapd.socket || warn 'could not enable snapd.socket'
else
  warn 'systemctl not found; skipping snapd.socket setup'
fi

if [[ ! -e /snap && -d /var/lib/snapd/snap ]]; then
  sudo ln -s /var/lib/snapd/snap /snap || true
fi

snaps=(
  hugo
  docker
)

for pkg in "${snaps[@]}"; do
  if snap list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$pkg"; then
    log "$pkg already installed"
  else
    log "installing $pkg"
    sudo snap install "$pkg"
  fi
done

log 'done'
