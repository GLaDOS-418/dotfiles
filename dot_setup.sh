#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '[dot_setup] %s\n' "$*"; }
warn() { printf '[dot_setup][warn] %s\n' "$*" >&2; }
die()  { printf '[dot_setup][error] %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

ENABLE_SSHD=0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Normal first-run path: this file is downloaded as ~/dot_setup.sh, then it
# clones ~/dotfiles and continues with files from that repo. When developing
# inside the repo, use the checkout directly so edits can be tested in place.
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
if [[ -f "$SCRIPT_DIR/.root" && -d "$SCRIPT_DIR/home-config" ]]; then
  DOTFILES="$SCRIPT_DIR"
fi
VIM="${VIM:-$HOME/vim}"

CHECKPOINT_ROOT="${HOME}/.dot_setup_checkpoints"
START_OVER=false
ASSUME_YES=false
RUN_POST_SETUP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start-over)
      START_OVER=true
      ;;
    -y|--yes|--non-interactive)
      ASSUME_YES=true
      ;;
    --run-post-setup)
      RUN_POST_SETUP=true
      ;;
    *)
      die "unknown argument: $1 (supported: --start-over, --yes, --run-post-setup)"
      ;;
  esac
  shift
done

UNAME_S="$(uname -s)"

# Keep OS detection separate from package installation. The package lists live
# under installers/* so macOS can follow the same flow as the WSL distros.
detect_os() {
  case "$UNAME_S" in
    Darwin)
      OS_ID="macos"
      OS_LIKE="darwin"
      if command -v sw_vers >/dev/null 2>&1; then
        OS_PRETTY="$(sw_vers -productName) $(sw_vers -productVersion)"
      else
        OS_PRETTY="macOS"
      fi
      ;;
    Linux)
      if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_LIKE="${ID_LIKE:-}"
        OS_PRETTY="${PRETTY_NAME:-$OS_ID}"
      else
        die "cannot detect distro: /etc/os-release not found"
      fi
      ;;
    *)
      die "unsupported OS: $UNAME_S"
      ;;
  esac
}

is_macos() { [[ "$UNAME_S" == "Darwin" ]]; }

is_wsl() {
  [[ "$UNAME_S" == "Linux" ]] || return 1
  grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null || \
  grep -qi microsoft /proc/version 2>/dev/null
}

pkg_manager() {
  if is_macos; then
    echo "brew"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  else
    echo "unknown"
  fi
}

refresh_dotfile_paths() {
  # DOTFILES can change after clone_repos when this script starts outside the
  # repo, so derived paths are refreshed after cloning.
  DOTBASE="$DOTFILES/home-config"
  DOTINSTALL="$DOTFILES/installers"
  DOTRC="$DOTFILES/shell-config"
}

detect_os
PKG_MGR="$(pkg_manager)"
[[ "$PKG_MGR" != "unknown" ]] || die "unsupported distro/package manager: $OS_PRETTY"
CHECKPOINT_DIR="$CHECKPOINT_ROOT/$OS_ID"
refresh_dotfile_paths

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

read_list_file() {
  local list_file="$1"
  local _n_ref="$2"
  local line

  # Bash 3.2 has no namerefs or mapfile, so append through eval carefully.
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      ''|[[:space:]]'#'*|'#'*)
        continue
        ;;
    esac
    eval "$_n_ref+=(\"\$line\")"
  done < "$list_file"
}

