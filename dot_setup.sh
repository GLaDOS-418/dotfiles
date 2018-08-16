# crontab entries
# * * * * * 'sudo -i arpon -d -i wlp3s0 -D'

#fstab entry for windows mount
# UUID=CC8AA6D38AA6B97A /mnt/windows/  ntfs    defaults,noatime 0 2

#installed packages
#creating links to configs
ln -s $PWD/.bashrc $HOME/.bashrc

#installed packaged
sudo -i pacman -Sy texlive-most texlive-lang
sudo -i pacman -Sy mupdf
sudo -i pacman -Sy nodejs
sudo -i pacman -Sy inkscape
sudo -i pacman -Sy gdb
sudo -i pacman -Sy sqlite
sudo -i pacman -Sy pandoc
sudo -i pacman -Sy rust
sudo -i pacman -Sy ripgrep
sudo -i pacman -Sy cmake
sudo -i pacman -Sy neovim
sudo -i pacman -Sy clang
sudo -i pacman -Sy openjdk
sudo -i pacman -Sy jdk10-openjdk
sudo -i pacman -Sy go
sudo -i pacman -Sy boost
sudo -i pacman -Sy chromium
sudo -i pacman -Sy ttf-ubuntu-font-family
yaourt -Sy skypeforlinux-stable-bin
yaourt -Sy global
yaourt -Sy biber
yaourt -Sy tree
