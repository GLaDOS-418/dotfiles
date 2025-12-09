#!/usr/bin/env bash


#
# Locale
#
if ! locale -a | grep -q '^en_US.utf8$'; then
  log "Generating locale en_US.UTF-8"
  sudo sed -i 's/^#\?en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
  log "Locale generated. Reboot recommended."
  exit 0
fi

#
# base packages
#
sudo apt update
sudo apt dist-upgrade -y

sudo apt install -y \
  openssh-server \
  openssh-client \
  git \
  curl \
  ca-certificates \
  build-essential

#####################################
# SSH
#####################################
install -d -m 700 "$HOME/.ssh"

readonly SSH_COMMENT="${USER_NAME}@${HOST_INFO}:${OS_NAME}:${DATE_TAG}"
readonly KEY_FILE="$HOME/.ssh/id_ed25519.pub"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -a 100 -N "" -C "$SSH_COMMENT" \
    -f ${KEY_FILE}
fi

ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
sort -u "$HOME/.ssh/known_hosts" -o "$HOME/.ssh/known_hosts"
chmod 644 "$HOME/.ssh/known_hosts"

echo
echo "ADD THIS SSH KEY TO GITHUB:"
echo "-----------------------------------"
cat  ${KEY_FILE}
echo "-----------------------------------"
read -rp "Press Enter after adding the key..."

#
# dotfiles
#

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
  git clone https://github.com/glados-418/vim.git
fi

#
# variables
#

DOTFILES="$HOME/dotfiles"
DOTBASE="$DOTFILES/dotbase"
DOTINSTALL="$DOTFILES/dotinstall"
DOTRC="$DOTFILES/dotrc"
VIM="$HOME/vim"

#
# package install
#

cd "$DOTINSTALL"

if [[ -f wsl-ubuntu ]]; then
  grep -Ev '^\s*#|^\s*$' wsl-ubuntu | \
    xargs sudo DEBIAN_FRONTEND=noninteractive apt install -y
fi


#
# remove old configs
#

for f in \
  .bashrc .inputrc .tmux.conf .gitconfig .rgignore \
  .vimrc .gvimrc
do
  [[ -e "$f" ]] && rm "$f" "$backup"/
done

[[ -d .vim ]] && rm -rf .vim
[[ -d .config/nvim ]] && rm -rf .config/nvim

#
# Symlinks
#

mkdir -p "$HOME/.config"

ln -sf "$DOTBASE/bashrc"        "$HOME/.bashrc"
ln -sf "$DOTBASE/inputrc"       "$HOME/.inputrc"
ln -sf "$DOTBASE/tmux.conf"     "$HOME/.tmux.conf"
ln -sf "$DOTBASE/rgignore"      "$HOME/.rgignore"

ln -sf "$VIM/nvim"              "$HOME/.config/nvim"
ln -sf "$VIM/vim"               "$HOME/.vim"
ln -sf "$VIM/vimrc"             "$HOME/.vimrc"
ln -sf "$VIM/gvimrc"            "$HOME/.gvimrc"

touch "$HOME/.gitconfig"
git config --global include.path "$DOTRC/gitconfig-shared"

if grep -qi microsoft /proc/version; then
  sudo cp "$DOTBASE/wsl.conf" /etc/wsl.conf
fi


echo
echo "==== Ubuntu bootstrap complete ===="
echo "==== To install language supports check out the install_* functions in ${DOTRC}/languagerc ===="