ensure_locale() {
  if is_macos; then
    log "macOS manages locale through system settings; skipping locale-gen"
    return 0
  fi

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
    brew)
      # macOS has no distro package manager on a fresh install. This step only
      # gets Homebrew online so the later common package-list step can use it.
      if ! xcode-select -p >/dev/null 2>&1; then
        warn "Xcode Command Line Tools are missing"
        xcode-select --install >/dev/null 2>&1 || true
        die "Xcode Command Line Tools install has been requested; rerun this script after it completes"
      fi

      local brew_bin=""
      if command -v brew >/dev/null 2>&1; then
        brew_bin="$(command -v brew)"
      elif [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin="/opt/homebrew/bin/brew"
      elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin="/usr/local/bin/brew"
      fi

      if [[ -z "$brew_bin" ]]; then
        log "installing Homebrew"
        need_cmd curl
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -x /opt/homebrew/bin/brew ]]; then
          brew_bin="/opt/homebrew/bin/brew"
        elif [[ -x /usr/local/bin/brew ]]; then
          brew_bin="/usr/local/bin/brew"
        else
          die "Homebrew installed, but brew was not found"
        fi
      fi

      eval "$("$brew_bin" shellenv)"
      ;;
    pacman)
      sudo pacman -Syu --noconfirm || true
      sudo pacman -S --needed --noconfirm openssh git curl ca-certificates base-devel inetutils
      ;;
    apt)
      sudo apt-get update
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        openssh-server openssh-client git curl ca-certificates build-essential hostname
      ;;
    dnf)
      sudo dnf -y update
      sudo dnf -y install openssh-server openssh-clients git curl ca-certificates hostname
      sudo dnf -y group install "Development Tools" || true
      ;;
  esac

  [[ "$ENABLE_SSHD" == "1" ]] && enable_ssh_server_if_available
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
    ans="$(lower "$ans")"
  fi

  install -d -m 700 "$HOME/.ssh"

  if [[ "$ans" != "n" && ! -f "$HOME/.ssh/id_ed25519" ]]; then
    local user_name host_info date_tag comment
    user_name="${USER:-$(id -un)}"
    host_info="$(hostname -f 2>/dev/null || hostname 2>/dev/null || uname -n)"
    date_tag="$(date -u +%Y_%b_%d__%H.%M.%SZ)"
    comment="${user_name}@${host_info}:${OS_PRETTY}:${date_tag}"

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

enable_ssh_server_if_available() {
  command -v systemctl >/dev/null 2>&1 || return 0

  local unit
  # Unit names vary by platform:
  # - sshd.service: RHEL/Fedora/Oracle and Arch
  # - ssh.service: Debian and older Ubuntu
  # - ssh.socket: Ubuntu 24.04+ socket-activated OpenSSH
  for unit in sshd.service ssh.service ssh.socket; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
      echo "Enabling OpenSSH server via systemd unit: $unit"
      sudo systemctl enable --now "$unit" || warn "failed to enable/start $unit"
      return 0
    fi
  done

  warn "OpenSSH server installed, but no known systemd unit found: sshd.service, ssh.service, ssh.socket"
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

  refresh_dotfile_paths

  if [[ -d "$DOTFILES/.git" && -f "$HOME/.ssh/id_ed25519" ]]; then
    git -C "$DOTFILES" remote set-url origin git@github.com:glados-418/dotfiles.git || true
  fi
}

selected_pkglist() {
  case "$PKG_MGR" in
    brew)
      echo "$DOTINSTALL/brewlist"
      ;;
    pacman)
      echo "$DOTINSTALL/wsl-arch"
      ;;
    apt)
      echo "$DOTINSTALL/wsl-ubuntu"
      ;;
    dnf)
      echo "$DOTINSTALL/wsl-oracle"
      ;;
    *)
      return 1
      ;;
  esac
}

