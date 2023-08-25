#!/bin/env bash

################################################################
# CUSTOM FUNCTIONS
################################################################

# C++

function new_cpp_project {
  if [ ! ${1} ]
  then
    echo "project name not supplied..."
    return
  fi

  git clone --depth 1 --single-branch --branch basic git@github.com:GLaDOS-418/cpp-project-template.git ${1}
  cd ${1}
  /usr/bin/rm -rf .git
  echo "# ${1}" >| README.md
  grep -rl --color=never 'project-name' | xargs sed -i "s/project-name/${1}/g"
  git init
  git add -f .
  git commit -m "created project ${1}."

  echo " ========================   PROJECT ${1} SETUP COMPLETE.  ======================== "
}

function gpp {
    g++ -g -O2 -Ddebug \
        -Waggregate-return \
        -Wall \
        -Wcast-align \
        -Wcast-qual \
        -Wconversion \
        -Wdisabled-optimization \
        -Weffc++ \
        -Wextra \
        -Wfloat-equal \
        -Wformat-nonliteral \ 
        -Wformat-security  \
        -Wformat-y2k \
        -Wformat=2 \
        -Wimport \
        -Winit-self \
        -Winline \
        -Winvalid-pch   \
        -Wlong-long \
        -Wmisleading-indentation \ 
        -Wmissing-braces \
        -Wmissing-field-initializers \
        -Wmissing-format-attribute   \
        -Wmissing-include-dirs \
        -Wmissing-noreturn \
        -Wpacked  \
        -Wpadded \ 
        -Wparentheses \
        -Wpointer-arith \
        -Wredundant-decls \
        -Wshadow \
        -Wshadow \
        -Wstack-protector \
        -Wstrict-aliasing=2 \
        -Wswitch-default \
        -Wswitch-enum \
        -Wuninitialized \
        -Wunreachable-code -Wunused \
        -Wunused-parameter \
        -Wunused-value \
        -Wunused-variable \
        -Wvariadic-macros \
        -Wwrite-strings \
        -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=undefined -fsanitize=address \
        -pedantic  \
        -pedantic-errors \
        -pthread -latomic -mavx2
        -std=c++2b \
    $@
}

function gpe {
    gww -Werror $@
}

function generate_new_key {
  ssh-keygen -t ed25519 -C $(whoami)@$(echo $(uname -nmo; grep -P ^NAME /etc/os-release | sed -E -e 's/NAME="(.*)"/\1/g' | tr ' ' '_' ; date +%F) | tr ' ' '::')
}

function fzfupdate {
    cd ~/.fzf && git pull && ./install
}

function spac {
    sudo -i pacman -Sy $@
    if [[ $? == 0 ]]; then
        echo $@ | tr ' ' '\n' >> $DOTFILES/paclist
    fi
}

function syay {
    yay -Sy $@
    if [[ $? == 0 ]]; then
        echo $@ | tr ' ' '\n' >> $DOTFILES/yaylist
    fi
}

function spip {
    pip3 install $@
    if [[ $? == 0 ]]; then
        echo $@ | tr ' ' '\n' >> $DOTFILES/piplist
    fi
}

function ssnap {
    sudo -i snap install $@
    if [[ $? == 0 ]]; then
        echo $@ | tr ' ' '\n' >> $DOTFILES/snaplist
    fi
}

function ftstats {
    # recursive statistics on file types in directory
    # files that do not have any extensions(.foo) are treated as extensions themselves
    # hidden files and folders are excluded

    dir="${1:-.}"
    
    if [ ! -d "$dir" ]; then
        echo "directory '$dir' does not exist."
        return
    fi
    
    find "$dir" -type f -not -path '*/\.*' | sed -E 's/.*\././' | sort -r | uniq -c
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
  touch $1.cpp && touch $1.in && vim -O $1.cpp $1.in
}

function op {
  # open multiple files matching the glob in vim
    if [[ -z $1 ]]; then
        echo "no glob..."
    elif [[ `ls -l $1* | wc -l` -gt 2 ]]; then
        echo "too many matches..."
    else
        vim -O $(ls $1*)
    fi
}

function bench {
  time $@ 1>/dev/null 2>&1
}


function grl {
  grep -Rl --exclude-dir={docs,deploy,.git} --include=\*.{cpp,CPP,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcsxproj,inc,pck,sql,lua,rs,go,ts,js} $@ 2>/dev/null
}

