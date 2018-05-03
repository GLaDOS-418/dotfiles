# crontab entries
# * * * * * 'sudo arpon -d -i wlp3s0 -D'

#fstab entry for windows mount
# UUID=CC8AA6D38AA6B97A /mnt/windows/  ntfs    defaults,noatime 0 2

#installed packages
#creating links to configs
ln -s dotfiles/vim/.vimrc ~/.vimrc
ln -s dotfiles/bash/.bashrc ~/.bashrc
ln -s dotfiles/bash/.bash_profile ~/.bash_profile
ln -s ~/.vimrc ~/.config/nvim/init.vim

#installed packaged
sudo pacman -Ss neovim
sudo pacman -Sy texlive-most texlive-lang
sudo yaourt -Sy biber
sudo pacman -Sy mupdf
sudo yaourt tree