install_packages_from_list() {
  local list_file="$1"
  [[ -f "$list_file" ]] || { warn "package list not found: $list_file"; return 0; }

  local pkgs=()
  read_list_file "$list_file" pkgs
  [[ ${#pkgs[@]} -gt 0 ]] || { log "no packages in $list_file"; return 0; }

  log "installing packages from $(basename "$list_file")"
  local failed=()
  local p

  case "$PKG_MGR" in
    brew)
      local brew_bin=""
      if command -v brew >/dev/null 2>&1; then
        brew_bin="$(command -v brew)"
      elif [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin="/opt/homebrew/bin/brew"
      elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin="/usr/local/bin/brew"
      else
        die "Homebrew is required to install packages from $list_file"
      fi

      eval "$("$brew_bin" shellenv)"
      "$brew_bin" update || warn "brew update failed; continuing"
      for p in "${pkgs[@]}"; do
        if "$brew_bin" list --formula "$p" >/dev/null 2>&1; then
          continue
        fi
        if ! "$brew_bin" install "$p"; then
          failed+=("$p")
        fi
      done
      ;;
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
  if is_macos; then
    log "skipping optional Linux package managers on macOS"
    return 0
  fi

  if [[ "$PKG_MGR" == "pacman" && -f "$DOTINSTALL/yaylist" ]]; then
    if command -v yay >/dev/null 2>&1; then
      local yay_pkgs=()
      read_list_file "$DOTINSTALL/yaylist" yay_pkgs
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
  require_file "$DOTBASE/gitconfig-shared"

  if is_macos; then
    require_file "$DOTBASE/bash_profile"
    require_file "$DOTBASE/configure_tools_bridge.bash"
  fi

  require_file "$(selected_pkglist)"
  require_file "$DOTINSTALL/post-setup.sh"

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

  if is_macos; then
    rm -f "$HOME/.bash_profile"
  fi
}

create_symlinks() {
  mkdir -p "$HOME/.config"

  ln -sfn "$DOTBASE/bashrc" "$HOME/.bashrc"
  ln -sfn "$DOTBASE/inputrc" "$HOME/.inputrc"
  ln -sfn "$DOTBASE/tmux.conf" "$HOME/.tmux.conf"
  ln -sfn "$DOTBASE/rgignore" "$HOME/.rgignore"

  if is_macos; then
    ln -sfn "$DOTBASE/bash_profile" "$HOME/.bash_profile"
  fi

  ln -sfn "$VIM/nvim" "$HOME/.config/nvim"
  ln -sfn "$VIM/vim" "$HOME/.vim"
  ln -sfn "$VIM/vimrc" "$HOME/.vimrc"
  ln -sfn "$VIM/gvimrc" "$HOME/.gvimrc"

  touch "$HOME/.gitconfig"
  git config --global include.path "$DOTBASE/gitconfig-shared"

  if is_wsl; then
    sudo cp "$DOTBASE/wsl.conf" /etc/wsl.conf
  fi
}

configure_macos_bash_shell() {
  is_macos || return 0

  # bash is installed from installers/brewlist. This step only registers it as an
  # allowed login shell and switches the current user after all symlinks exist.
  local brew_bin="" brew_bash
  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin="/usr/local/bin/brew"
  else
    die "Homebrew is required before configuring macOS bash"
  fi

  eval "$("$brew_bin" shellenv)"
  brew_bash="$(dirname "$brew_bin")/bash"
  [[ -x "$brew_bash" ]] || die "Homebrew bash not found at $brew_bash"

  if ! grep -Fxq "$brew_bash" /etc/shells; then
    log "adding $brew_bash to /etc/shells"
    echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
  fi

  local current_shell
  current_shell="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}' || true)"
  current_shell="${current_shell:-${SHELL:-}}"

  if [[ "$current_shell" != "$brew_bash" ]]; then
    log "switching login shell to $brew_bash"
    sudo chsh -s "$brew_bash" "$USER" || warn "failed to switch login shell; run: chsh -s \"$brew_bash\""
  fi
}

run_post_setup() {
  local script="$DOTINSTALL/post-setup.sh"

  if [[ ! -x "$script" ]]; then
    warn "post-setup script not found or not executable: $script"
    return 0
  fi

  if $ASSUME_YES; then
    bash "$script" --yes
  else
    bash "$script"
  fi
}

main() {
  need_cmd sudo

  ensure_checkpoint_dir
  if $START_OVER; then
    rm -rf "$CHECKPOINT_DIR"
    ensure_checkpoint_dir
    log "reset checkpoints for $OS_ID and restarting from beginning"
  fi

  log "detected OS: $OS_PRETTY ($OS_ID); package manager: $PKG_MGR"
  if is_wsl; then
    log "WSL environment detected"
  elif ! is_macos; then
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
  run_step configure_macos_bash_shell

  if $RUN_POST_SETUP; then
    run_post_setup
  fi

  log "setup completed successfully"
  if is_macos; then
    log "open a new terminal to start Homebrew bash"
  else
    log "open a new shell (or run: source ~/.bashrc)"
  fi

  if ! $RUN_POST_SETUP; then
    log "next step: run post-setup automation"
    if $ASSUME_YES; then
      log "bash \"$DOTINSTALL/post-setup.sh\" --yes"
    else
      log "bash \"$DOTINSTALL/post-setup.sh\""
    fi
  fi
}

main "$@"