function grn {
  grep -Rn --exclude-dir={docs,deploy,.git} --include=\*.{cpp,CPP,cc,h,H,hpp,xslt,xml,makefile,mk,yml,log\*,ksh,sh,bat,vcxproj,inc,pck,sql,lua,rs,go,ts,js} $@ 2>/dev/null
}

# ex - archive extractor
function ex {
  if [ -f $1 ] ; then
    case $1 in
      *.7z)                   7z x $1           ;;
      *.bz2)                  bunzip2 -kd $1    ;;
      *.deb)                  ar x $1           ;;
      *.gz)                   gunzip $1         ;;
      *.lzip)                 tar kxf --lzip $1 ;;
      *.lzma)                 tar kxf --lzma $1 ;;
      *.lzop)                 tar kxf --lzop $1 ;;
      *.rar)                  unrar x $1        ;;
      *.tar)                  tar kxf $1        ;;
      *.tar.bz2|*.tbz2|*.tb2) tar kxjf $1       ;;
      *.tar.bz|*.tbz)         tar kxjf $1       ;;
      *.tar.gz|*.tgz)         tar kxzf $1       ;;
      *.tar.xz|*.txz)         tar kxJf $1       ;;
      *.tar.zst)              tar kxf $1        ;;
      *.Z)                    uncompress $1     ;;
      *.zip)                  unzip $1          ;;
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

# aliases also have this
# function dh {
#     BRANCH='HEAD'
#     if [ -n $1 ]; then
#         BRANCH=$1
#     fi
#     echo $BRANCH
#     git diff --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines $BRANCH
# }
# 
# function diffhead {
#     BRANCH='HEAD'
#     if [ ! -n $1 ]; then
#         BRANCH=$1
#     fi
#     git diff --ignore-cr-at-eol --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines $BRANCH
# }

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

function nonzero_error_code { 
  printf "`local e=$? ; if [ $e -ne 0 ]; then echo $e: ; else echo '' ; fi`"
}

# get current branch in git repo
function parse_git_branch {
  BRANCH=`git rev-parse --abbrev-ref HEAD 2> /dev/null | sed -e 's/\(.*\)/\1/'`
  if [ ! "${BRANCH}" == "" ]
  then
    STAT=`parse_git_dirty`
    printf " (${BRANCH}${STAT})"
  fi

  printf ""
}

# get current status of git repo
function parse_git_dirty {
  status=`git status 2>&1 | tee`

  dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
  untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
  ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
  behind=`echo -n "${status}" 2> /dev/null | grep "Your branch is behind" &> /dev/null; echo "$?"`
  newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
  renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
  deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
  diverged=`echo -n "${status}" 2> /dev/null | grep "Your branch and.\+\?have diverged" &> /dev/null; echo "$?"`

  bits=""
  if [ "${renamed}" == "0" ]; then
    bits="*${bits}"
  fi
  if [ "${ahead}" == "0" ]; then
    bits=">${bits}"
  fi
  if [ "${behind}" == "0" ]; then
    bits="<${bits}"
  fi
  if [ "${newfile}" == "0" ]; then
    bits="+${bits}"
  fi
  if [ "${untracked}" == "0" ]; then
    bits="?${bits}"
  fi
  if [ "${deleted}" == "0" ]; then
    bits="x${bits}"
  fi
  if [ "${dirty}" == "0" ]; then
    bits="!${bits}"
  fi
  if [ "${diverged}" == "0" ]; then
    bits="Y${bits}"
  fi
  if [ ! "${bits}" == "" ]; then
    echo " ${bits}"
  else
    echo ""
  fi
}

function update_calibre {
  sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
}


function rman {
  # open a random man page from one of the sections listed in 'sections' array
  # 1 : user commands
  # 2 : system calls
  # 3 : library functions
  # 4 : device files
  # 5 : file formats
  # 6 : games and demos
  # 7 : miscellaneous
  # 8 : sys admin
  # 9 : kernel developer's manual

  # random_section=$(shuf -i 1-9 -n 1) # generate a random number in [1-9]
  local sections=("1")
  local random_section=${sections[$RANDOM % ${#sections[@]}]}
  
  find "/usr/share/man/man$random_section/" -type f -prune -o -print | shuf -n 1 | sed 's/.gz$//g' | sed 's#.*/##' |  xargs man
}

