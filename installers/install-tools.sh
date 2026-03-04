#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[install-tools] %s\n' "$*"; }
warn() { printf '[install-tools][warn] %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install_fzf() {
  if [[ -d "$HOME/.fzf/.git" ]]; then
    log 'updating fzf'
    git -C "$HOME/.fzf" pull --rebase || warn 'failed to update fzf repo'
  else
    log 'cloning fzf'
    git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi

  "$HOME/.fzf/install" --all --no-update-rc
}

install_languagetool() {
  command -v unzip >/dev/null 2>&1 || {
    warn 'unzip not found; skipping LanguageTool'
    return 0
  }

  local tmpdir zip_path base_dir latest_dir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  zip_path="$tmpdir/LanguageTool-stable.zip"
  base_dir="$HOME/.local/share"

  log 'downloading LanguageTool'
  curl -fsSL "https://languagetool.org/download/LanguageTool-stable.zip" -o "$zip_path"

  mkdir -p "$base_dir"
  unzip -oq "$zip_path" -d "$base_dir"

  latest_dir="$(find "$base_dir" -maxdepth 1 -type d -name 'LanguageTool-*' | sort | tail -n1)"
  if [[ -n "$latest_dir" ]]; then
    ln -sfn "$latest_dir" "$base_dir/LanguageTool"
  fi
}

install_fzf
install_languagetool

bash "$SCRIPT_DIR/install-rust-tools.sh"
bash "$SCRIPT_DIR/install-go-tools.sh"
bash "$SCRIPT_DIR/install-npm-tools.sh"
bash "$SCRIPT_DIR/install-python-tools.sh"

if command -v bob >/dev/null 2>&1; then
  bob use nightly || warn 'bob use nightly failed'
else
  warn 'bob not found; skipping bob nightly selection'
fi

if command -v nvim >/dev/null 2>&1; then
  nvim --headless '+PlugInstall --sync' +qa || warn 'nvim PlugInstall failed'
else
  warn 'nvim not found; skipping PlugInstall'
fi

log 'done'
