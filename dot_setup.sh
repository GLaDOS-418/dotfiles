#!/bin/env bash
# the file is maintained in 'dotfiles' repo.

# generating locale
if  grep -q '#en_US.UTF-8 UTF-8' '/etc/locale.gen'
then
  sudo sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  echo "locale value activated in /etc/locale.gen"
  sudo locale-gen
  echo "reboot...."
  exit
elif grep -q '^en_US.UTF-8 UTF-8' '/etc/locale.gen'
then
  echo "locale value already active in /etc/locale.gen"
else
  echo 'en_US.UTF-8 UTF-8' | tee -a /etc/locale.gen
  echo "locale value added in /etc/locale.gen"
  sudo locale-gen
  echo "reboot...."
  exit
fi

if [ -x "$(command -v pacman)" ]; then
  sudo -i pacman -Syu
  sudo -i pacman --needed --noconfirm -Sy openssh git curl
elif [ -x "$(command -v apt)" ]; then
  sudo apt update
  sudo apt install -y openssh-server openssh-client git curl
elif [ -x "$(command -v dnf)" ]; then
  sudo dnf update
  sudo dnf install -y openssh-server openssh git curl
fi

read -rp "generate ssh key? (y/N)" is_generate_key
is_generate_key=${is_generate_key,,}

if [[ ${is_generate_key} == y* ]]
then
    if [[ -e $HOME/.ssh ]]; then
      /bin/rm -rf "$HOME"/.ssh
    fi

    cat /dev/zero | ssh-keygen -t ed25519 -q -N "" -C $(whoami)@$(echo $(uname -nmo; grep -P ^NAME /etc/os-release | sed -E -e 's/NAME="(.*)"/\1/g' | tr ' ' '_' ; date +%F) | tr ' ' '::')
fi

ssh-keyscan github.com >> ~/.ssh/known_hosts


# TODO: add ssh key to github via github api
# printf '\nenter github username: '
# read -p
# read -sp "enter github pass: " pass
#
# curl -u "${user}:${pass}" --data "{ \"key\": \"$(cat ~/.ssh/id_rsa.pub)\"}" https://api.github.com/user/keys

printf '\n\n ::::::::::  ADD THIS KEY TO YOUR GIT REPO :::::::::: \n\n'
cat "$HOME"/.ssh/id_ed25519.pub

printf '\n\n'
read -rp "press 'enter'..." enter


cd || exit
curl -L https://github.com/GLaDOS-418/dotfiles/raw/main/dotbase/bashrc -o .bashrc
source .bashrc

[ ! -d dotfiles ] && git clone git@github.com:glados-418/dotfiles.git
[ ! -d vim ] && git clone git@github.com:glados-418/vim.git


DOTFILES=${HOME}/dotfiles
DOTBASE=${DOTFILES}/dotbase
DOTINSTALL=${DOTFILES}/dotinstall
DOTRC=${DOTFILES}/dotrc
VIM=${HOME}/vim


cd "${DOTINSTALL}" || exit
printf '\n\n ::::: INSTALLING PACKAGES :::::\n\n'
if [ -x "$(command -v pacman)" ]; then
  tr '\n' ' ' < paclist  | xargs sudo -i pacman --needed --noconfirm -Sy
  os_id=$(grep -oP '^ID=\K\w+' /etc/os-release)
  if [[ ${os_id} == manjaro ]]; then
    sudo -i pacman --needed --noconfirm -Sy yay
    tr '\n' ' ' < yaylist  | xargs yay --needed --noconfirm -Sy
  else
    tr '\n' ' ' < yaylist | xargs sudo -i pacman --needed --noconfirm -Sy
  fi
elif [ -x "$(command -v apt)" ]; then
  wsl-ubuntu | xargs echo | xargs sudo DEBIAN_FRONTEND=noninteractive apt install -y
elif [ -x "$(command -v dnf)" ]; then
   tr '\n' ' ' < wsl-oracle | xargs sudo dnf install -y
else
  echo "package manager not installed..."
fi


cd || exit
## remove old configs
[ -f .bashrc ]    && /bin/rm .bashrc
[ -f .inputrc ]   && /bin/rm .inputrc
[ -f .tmux.conf ] && /bin/rm .tmux.conf
[ -f .gitconfig ] && /bin/rm .gitconfig
[ -f .rgignore ]  && /bin/rm .rgignore

[ -f .vimrc ]  && /bin/rm .vimrc
[ -f .gvimrc ] && /bin/rm .gvimrc
[ -d .vim ]    && /bin/rm -rf .vim
[ -d .config/nvim ]  && /bin/rm -rf .config/nvim
[ -f /etc/wsl.conf ] && sudo /bin/rm -f /etc/wsl.conf


## link new configs
ln -s "$DOTBASE"/bashrc    .bashrc
ln -s "$DOTBASE"/inputrc   .inputrc
ln -s "$DOTBASE"/tmux.conf .tmux.conf
ln -s "$DOTBASE"/rgignore  .rgignore

touch .gitconfig
git config --global include.path "$DOTRC"/gitconfig-shared

mkdir -p .config
ln -s "${VIM}"/nvim   .config/nvim
ln -s "${VIM}"/vim    .vim
ln -s "${VIM}"/vimrc  .vimrc
ln -s "${VIM}"/gvimrc .gvimrc

source .bashrc

# wsl.conf is relevant only for WSL2 distributions
sudo cp "$DOTBASE"/wsl.conf /etc/wsl.conf

# enable snapd -- snaplist
if [ -x "$(command -v snap)" ]; then
  sudo systemctl enable --now snapd.socket
  sudo ln -s /var/lib/snapd/snap /snap
  xargs sudo -i snap install < snaplist
fi

printf "\n\n:::: INITIAL SETUP DONE ::::\n\n"
