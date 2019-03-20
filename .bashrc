#!/bin/env bash
#########################################
##                           ___.      ##
## _____ _______  ____   ____\_ |__    ##
## \__  \\_  __ \/    \ /  _ \| __ \   ##
##  / __ \|  | \/   |  (  <_> ) \_\ \  ##
## (____  /__|  |___|  /\____/|___  /  ##
##      \/           \/           \/   ##
##                                     ##
#########################################

################################################################
# LOCAL VARIABLE
################################################################

ANACONDA=/home/arnob/anaconda3/bin
FLATBUFFERS=/home/arnob/binaries/flatbuffers
GNUGLOBAL=/home/arnob/executables/global/bin
CHROME=/usr/lib/chrome
UNICTAGS=/home/arnob/executables/ctags_bld/bin
DOTFILES='~/dotfiles'
SAVE_CMD="python3 ~/dotfiles/save_command.py"
#phantomjs required for youtube-dl
#PHANTOMJS=/home/arnob/Downloads/phantomjs-2.1.3/bin
LIVE_LATEX_PREVIEW='~/.vim/bundle/vim-live-latex-preview/bin/'
DOT_SETUP_FILE='~/dotfiles/dot_setup.sh'

################################################################
# EXPORT
################################################################

#export https_proxy=""
export EDITOR=vim
export MYVIMRC="~/.vimrc"
export INPUTRC="~/.inputrc"
export HISTFILE="~/.bash_history"

# don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE
export HISTSIZE=1000
export HISTFILESIZE=2000

export GOPATH=${HOME}/go
export PATH=$UNICTAGS:$CHROME:$LIVE_LATEX_PREVIEW:$GNUGLOBAL:$GOPATH/bin:$PATH:/home/arnob/executables/

################################################################
# ALIAS
################################################################

# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# PROJECT SPECIFIC
if [ -f ~/.workrc ]; then
    . ~/.workrc
fi

#PROJECT AGNOSTTIC
alias cdr='cd ./"$(git rev-parse --show-cdup)"'
alias gp="git rev-parse --abbrev-ref HEAD | xargs git push origin --set-upstream"
alias gl="git pull"
alias st="git status"
alias br="git branch"
alias log="git log --oneline --no-merges HEAD~20..HEAD"
alias lg="git log --no-merges HEAD~10..HEAD"
alias emacs="emacs & &> /dev/null"
alias suvim="sudo -E gvim"
#remove unused packages(orphans): if none found o/p :"no targets specified"
alias cleanpac='sudo pacman -Rns $(pacman -Qtdq)'
alias cdp="cd /mnt/windows/projects"
alias dh="git diff  --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines HEAD"
alias diffhead="git diff --ignore-cr-at-eol --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines HEAD"
alias prp="pipenv run python"
alias psh="pipenv shell"
alias ipshow="ip link show"
alias tux="sudo arpon -d -i wlp3s0 -D"
alias vv="vim ~/.vimrc"
alias sv="sudo -E vim"
alias vc="vim ~/.vim/sources/custom_functions.vim"
alias va="vim ~/.vim/sources/abbreviations.vim"
alias vs="vim ~/.vim/sources/statusline.vim"
alias vp="vim ~/.vim/sources/plugins.vim"
alias vb="vim ~/.bashrc"
alias sb="source ~/.bashrc"
alias more=less
alias spac="$SAVE_CMD sudo -i pacman -Sy"
alias syao="$SAVE_CMD yaourt -Sy"
alias v="vim "
alias gv="gvim "
alias vd="vimdiff "
alias gvd="gvimdiff "
alias wg="wget --recursive --timestamping --level=inf --no-remove-listing --convert-links --show-progress --progress=bar:force --no-parent --execute robots=off --compression=auto --verbose --continue --wait=2 --random-wait --reject htm,html,tmp,dstore,db,dll --directory-prefix=guest_dir --regex-type=pcre"
alias wgold="wget --recursive --timestamping --level=inf --no-remove-listing --convert-links --show-progress --progress=bar:force --no-parent --execute robots=off --verbose --continue --wait=2 --random-wait --reject htm,html,tmp,dstore,db,dll --directory-prefix=guest_dir --regex-type=pcre"
alias cdw="cd /mnt/windows/Users/AB/Downloads/"
alias tv="find media/TV\ Series/ -maxdepth 2 -mindepth 2 -type d  | sed -e 's/^.*\///g' | sort -bdf > list_tv.txt"
alias u0="du --max-depth=0 -h"
alias u1="du --max-depth=1 -h"
alias l="ls -lrth --color=auto"
alias la="ls -lrthA --color=auto"
alias upe="cat updatelog | xargs -I{} pacman -Qo {} 2>&1 | sed 's/^error:.*owns //g' > noowner && cat noowner | xargs sudo rm -rf"
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias rsync='rsync -azvhP'

################################################################
# CUSTOM FUNCTIONS
################################################################

function lstcmd(){
  fc -ln "$1" "$1" | sed '1s/^[[:space:]]*//' | xargs echo >> $DOT_SETUP_FILE
}

function lmed(){
  find $1 -maxdepth 2 -mindepth 2 -type d  | sed -e 's/^.*\///g' | sort -bdf > $2
}

function mp(){
  touch $1.cpp && touch $1.in && vim $1.cpp
}

function bench(){
  time $@ 1>/dev/null 2>&1
}

