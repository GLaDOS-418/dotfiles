#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '[dot_setup] %s\n' "$*"; }
warn() { printf '[dot_setup][warn] %s\n' "$*" >&2; }
die()  { printf '[dot_setup][error] %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$SCRIPT_DIR}"
DOTBASE="$DOTFILES/dotbase"
DOTINSTALL="$DOTFILES/dotinstall"
DOTRC="$DOTFILES/dotrc"
VIM="${VIM:-$HOME/vim}"

CHECKPOINT_DIR="${HOME}/.dot_setup_checkpoints"
START_OVER=false
ASSUME_YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start-over)
      START_OVER=true
      ;;
    -y|--yes|--non-interactive)
      ASSUME_YES=true
      ;;
    *)
      die "unknown argument: $1 (supported: --start-over, --yes)"
      ;;
  esac
  shift
done

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_LIKE="${ID_LIKE:-}"
  OS_PRETTY="${PRETTY_NAME:-$OS_ID}"
else
  die "cannot detect distro: /etc/os-release not found"
fi

is_wsl() {
  grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null || \
  grep -qi microsoft /proc/version 2>/dev/null
}

pkg_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  else
    echo "unknown"
  fi
}

PKG_MGR="$(pkg_manager)"
[[ "$PKG_MGR" != "unknown" ]] || die "unsupported distro/package manager: $OS_PRETTY"

ensure_checkpoint_dir() { mkdir -p "$CHECKPOINT_DIR"; }
is_done()               { [[ -f "$CHECKPOINT_DIR/$1.done" ]]; }
mark_done()             { : > "$CHECKPOINT_DIR/$1.done"; }

run_step() {
  local step="$1"
  if is_done "$step"; then
    log "skip $step (already done)"
    return 0
  fi

  log "running $step"
  "$step"
  mark_done "$step"
  log "completed $step"
}

require_file() {
  [[ -e "$1" ]] || die "missing required file: $1"
}

ensure_locale() {
  log "ensuring locale en_US.UTF-8"

  case "$PKG_MGR" in
    pacman|apt)
      if [[ -f /etc/locale.gen ]]; then
        if grep -Eq '^[[:space:]]*#?[[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8' /etc/locale.gen; then
          sudo sed -i -E 's/^[[:space:]]*#?[[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        else
          echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
        fi
        sudo locale-gen || warn "locale-gen failed; continuing"
      else
        warn "/etc/locale.gen not found; skipping locale-gen"
      fi

      if [[ "$PKG_MGR" == "apt" ]] && command -v update-locale >/dev/null 2>&1; then
        sudo update-locale LANG=en_US.UTF-8 || warn "update-locale failed; continuing"
      elif [[ "$PKG_MGR" == "pacman" ]]; then
        echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null || warn "failed to write /etc/locale.conf"
      fi
      ;;
    dnf)
      sudo dnf -y install glibc-langpack-en || warn "failed installing glibc-langpack-en"
      if command -v localectl >/dev/null 2>&1; then
        sudo localectl set-locale LANG=en_US.UTF-8 || warn "localectl failed; writing /etc/locale.conf"
      fi
      echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null || warn "failed to write /etc/locale.conf"
      ;;
  esac
}

install_base_packages() {
  log "installing base packages for $PKG_MGR"
  case "$PKG_MGR" in
    pacman)
      sudo pacman -Syu --noconfirm || true
      sudo pacman -S --needed --noconfirm openssh git curl ca-certificates base-devel
      ;;
    apt)
      sudo apt-get update
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        openssh-server openssh-client git curl ca-certificates build-essential
      ;;
    dnf)
      sudo dnf -y update
      sudo dnf -y install openssh-server openssh-clients git curl ca-certificates
      sudo dnf -y group install "Development Tools" || true
      ;;
  esac
}

verify_bootstrap_tools() {
  need_cmd git
  need_cmd curl
  need_cmd ssh-keygen
  need_cmd ssh-keyscan
}

