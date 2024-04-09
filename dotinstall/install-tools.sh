#!/bin/env bash

# fzf
git clone --depth=1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Language server tool ( req firefox addon )
curl -L https://languagetool.org/download/LanguageTool-stable.zip -o LanguageTool-stable.zip && ex LanguageTool-stable.zip

# install binaries from cargo
bash install-rust-tools.sh

# install binaries from npm
bash install-npm-tools.sh

# install packages using pipx (a wrapper for pip+venv)
bash install-python-tools.sh

#do this after package install to avoid ycm build errors
#bob installed via rust-tools.sh script
bob use nightly
nvim +PlugInstall +qall

