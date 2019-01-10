#!/bin/env bash

# crontab entries
# * * * * * 'sudo -i arpon -d -i wlp3s0 -D'

#fstab entry for windows mount
# UUID=CC8AA6D38AA6B97A /mnt/windows/  ntfs    defaults,noatime 0 2

# mount shared host dir from windows host to linux guest vbox
# sudo mount -t vboxsf shared_host_dir_name /path/to/guest/dir

if [[ ! -d $HOME/vim ]];then
  git clone https://github.com/arnobbhanja/vim.git $HOME/vim
fi

if [[ -f $HOME/.bashrc ]]; then
  rm $HOME/.bashrc
fi

ln -s $PWD/.bashrc $HOME/.bashrc
source ~/.bashrc

#installed packaged
if [ -x "$(command -v pacman)" ]; then
  cat paclist | tr '\n' ' ' | xargs sudo -i pacman --needed --noconfirm -Sy
  cat yaylist | tr '\n' ' ' | xargs yay --needed --noconfirm -Sy
else
  echo "pacman not installed..."
fi

if [[ ! -d $HOME/.local/share/fonts ]]; then
  mkdir -p $HOME/.local/share/fonts
fi

cp -r $HOME/vim/fonts/* $HOME/.local/share/fonts/

if [[ -f $HOME/.vimrc ]]; then
  rm $HOME/.vimrc
fi

if [[ -d $HOME/.vim ]]; then
  rm -rf $HOME/.vim
fi

ln -s $HOME/vim/vim/.vim $HOME/.vim
ln -s $HOME/vim/vim/.vimrc $HOME/.vimrc

#do this after package install to avoid ycm build errors
vim +PlugInstall +qall

cat /dev/zero | ssh-keygen -b 2048 -t rsa -q -N "" -C $(whoami)@$(echo $(uname -nmo; grep -P ^NAME /etc/os-release | sed -E -e 's/NAME="(.*)"/\1/g' | tr ' ' '_' ; date +%F) | tr ' ' ':')

#public key
cat $HOME/.ssh/id_rsa.pub

echo "use above public key in gitlab, github: (read)"

git remote set-url origin git@gitlab.com:arnobbhanja/dotfiles.git

cd $HOME/vim
git remote set-url origin git@github.com:arnobbhanja/vim.git
