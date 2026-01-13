#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# logging helpers
# -------------------------
log() { printf '[BOOTSTRAP] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

# -------------------------
# distro detection
# -------------------------
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID:-unknown}"
  DISTRO_LIKE="${ID_LIKE:-}"
  DISTRO_PRETTY="${PRETTY_NAME:-$DISTRO_ID}"
else
  die "unable to detect distro (missing /etc/os-release)"
fi

is_debian_like() { [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *debian* ]]; }
is_rhel_like()   { [[ "$DISTRO_ID" == "ol"     || "$DISTRO_ID" == "rhel"   || "$DISTRO_ID" == "centos" || "$DISTRO_ID" == "rocky" || "$DISTRO_LIKE" == *rhel* ]]; }

# -------------------------
# checkpoints
# -------------------------
CHECKPOINT_DIR="$HOME/.bootstrap_checkpoints"

ensure_checkpoint_dir() { mkdir -p "$CHECKPOINT_DIR"; }
is_done()               { [[ -f "$CHECKPOINT_DIR/$1.done" ]]; }
mark_done()             { : > "$CHECKPOINT_DIR/$1.done"; }

run_step() {
  # usage: run_step STEP_FUNCTION_NAME
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

# -------------------------
# locale ensure: en_US.UTF-8
# -------------------------
ensure_locale() {
  # accept either "en_US.utf8" or "en_US.UTF-8" as present
  if locale -a 2>/dev/null | grep -qiE '^(en_US\.utf8|en_US\.UTF-8)$'; then
    log "locale en_US.UTF-8 already available"
    return 0
  fi

  if is_debian_like; then
    log "generating locale en_US.UTF-8 (debian/ubuntu)"
    sudo sed -i 's/^[#[:space:]]*en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen
    sudo update-locale LANG=en_US.UTF-8
  elif is_rhel_like; then
    log "installing langpack and setting locale (rhel/ol8)"
    # minimal language data for English
    sudo dnf -y install glibc-langpack-en
    # set system default
    sudo localectl set-locale LANG=en_US.UTF-8
  else
    die "unsupported distro for locale configuration: $DISTRO_PRETTY"
  fi

  log "locale configured; some services may require restart or a reboot"
}

# -------------------------
# base packages
# -------------------------
install_base_packages() {
  if is_debian_like; then
    log "apt update and dist-upgrade"
    sudo apt update
    sudo apt -y dist-upgrade

    log "installing base packages (debian/ubuntu)"
    sudo apt install -y \
      openssh-server \
      openssh-client \
      git \
      curl \
      ca-certificates \
      build-essential \
      hostname

  elif is_rhel_like; then
    log "dnf update"
    sudo dnf -y update

    log "installing base packages (rhel/ol8)"
    sudo dnf -y install \
      openssh-server \
      openssh-clients \
      git \
      curl \
      ca-certificates \
      hostname

    # development toolchain equivalent to build-essential
    log "dnf groupinstall \"Development Tools\""
    sudo dnf -y group install "Development Tools"

    # ensure sshd is enabled if server package was newly installed
    if systemctl list-unit-files | grep -q '^sshd\.service'; then
      sudo systemctl enable --now sshd || true
    fi
  else
    die "unsupported distro for base packages: $DISTRO_PRETTY"
  fi
}

# -------------------------
# ssh keys and known_hosts
# -------------------------
setup_ssh() {
  install -d -m 700 "$HOME/.ssh"

  local USER_NAME="${USER:-$(id -un)}"
  local HOST_INFO
  HOST_INFO="$(hostname -f 2>/dev/null || hostname)"
  local OS_NAME="$DISTRO_PRETTY"
  local DATE_TAG
  DATE_TAG="$(date -u +%Y_%b_%d__%H.%M.%SZ)"

  local SSH_COMMENT="${USER_NAME}@${HOST_INFO}:${OS_NAME}:${DATE_TAG}"
  local KEY_PRIV="$HOME/.ssh/id_ed25519"
  local KEY_PUB="$HOME/.ssh/id_ed25519.pub"

  if [[ ! -f "$KEY_PRIV" ]]; then
    log "generating ed25519 ssh key"
    ssh-keygen -t ed25519 -a 100 -N "" -C "$SSH_COMMENT" -f "$KEY_PRIV"
  else
    log "ssh key already exists: $KEY_PRIV"
  fi

  ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
  sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts"
  chmod 644 "$HOME/.ssh/known_hosts"

  echo
  echo "ADD THIS SSH KEY TO GITHUB:"
  echo "-----------------------------------"
  cat "$KEY_PUB"
  echo "-----------------------------------"
  read -rp "press enter after adding the key..."
}

# -------------------------
# dotfiles
# -------------------------
clone_dot_repos() {
  cd "$HOME"

  if [[ ! -d dotfiles ]]; then
    git clone https://github.com/GLaDOS-418/dotfiles.git
    cd dotfiles
    git remote set-url origin git@github.com:glados-418/dotfiles.git
  else
    cd dotfiles
    git pull --rebase
  fi

  if [[ ! -d "$HOME/vim" ]]; then
    git clone https://github.com/glados-418/vim.git "$HOME/vim"
  fi
}

# -------------------------
# variables
# -------------------------
DOTFILES="$HOME/dotfiles"
DOTBASE="$DOTFILES/dotbase"
DOTINSTALL="$DOTFILES/dotinstall"
DOTRC="$DOTFILES/dotrc"
VIM="$HOME/vim"

# -------------------------
# package install from dotinstall (per distro file)
# -------------------------
install_extra_from_dotinstall() {
  cd "$DOTINSTALL" || return 0

  local PKGLIST_FILE=
  if is_debian_like && [[ -f "wsl-ubuntu" ]]; then
    PKGLIST_FILE="wsl-ubuntu"
  elif is_rhel_like && [[ -f "wsl-oracle" ]]; then
    PKGLIST_FILE="wsl-oracle"
  fi

  [[ -n "$PKGLIST_FILE" ]] || { log "no per-distro package list found in $DOTINSTALL"; return 0; }

  log "installing extra packages from $DOTINSTALL/$PKGLIST_FILE"
  # read non-empty, non-comment lines
  mapfile -t pkgs < <(grep -Ev '^\s*#|^\s*$' "$PKGLIST_FILE")

  if is_debian_like; then
    sudo DEBIAN_FRONTEND=noninteractive apt install -y "${pkgs[@]}"
  elif is_rhel_like; then
    sudo dnf -y install "${pkgs[@]}"
  fi
}

# -------------------------
# remove old configs (idempotent)
# -------------------------
remove_old_configs() {
  cd "$HOME"
  rm -f .{bashrc,inputrc,tmux.conf,gitconfig,rgignore,vimrc,gvimrc}
  rm -rf .vim .config/nvim
}

# -------------------------
# symlinks
# -------------------------
create_symlinks() {
  mkdir -p "$HOME/.config"

  ln -sf "$DOTBASE/bashrc"    "$HOME/.bashrc"
  ln -sf "$DOTBASE/inputrc"   "$HOME/.inputrc"
  ln -sf "$DOTBASE/tmux.conf" "$HOME/.tmux.conf"
  ln -sf "$DOTBASE/rgignore"  "$HOME/.rgignore"

  ln -sf "$VIM/nvim"          "$HOME/.config/nvim"
  ln -sf "$VIM/vim"           "$HOME/.vim"
  ln -sf "$VIM/vimrc"         "$HOME/.vimrc"
  ln -sf "$VIM/gvimrc"        "$HOME/.gvimrc"

  touch "$HOME/.gitconfig"
  git config --global include.path "$DOTRC/gitconfig-shared"

  if grep -qi microsoft /proc/version; then
    sudo cp "$DOTBASE/wsl.conf" /etc/wsl.conf
  fi
}

# -------------------------
# main
# -------------------------
ensure_checkpoint_dir

log "distro: $DISTRO_PRETTY ($DISTRO_ID)"
read -r -p "Do you want to perform from start? type 'yes' to start from the beginning [default: NO]: " START_OVER
if [[ "${START_OVER,,}" == "yes" ]]; then
  rm -rf "$CHECKPOINT_DIR"
  ensure_checkpoint_dir
  log "resetting checkpoints and starting from the beginning"
fi

run_step ensure_locale
run_step install_base_packages
run_step setup_ssh
run_step clone_dot_repos
run_step install_extra_from_dotinstall
run_step remove_old_configs
run_step create_symlinks

echo
echo "==== bootstrap complete on ${DISTRO_PRETTY} ===="
echo "==== for language supports see install_* functions in ${DOTRC}/languagerc ===="

