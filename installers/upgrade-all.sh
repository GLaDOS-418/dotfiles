#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[upgrade-all] %s\n' "$*"; }
warn() { printf '[upgrade-all][warn] %s\n' "$*" >&2; }

if command -v pipx >/dev/null 2>&1; then
  log 'upgrading pipx packages'
  pipx upgrade-all
else
  warn 'pipx not found; skipping pipx upgrades'
fi

if command -v cargo-install-update >/dev/null 2>&1; then
  log 'upgrading cargo-installed crates via cargo-install-update'
  cargo install-update -a
elif command -v cargo >/dev/null 2>&1; then
  warn 'cargo-install-update not found; skipping cargo install-update -a'
else
  warn 'cargo not found; skipping cargo upgrades'
fi

if command -v npm >/dev/null 2>&1; then
  log 'upgrading global npm packages'
  npm update -g
else
  warn 'npm not found; skipping npm upgrades'
fi

log 'done'
