# dotfiles

clone the repo in `$HOME` and run the following commands to create links to the dotfiles.
remove any existing conflicting file before running these commands.

```bash
ln -s $HOME/dotfiles/home-config/bashrc           $HOME/.bashrc
ln -s $HOME/dotfiles/home-config/inputrc          $HOME/.inputrc
ln -s $HOME/dotfiles/home-config/tmux.conf        $HOME/.tmux.conf
ln -s $HOME/dotfiles/home-config/rgignore         $HOME/.rgignore

touch $HOME/.gitconfig
git config --global include.path $HOME/dotfiles/shell-config/gitconfig-shared
```

**NOTE**: for more details follow `dot_setup.sh`.


**TODO**: explore [GNU Stow](https://www.gnu.org/software/stow/)
