#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-go-tools] %s\n' "$*"; }

command -v go >/dev/null 2>&1 || {
  echo '[install-go-tools][error] go is not installed.' >&2
  exit 1
}

log 'installing/updating go tools'
go install github.com/charmbracelet/glow@latest

log 'done'