function gpp(){
  /usr/bin/g++ -g -Dfio -o -std=gnu++17 $1 $1.cpp
}

function grl(){
  grep -Rl --exclude-dir={docs,deploy} --include=\*.{cpp,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcsxproj,inc,pck,sql} $@ 2>/dev/null
}

function grn(){
  grep -Rn --exclude-dir={docs,deploy} --include=\*.{cpp,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcsxproj,inc,pck,sql} $@ 2>/dev/null
}
# ex - archive extractor
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2|*.tbz2|*.tb2) tar kxjf $1       ;;
      *.tar.bz|*.tbz)         tar kxjf $1       ;;
      *.tar.gz|*.tgz)         tar kxzf $1       ;;
      *.tar.xz|*.txz)         tar kxJf $1       ;;
      *.lzip)                 tar kxf --lzip $1 ;;
      *.lzop)                 tar kxf --lzop $1 ;;
      *.lzma)                 tar kxf --lzma $1 ;;
      *.tar)                  tar kxf $1        ;;
      *.bz2)                  bunzip2 -kd $1    ;;
      *.rar)                  unrar x $1        ;;
      *.gz)                   gunzip $1         ;;
      *.zip)                  unzip $1          ;;
      *.Z)                    uncompress $1     ;;
      *.7z)                   7z x $1           ;;
      *)                      echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ar - archiver
ar ()
{
  if [ -f $2 ] ; then
    case $1 in
      tbz2) tar -kcjf $2       ;;
      tbz)  tar -kcjf $2       ;;
      tgz)  tar -kczf $2       ;;
      txz)  tar -kcJf $2       ;;
      tar)  tar -kcf $2        ;;
      lzip) tar -kcf --lzip $2 ;;
      lzop) tar -kcf --lzop $2 ;;
      lzma) tar -kcf --lzma $2 ;;
      *)    echo "'$1' cannot be compressed via ar()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# WSL 'git' wrapper. Named the function git to get bash completion
# https://github.com/Microsoft/WSL/issues/981#issuecomment-363638656
function git(){
  REALPATH=`readlink -f ${PWD}`
  if grep -qE "(Microsoft|WSL|MINGW64|CYGWIN)" /proc/version &> /dev/null  && [ "${REALPATH:0:5}" == "/mnt/" -o "${REALPATH:0:6}" == "/home/" -o "${REALPATH:0:3}" == "/c/" ]; then
    # /mnt/ for microsoft wsl and /c/ for git bash and /home/ for cygwin
    git.exe "$@"
  else
    /usr/bin/git "$@"
  fi
}

colors() {
  local fgc bgc vals seq0

  printf "Color escapes are %s\n" '\e[${value};...;${value}m'
  printf "Values 30..37 are \e[33mforeground colors\e[m\n"
  printf "Values 40..47 are \e[43mbackground colors\e[m\n"
  printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

  # foreground colors
  for fgc in {30..37}; do
    # background colors
    for bgc in {40..47}; do
      fgc=${fgc#37} # white
      bgc=${bgc#40} # black

      vals="${fgc:+$fgc;}${bgc}"
      vals=${vals%%;}

      seq0="${vals:+\e[${vals}m}"
      printf "  %-9s" "${seq0:-(default)}"
      printf " ${seq0}TEXT\e[m"
      printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
    done
    echo; echo
  done
}

################################################################
##  CONFIG
################################################################

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# running gui apps as root
xhost +local:root > /dev/null 2>&1
# sudo with tab completion
complete -cf sudo

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.
shopt -s checkwinsize

shopt -s expand_aliases

# Enable history appending instead of overwriting.
shopt -s histappend

# the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

###################################################################
# COLORS
###################################################################

# Change the window title of X terminals
case ${TERM} in
  xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
    ;;
  screen*)
    PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
    ;;
esac

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
  && type -P dircolors >/dev/null \
  && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
  # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
  if type -P dircolors >/dev/null ; then
    if [[ -f ~/.dir_colors ]] ; then
      eval $(dircolors -b ~/.dir_colors)
    elif [[ -f /etc/DIR_COLORS ]] ; then
      eval $(dircolors -b /etc/DIR_COLORS)
    fi
  fi

  function parse_git_branch(){
    git rev-parse --abbrev-ref HEAD 2> /dev/null | sed -e 's/\(.*\)/(\1) /'
  }

  if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[01;31m\][\h\[\033[01;36m\] \w\[\033[01;31m\]]\$\[\033[00m\] '
  else
      # https://stackoverflow.com/questions/35897021/why-does-a-newline-in-ps1-throw-a-syntax-error-in-git-for-windows-bash?lq=1
      PS1='\[\033[01;32m\][ \u@\h\[\033[01;37m\] \w\[\033[01;36m\] $(parse_git_branch)\[\033[01;32m\]]'$'\[\033[00m\]\n\$ '
  fi

else
  if [[ ${EUID} == 0 ]] ; then
    # show root@ when we don't have colors
    PS1='\u@\h \w \$ '
  else
    PS1='\u@\h \w \$ '
  fi
fi

# better yaourt colors
export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"
#export PS1=${debian_chroot:+($debian_chroot)}\u@\h:\w\$ #old value
#export PS1="[\u]:[\W]$" #[username]:[baseWorkingDirectory]

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# get rid of annoying dark blue color on black bg on terminal
LS_COLORS=$LS_COLORS:'di=01;33'
export LS_COLORS

unset use_color safe_term match_lhs sh
