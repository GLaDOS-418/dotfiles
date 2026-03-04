#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '[post-setup] %s\n' "$*"; }
warn() { printf '[post-setup][warn] %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
LANGUAGERC="$DOTFILES/shell-config/languagerc"

ASSUME_YES=false
RUN_PLUGINS=true
RUN_LANGUAGES=true
LANGS=(cpp rust go java node)

usage() {
  cat <<'USAGE'
Usage: post-setup.sh [options]

Options:
  --yes                 Run non-interactively where possible.
  --plugins-only        Run only Vim/Neovim plugin installs.
  --languages-only      Run only language setup helpers.
  --langs a,b,c         Limit languages (default: cpp,rust,go,java,node).
  -h, --help            Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y|--non-interactive)
      ASSUME_YES=true
      ;;
    --plugins-only)
      RUN_PLUGINS=true
      RUN_LANGUAGES=false
      ;;
    --languages-only)
      RUN_PLUGINS=false
      RUN_LANGUAGES=true
      ;;
    --langs)
      [[ $# -ge 2 ]] || { echo '[post-setup][error] --langs needs a value' >&2; exit 1; }
      IFS=',' read -r -a LANGS <<< "$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[post-setup][error] unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

run_plugins() {
  log 'running non-interactive plugin install/update'

  if command -v nvim >/dev/null 2>&1; then
    nvim --headless '+PlugInstall --sync' +qa || warn 'Neovim plugin install failed'
  else
    warn 'nvim not found; skipping Neovim plugin step'
  fi

  if command -v vim >/dev/null 2>&1 && [[ -f "$HOME/vim/vimrc" ]]; then
    vim -E -s -u "$HOME/vim/vimrc" '+PlugInstall --sync' +qa || warn 'Vim plugin install failed'
  else
    warn 'vim or $HOME/vim/vimrc not found; skipping Vim plugin step'
  fi
}

run_languages() {
  [[ -f "$LANGUAGERC" ]] || { warn "missing $LANGUAGERC; skipping language setup"; return 0; }

  # shellcheck disable=SC1090
  source "$LANGUAGERC"

  if ! $ASSUME_YES; then
    printf 'Run language installers now (%s)? [y/N]: ' "${LANGS[*]}"
    read -r ans
    ans="${ans,,}"
    [[ "$ans" == y* ]] || { log 'language setup skipped by user'; return 0; }
  fi

  for lang in "${LANGS[@]}"; do
    lang="${lang,,}"
    fn="install_${lang}"

    if [[ "$lang" == "cpp" ]] && ! command -v apt-get >/dev/null 2>&1; then
      warn 'install_cpp currently targets apt-based systems; skipping on this distro'
      continue
    fi

    if declare -F "$fn" >/dev/null 2>&1; then
      log "running $fn"
      "$fn" || warn "$fn failed"
    else
      warn "installer function not found: $fn"
    fi
  done
}

main() {
  if $RUN_PLUGINS; then
    run_plugins
  fi

  if $RUN_LANGUAGES; then
    run_languages
  fi

  log 'post setup complete'
}

main "$@"
