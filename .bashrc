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

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if  which tmux > /dev/null 2>&1  &&  [ -z "$TMUX" ]; then
    ID="$( tmux ls 2&>/dev/null | grep -vm1 attached | cut -d: -f1 )" # get the id of a deattached session
    if [[ -z "$ID" ]] ;then # if not available create a new one
        tmux new-session
    else
        tmux attach-session -t "$ID" # if available attach to it
    fi
fi

################################################################
# LOCAL VARIABLE
################################################################

# ANACONDA=$HOME/anaconda3/bin
# FLATBUFFERS=$HOME/binaries/flatbuffers
# GNUGLOBAL=$HOME/executables/global/bin
# CHROME=/usr/lib/chrome
# UNICTAGS=$HOME/executables/ctags_bld/bin
# PHANTOMJS=$HOME/Downloads/phantomjs-2.1.3/bin
# LIVE_LATEX_PREVIEW="$HOME/.vim/bundle/vim-live-latex-preview/bin/"
DOT_SETUP_FILE="$HOME/dotfiles/dot_setup.sh"
DIFF_SO_FANCY="$HOME/dotfiles/so-fancy"
DOTFILES=$HOME/dotfiles
SAVE_CMD="python3 $HOME/dotfiles/save_command.py"

################################################################
# EXPORT
################################################################

#export https_proxy=""
export EDITOR=vim
export MYVIMRC="$HOME/.vimrc"
export INPUTRC="$HOME/.inputrc"
export COLUMNS

# BASH HISTORY

# don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignoreboth

# save last 2k commands on disk and of that load last 1k commands in memory.
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTFILE="$HOME/.bash_history"
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

export GOPATH=${HOME}/go
export PATH=$UNICTAGS:$CHROME:$LIVE_LATEX_PREVIEW:$GNUGLOBAL:$GOPATH/bin:$DIFF_SO_FANCY:$PATH
# export MANPATH=$MANPATH:$HOME/share/man

################################################################
# ALIASES
################################################################

# Remove all predefined aliases
unalias -a

# You may want to put all your additions into a separate file like
# $HOME/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# PROJECT AGNOSTTIC
if [ -e $HOME/.bash_aliases ]; then
  . $HOME/.bash_aliases
fi

# PROJECT SPECIFIC
if [ -e $HOME/.workrc ]; then
    . $HOME/.workrc
fi

################################################################
# CUSTOM FUNCTIONS
################################################################

function ftstats {
    # recursive statistics on file types in directory
    # find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -nr
    if [[ -n $1 ]]; then
        # any arg means folder-wise
        for d in */ ; do
            echo $d
            find $d -type f | sed -r 's/.*\/([^\/]+)/\1/' | sed 's/^[^\.]*$//' | sed -r 's/.*(\.[^\.]+)$/\1/' | sort | uniq -c | sort -nr
            # files only    | keep filename only          | no ext -> '' ext   | keep part after . (i.e. ext) | count          | sort by count desc
        done
    else
        find $d -type f | sed -r 's/.*\/([^\/]+)/\1/' | sed 's/^[^\.]*$//' | sed -r 's/.*(\.[^\.]+)$/\1/' | sort | uniq -c | sort -nr
    fi

}

function mcd {
    mkdir -pv $1 && cd $1
}

function ls {
    command ls -FhvC --color=always --author --time-style=long-iso "$@" | less -RXF
}

function lstcmd {
  fc -ln "$1" "$1" | sed '1s/^[[:space:]]*//' | xargs echo >> $DOT_SETUP_FILE
}

function lmedia {
  find $1 -maxdepth 2 -mindepth 2 -type d  | sed -e 's/^.*\///g' | sort -bdfh > $2
}

function mp {
  touch $1.cpp && touch $1.in && vim $1.cpp
}

function bench {
  time $@ 1>/dev/null 2>&1
}

function gpp {
  /usr/bin/g++ -g -Dfio -o -std=gnu++17 $1 $1.cpp
}

function grl {
  grep -Rl --exclude-dir={docs,deploy} --include=\*.{cpp,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcsxproj,inc,pck,sql} $@ 2>/dev/null
}

function grn {
  grep -Rn --exclude-dir={docs,deploy} --include=\*.{cpp,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcsxproj,inc,pck,sql} $@ 2>/dev/null
}

# ex - archive extractor
function ex {
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
function ar {
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
function git {
  REALPATH=`readlink -f ${PWD}`
  if grep -qE "(MINGW64|CYGWIN)" /proc/version &> /dev/null  && [ "${REALPATH:0:6}" == "/cygdrive/" -o "${REALPATH:0:3}" == "/c/" ]; then
    # /c/ for git bash and /cygdrive/ for cygwin
    git.exe "$@"
  elif grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null  && [ "${REALPATH:0:5}" == "/mnt/" ]; then
    # /mnt/ for microsoft wsl. WSL doesn't allow windows programs to alter subsystem files. Thus no /home/
    git.exe "$@"
  elif grep -qE "(MSYS_NT)" /proc/version &> /dev/null ;  then
    /mingw64/bin/git "$@"
  else
    /usr/bin/git "$@"
  fi
}

function git_ignore { 
  # Usage : generates .gitignore file for languages, IDEs and Operating Systems
  # $ git_ignore vim c++ linux
  # End of https://www.gitignore.io/api/vim,c++,linux
  curl -Ls  "http://www.gitignore.io/api/$(IFS=, ; echo "$*")"; 
  printf '\n'
}

function colors {
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

function parse_git_branch {
    git rev-parse --abbrev-ref HEAD 2> /dev/null | sed -e 's/\(.*\)/(\1) /'
}

################################################################
##  CONFIG
################################################################

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

# the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Prevent file overwrite on stdout redirection.
# Use `>|` to force redirection to an existing file.
set -o noclobber

# cdspell                 - correct minor spelling mistakes in cd
# checkjobs               - check if a job is running in current bash session. If yes, ask for second exit
# dirspell                - bash attempting spell correction if dir does not exit
# histappend              - Enable history appending instead of overwriting.
# autocd                  - a dir name is executed as if it is an arg to cd cmd
# direxpand               - automatically expand directory globs when completing
# histverify              - expand, but don't automatically execute, history expansions
# nocaseglob              - case insensitive globbing
# no_empty_cmd_completion - don't TAB expand empty lines

shopt -s expand_aliases cdspell checkjobs dirspell histappend \
autocd direxpand histverify nocaseglob no_empty_cmd_completion

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
[[ -f $HOME/.dir_colors   ]] && match_lhs="${match_lhs}$(<$HOME/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
  && type -P dircolors >/dev/null \
  && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
  # Enable colors for ls, etc.  Prefer $HOME/.dir_colors #64489
  if type -P dircolors >/dev/null ; then
    if [[ -f $HOME/.dir_colors ]] ; then
      eval $(dircolors -b $HOME/.dir_colors)
    elif [[ -f /etc/DIR_COLORS ]] ; then
      eval $(dircolors -b /etc/DIR_COLORS)
    fi
  fi

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

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
