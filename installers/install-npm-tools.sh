#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-npm-tools] %s\n' "$*"; }

command -v npm >/dev/null 2>&1 || {
  echo '[install-npm-tools][error] npm is not installed.' >&2
  exit 1
}

packages=(
  diff-so-fancy
  git-trim
  wsl-open
  generate
  generate-license
)

log 'installing/updating npm global tools'
npm install -g "${packages[@]}"

log 'done'
