#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-universal-ctags] %s\n' "$*"; }

detect_pkg_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo pacman
  elif command -v apt-get >/dev/null 2>&1; then
    echo apt
  elif command -v dnf >/dev/null 2>&1; then
    echo dnf
  else
    echo unknown
  fi
}

install_deps() {
  local pkg_mgr="$1"
  case "$pkg_mgr" in
    pacman)
      sudo pacman -Sy --noconfirm
      sudo pacman -S --needed --noconfirm autoconf automake pkgconf jansson libseccomp gcc make
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y autoconf automake pkg-config libjansson-dev libseccomp-dev gcc make
      ;;
    dnf)
      sudo dnf -y install autoconf automake pkgconf-pkg-config jansson-devel libseccomp-devel gcc make
      ;;
  esac
}

PKG_MGR="$(detect_pkg_manager)"
[[ "$PKG_MGR" != 'unknown' ]] || {
  echo '[install-universal-ctags][error] unsupported distro/package manager' >&2
  exit 1
}

install_deps "$PKG_MGR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

log 'cloning universal-ctags'
git clone --depth=1 https://github.com/universal-ctags/ctags.git "$tmpdir/ctags"

cd "$tmpdir/ctags"
./autogen.sh
./configure --prefix=/usr/local
make -j"$(nproc)"
sudo make install

if command -v ctags >/dev/null 2>&1; then
  ctags --version | head -n1
fi

log 'done'
