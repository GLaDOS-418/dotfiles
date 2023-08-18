#!/bin/env bash

################################################################
# SHELL ALIAS 
################################################################

alias u0='du --max-depth=0 -h'
alias u1='du --max-depth=1 -h'
alias l='ls -lrt'   # ls is function declared later
alias la='ls -lrtA' # ls is function declared later
alias df='df -h'                          # human-readable sizes
alias free='free -mht'                    # show sizes in MB
alias grep='grep --colour=always'
alias egrep='egrep --colour=always'
alias rsync='rsync -azvhP'
alias navic='navi --cheatsh'
alias m='make'

#### try to prevent accidental data loss
# alias cp='cp -i'
# alias mv='mv -i'

TRASH="${HOME}/.local/share/trash/files/"
mkdir -p ${TRASH}

alias rm='mv -t "${TRASH}" --backup=numbered -- "$@"'
alias nuke_trash='/bin/rm -r ${TRASH:?}/*'

################################################################
# EDITOR ALIAS 
################################################################

if [[ -x "$(command -v nvim)" ]]; then
    alias v='nvim'
else
    alias v='vim'
fi
alias nv='nvim'
alias vim='nvim'
alias uv='v +PlugInstall +UpdateRemotePlugins +qa'
alias gv='gvim'
alias vd='vimdiff'
alias gvd='gvimdiff'
alias emacs='emacs & &> /dev/null'
alias suvim='sudo -E gvim'
alias sv='sudo -E vim'
alias more=less
alias sb='source ~/.bashrc'
alias vb='v ~/.bashrc'
alias vv='v ~/.vimrc'
alias vc='v ~/.vim/sources/custom_functions.vim'
alias va='v ~/.vim/sources/abbreviations.vim'
alias vs='v ~/.vim/sources/statusline.vim'
alias vp='v ~/.vim/sources/plugins.vim'
alias vba='v ~/.bash_aliases'
alias vn='v -u NONE'

################################################################
# TOOL ALIAS 
################################################################

# WGET
alias wgold='wget --recursive --timestamping --level=inf --no-remove-listing --convert-links --show-progress --progress=bar:force --no-parent --execute robots=off --verbose --continue --wait=2 --random-wait --reject htm,html,tmp,dstore,db,dll --directory-prefix=guest_dir --regex-type=pcre'
alias wg='wgold --compression=auto'

# GIT
alias dh='git diff --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines --diff-algorithm=histogram'
alias dhead='dh HEAD'
alias cdr='cd ./"$(git rev-parse --show-cdup)"'
alias gp='git rev-parse --abbrev-ref HEAD | xargs git push origin --set-upstream'
alias gpf='gp --force'
alias gl='git pull'
alias st='git status'
alias br='git branch'
alias log='git log --oneline --no-merges HEAD~20..HEAD'

# PACMAN
alias upe="cat updatelog | xargs -I{} pacman -Qo {} 2>&1 | sed 's/^error:.*owns //g' > noowner && cat noowner | xargs sudo rm -rf"
alias cleanpac='sudo pacman -Rns $(pacman -Qtdq)' # remove unused packages(orphans): if none found o/p :"no targets specified"
alias unlockpac="sudo rm /var/lib/pacman/db.lck" #pacman unlock
# fix typos
alias udpate='sudo pacman -Syyu'
alias upate='sudo pacman -Syyu'
alias updte='sudo pacman -Syyu'
alias updqte='sudo pacman -Syyu'
alias upqll="paru -Syu --noconfirm"
alias upal="paru -Syu --noconfirm"


# PYTHON
alias prp='pipenv run python'
alias psh='pipenv shell'

# NETWORK
alias ipshow='ip link show'
alias tux='sudo arpon -d -i wlp3s0 -D'

# FZF
alias of=' fd --type f --hidden --follow --exclude .git | fzf --header "open file..." --preview "bat -n --color=always {}" --bind "ctrl-/:change-preview-window(down|hidden|)" --preview-window down | xargs nvim'

# YT-DLP

################################################################
#fix obvious typo's
################################################################

alias cd..='cd ..'
alias pdw="pwd"