prompt_ssh_setup() {
  local ans="y"
  if ! $ASSUME_YES; then
    read -r -p "Generate SSH key if missing? [Y/n]: " ans
    ans="${ans,,}"
  fi

  install -d -m 700 "$HOME/.ssh"

  if [[ "$ans" != "n" && ! -f "$HOME/.ssh/id_ed25519" ]]; then
    local user_name host_info date_tag comment
    user_name="${USER:-$(id -un)}"
    host_info="$(hostname -f 2>/dev/null || hostname)"
    date_tag="$(date -u +%Y-%m-%d)"
    comment="${user_name}@${host_info}:${OS_ID}:${date_tag}"

    log "generating ed25519 key"
    ssh-keygen -t ed25519 -a 100 -N "" -C "$comment" -f "$HOME/.ssh/id_ed25519"
  fi

  ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
  sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts" || true
  chmod 644 "$HOME/.ssh/known_hosts" || true

  if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo
    echo "ADD THIS SSH KEY TO GITHUB:"
    echo "-----------------------------------"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "-----------------------------------"
    echo
    if ! $ASSUME_YES; then
      read -r -p "Press Enter after adding the key (or Ctrl+C to stop)... " _
    fi
  else
    warn "no public key found at ~/.ssh/id_ed25519.pub; continuing with HTTPS clone"
  fi
}

clone_or_update_repo() {
  local url_https="$1"
  local dst="$2"

  if [[ -d "$dst/.git" ]]; then
    log "updating $(basename "$dst")"
    if [[ -n "$(git -C "$dst" status --porcelain 2>/dev/null || true)" ]]; then
      warn "repo has local changes; skipping pull for $dst"
      return 0
    fi
    git -C "$dst" pull --rebase || warn "git pull failed for $dst"
  else
    log "cloning $(basename "$dst")"
    git clone "$url_https" "$dst"
  fi
}

clone_repos() {
  clone_or_update_repo "https://github.com/GLaDOS-418/dotfiles.git" "$DOTFILES"
  clone_or_update_repo "https://github.com/glados-418/vim.git" "$VIM"

  if [[ -d "$DOTFILES/.git" && -f "$HOME/.ssh/id_ed25519" ]]; then
    git -C "$DOTFILES" remote set-url origin git@github.com:glados-418/dotfiles.git || true
  fi
}

selected_pkglist() {
  case "$PKG_MGR" in
    pacman)
      echo "$DOTINSTALL/wsl-arch"
      ;;
    apt)
      echo "$DOTINSTALL/wsl-ubuntu"
      ;;
    dnf)
      echo "$DOTINSTALL/wsl-oracle"
      ;;
  esac
}

