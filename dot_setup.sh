# crontab entries
# * * * * * 'sudo arpon -d -i wlp3s0 -D'

#fstab entry for windows mount
# UUID=CC8AA6D38AA6B97A /mnt/windows/  ntfs    defaults,noatime 0 2

#installed packages
#creating links to configs
ln -s dotfiles/bash/.bashrc ~/.bashrc
ln -s dotfiles/bash/.bash_profile ~/.bash_profile

#installed packaged
sudo pacman -Ss neovim
sudo pacman -Sy texlive-most texlive-lang
yaourt -Sy biber
sudo pacman -Sy mupdf
yaourt tree
sudo pacman -Sy nodejs
sudo pacman -Sy inkscape
sudo pacman -Sy gdb
yaourt -Sy skypeforlinux-stable-bin
sudo pacman -Sy sqlite
yaourt global
sudo pacman -Sy pandoc
sudo pacman -Sy rust
sudo pacman -Sy ripgrep
sudo pacman -Sy the_silver_searcher
sudo pacman -Sy fd
sudo pacman -Sy cmake
