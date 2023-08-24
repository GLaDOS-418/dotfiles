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

DOT_SETUP_FILE="$HOME/dotfiles/dot_setup.sh"
TOOL_SCRIPTS="$HOME/dotfiles/tools"
DOTFILES=$HOME/dotfiles
SAVE_CMD="python3 $HOME/dotfiles/save_command.py"
FZF_UTILITIES="$HOME/dotfiles/.fzf_utilities"

################################################################
# EXPORT
################################################################

#export https_proxy=""
export EDITOR=nvim
export VISUAL=nvim
export MYVIMRC="$HOME/.vimrc"
export INPUTRC="$HOME/.inputrc"
export COLUMNS

# The Firefox build system and related tools store shared, persistent state in a common directory on the filesystem
export UNICTAGS=$HOME/bin/ctags_bld

export CC=clang
export CXX=clang++
export GOPATH=${HOME}/go
export LOCALBIN=${HOME}/.local/bin
export LOCALNVIM=${HOME}/.local/nvim/bin
export PATH=$UNICTAGS/bin:$CHROME:$LIVE_LATEX_PREVIEW:$GNUGLOBAL:$GOPATH/bin:$TOOL_SCRIPTS:$LOCALBIN:$LOCALNVIM:$PATH
# export MANPATH=$MANPATH:$HOME/share/man

########################################## 
# FZF
########################################## 

# use Fzf with 'fd'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
#export FZF_DEFAULT_COMMAND="fd . $HOME"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d . $HOME"
# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# morhetz/gruvbox
export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934'

#########################################
### BASH HISTORY
#########################################

# don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignoreboth:erasedups

# save last 2k commands on disk and of that load last 1k commands in memory.
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTFILE="$HOME/.bash_history"
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

################################################################
# SOURCES
################################################################

#Fuzzy search files using fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ -e ${FZF_UTILITIES} ]; then
  . ${FZF_UTILITIES}
fi

# Remove all predefined aliases
unalias -a

# You may want to put all your additions into a separate file like
# $HOME/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -e $HOME/.bash_aliases ]; then
  . $HOME/.bash_aliases
fi

if [ -e $HOME/.bash_functions ]; then
  . $HOME/.bash_functions
fi

if [ -e $HOME/.personalrc ]; then
    . $HOME/.personalrc
fi

# git completion
git_completion=$HOME/dotfiles/tools/git-completion-bash.sh
if [ -e  ${git_completion} ]; then
    . ${git_completion}
fi

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
# cmdhist                 - save multiline commands as single line in history

shopt -s expand_aliases cdspell checkjobs dirspell histappend \
autocd direxpand histverify nocaseglob no_empty_cmd_completion cmdhist

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

function __build_prompt_command {
  pstatus=$(nonzero_error_code) # cache, otherwise the error code will change to the output of next executed command
  pbranch=$(parse_git_branch)

  printf "\033[01;36m${pbranch} \e[31m${pstatus}"
}

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
    # status='`e=$? ; if [ $e = 0 ]; then echo ""; else echo $e: ; fi`'

    # https://stackoverflow.com/questions/35897021/why-does-a-newline-in-ps1-throw-a-syntax-error-in-git-for-windows-bash?lq=1
    # PS1='\[\033[01;32m\][ \u@\h\[\033[01;37m\] \w\[\033[01;36m\]$(parse_git_branch)\[\e[31m\] $(nonzero_value)\[\e[m\]\[\033[01;32m\]${SHLVL} ]'$'\[\033[00m\]\n\$ '
      PS1='\[\033[01;32m\][ \u@\h\[\033[01;37m\] \w\[\033[01;36m\]$(__build_prompt_command)\[\e[m\]\[\033[01;32m\]${SHLVL} ]'$'\[\033[00m\]\n\$ '
    # PS1='$(__build_prompt_command)'
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
# $ dircolors, dircolors -p #use these commands to know about the colors
LS_COLORS=$LS_COLORS:'di=01;33:ow=01;37;45:so=01;37;45'
export LS_COLORS

unset use_color safe_term match_lhs sh

. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# https://github.com/nvbn/thefuck
eval $(thefuck --alias --enable-experimental-instant-mode)

# reporting tools - install when not installed
# neofetch
#screenfetch
#alsi
#paleofetch
#fetch
#hfetch
#sfetch
#ufetch
#ufetch-arco
#pfetch
#sysinfo
#sysinfo-retro
#cpufetch
#colorscript random

