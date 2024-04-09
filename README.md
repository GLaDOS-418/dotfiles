# dotfiles

clone the repo in `$HOME` and run the following commands to create links to the dotfiles.
remove any existing conflicting file before running these commands.

```bash
ln -s $HOME/dotfiles/bashrc           $HOME/.bashrc
ln -s $HOME/dotfiles/bash_aliases     $HOME/.bash_aliases
ln -s $HOME/dotfiles/bash_functions   $HOME/.bash_functions
ln -s $HOME/dotfiles/inputrc          $HOME/.inputrc
ln -s $HOME/dotfiles/gitconfig        $HOME/.gitconfig
ln -s $HOME/dotfiles/tmux.conf        $HOME/.tmux.conf
ln -s $HOME/dotfiles/languagerc       $HOME/.languagerc
```

**NOTE**: for more details follow `dot_setup.sh`.


**TODO**: explore [GNU Stow](https://www.gnu.org/software/stow/)
