#!/bin/env bash

################################################################
# SHELL ALIAS 
################################################################

alias u0='du --max-depth=0 -h'
alias u1='du --max-depth=1 -h'
alias l='ls -lrt'   # ls is function declared later
alias la='ls -lrtA' # ls is function declared later
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias grep='grep --colour=always'
alias egrep='egrep --colour=always'
alias rsync='rsync -azvhP'
#if [[ -x /usr/share/nvim ]]; then
#    alias v='nvim'
#else
#    alias v='vim'
#fi
alias nv='nvim'
alias v='vim'
alias uv='v +PlugInstall +UpdateRemotePlugins +qa'
alias gv='gvim'
alias vd='vimdiff'
alias gvd='gvimdiff'
alias emacs='emacs & &> /dev/null'
alias suvim='sudo -E gvim'
alias sv='sudo -E vim'
alias more=less

################################################################
# EDITOR ALIAS 
################################################################

alias sb='source ~/.bashrc'
alias vb='v ~/.bashrc'
alias vv='v ~/.vimrc'
alias vc='v ~/.vim/sources/custom_functions.vim'
alias va='v ~/.vim/sources/abbreviations.vim'
alias vs='v ~/.vim/sources/statusline.vim'
alias vp='v ~/.vim/sources/plugins.vim'
alias vba='v ~/.bash_aliases'

################################################################
# TOOL ALIAS 
################################################################

# WGET
alias wgold='wget --recursive --timestamping --level=inf --no-remove-listing --convert-links --show-progress --progress=bar:force --no-parent --execute robots=off --verbose --continue --wait=2 --random-wait --reject htm,html,tmp,dstore,db,dll --directory-prefix=guest_dir --regex-type=pcre'
alias wg='wgold --compression=auto'

# GIT
alias dh='git diff --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines HEAD'
alias diffhead='git diff --ignore-cr-at-eol --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines HEAD'
alias sdf='git sdf'
alias cdr='cd ./"$(git rev-parse --show-cdup)"'
alias gp='git rev-parse --abbrev-ref HEAD | xargs git push origin --set-upstream'
alias gl='git pull'
alias st='git status'
alias br='git branch'
alias log='git log --oneline --no-merges HEAD~20..HEAD'

# PACMAN
alias cdp='cd /mnt/windows/projects'
alias upe="cat updatelog | xargs -I{} pacman -Qo {} 2>&1 | sed 's/^error:.*owns //g' > noowner && cat noowner | xargs sudo rm -rf"
alias cleanpac='sudo pacman -Rns $(pacman -Qtdq)' # remove unused packages(orphans): if none found o/p :"no targets specified"

# PYTHON
alias prp='pipenv run python'
alias psh='pipenv shell'

# NETWORK
alias ipshow='ip link show'
alias tux='sudo arpon -d -i wlp3s0 -D'

################################################################
# PERSONAL ALIAS
################################################################

alias cdw='cd /mnt/windows/Users/AB/Downloads/'
alias tv='find media/TV\ Series/ -maxdepth 2 -mindepth 2 -type d  | sed -e 's/^.*\///g' | sort -bdf > list_tv.txt'
alias data='cd /run/media/helix/DATA'