install_packages_from_list() {
  local list_file="$1"
  [[ -f "$list_file" ]] || { warn "package list not found: $list_file"; return 0; }

  mapfile -t pkgs < <(grep -Ev '^[[:space:]]*(#|$)' "$list_file")
  [[ ${#pkgs[@]} -gt 0 ]] || { log "no packages in $list_file"; return 0; }

  log "installing packages from $(basename "$list_file")"
  local failed=()
  local p

  case "$PKG_MGR" in
    pacman)
      sudo pacman -Sy --noconfirm || true
      for p in "${pkgs[@]}"; do
        if ! sudo pacman -S --needed --noconfirm "$p"; then
          failed+=("$p")
        fi
      done
      ;;
    apt)
      sudo apt-get update || true
      for p in "${pkgs[@]}"; do
        if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$p"; then
          failed+=("$p")
        fi
      done
      ;;
    dnf)
      for p in "${pkgs[@]}"; do
        if ! sudo dnf -y install "$p"; then
          failed+=("$p")
        fi
      done
      ;;
  esac

  if [[ ${#failed[@]} -gt 0 ]]; then
    warn "some packages failed from $(basename "$list_file"): ${failed[*]}"
  fi
}

install_distro_packages() {
  install_packages_from_list "$(selected_pkglist)"
}

install_optional_tools() {
  if [[ "$PKG_MGR" == "pacman" && -f "$DOTINSTALL/yaylist" ]]; then
    if command -v yay >/dev/null 2>&1; then
      mapfile -t yay_pkgs < <(grep -Ev '^[[:space:]]*(#|$)' "$DOTINSTALL/yaylist")
      if [[ ${#yay_pkgs[@]} -gt 0 ]]; then
        log "installing packages from yaylist"
        yay --needed --noconfirm -S "${yay_pkgs[@]}" || warn "some yay packages failed"
      fi
    else
      warn "yay not installed; skipping yaylist"
    fi
  fi

  if command -v snap >/dev/null 2>&1 && [[ -f "$DOTINSTALL/snaplist" ]]; then
    log "installing packages from snaplist"
    sudo systemctl enable --now snapd.socket || true
    [[ -e /snap ]] || sudo ln -s /var/lib/snapd/snap /snap || true
    while IFS= read -r pkg; do
      [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
      sudo snap install "$pkg" || warn "snap install failed: $pkg"
    done < "$DOTINSTALL/snaplist"
  fi
}

verify_references() {
  require_file "$DOTBASE/bashrc"
  require_file "$DOTBASE/bashrc_common"
  require_file "$DOTBASE/bashrc_interactive"
  require_file "$DOTBASE/inputrc"
  require_file "$DOTBASE/tmux.conf"
  require_file "$DOTBASE/rgignore"
  require_file "$DOTRC/gitconfig-shared"

  require_file "$(selected_pkglist)"

  require_file "$VIM/vimrc"
  require_file "$VIM/gvimrc"
  require_file "$VIM/vim"
  require_file "$VIM/nvim"

  if is_wsl; then
    require_file "$DOTBASE/wsl.conf"
  fi
}

remove_old_configs() {
  rm -f "$HOME/.bashrc" "$HOME/.inputrc" "$HOME/.tmux.conf" "$HOME/.rgignore"
  rm -f "$HOME/.vimrc" "$HOME/.gvimrc"
  rm -rf "$HOME/.vim" "$HOME/.config/nvim"
}

create_symlinks() {
  mkdir -p "$HOME/.config"

  ln -sfn "$DOTBASE/bashrc" "$HOME/.bashrc"
  ln -sfn "$DOTBASE/inputrc" "$HOME/.inputrc"
  ln -sfn "$DOTBASE/tmux.conf" "$HOME/.tmux.conf"
  ln -sfn "$DOTBASE/rgignore" "$HOME/.rgignore"

  ln -sfn "$VIM/nvim" "$HOME/.config/nvim"
  ln -sfn "$VIM/vim" "$HOME/.vim"
  ln -sfn "$VIM/vimrc" "$HOME/.vimrc"
  ln -sfn "$VIM/gvimrc" "$HOME/.gvimrc"

  touch "$HOME/.gitconfig"
  git config --global include.path "$DOTRC/gitconfig-shared"

  if is_wsl; then
    sudo cp "$DOTBASE/wsl.conf" /etc/wsl.conf
  fi
}

main() {
  need_cmd sudo

  ensure_checkpoint_dir
  if $START_OVER; then
    rm -rf "$CHECKPOINT_DIR"
    ensure_checkpoint_dir
    log "reset checkpoints and restarting from beginning"
  fi

  log "detected distro: $OS_PRETTY ($OS_ID); package manager: $PKG_MGR"
  if is_wsl; then
    log "WSL environment detected"
  else
    warn "WSL not detected; continuing anyway"
  fi

  run_step ensure_locale
  run_step install_base_packages
  run_step verify_bootstrap_tools
  run_step prompt_ssh_setup
  run_step clone_repos
  run_step verify_references
  run_step install_distro_packages
  run_step install_optional_tools
  run_step remove_old_configs
  run_step create_symlinks

  log "setup completed successfully"
  log "open a new shell (or run: source ~/.bashrc)"
}

main "$@"
