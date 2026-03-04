#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-rust-tools] %s\n' "$*"; }

command -v cargo >/dev/null 2>&1 || {
  echo '[install-rust-tools][error] cargo is not installed.' >&2
  exit 1
}

crates=(
  bat
  bob-nvim
  du-dust
  fd-find
  git-delta
  navi
  ripgrep
  sd
  tree-sitter-cli
  typos-cli
  zoxide
)

log 'installing/updating rust tools'
for crate in "${crates[@]}"; do
  cargo install --locked --force "$crate"
done

log 'done'
