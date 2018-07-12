################################################################
# LOCAL VARIABLE
################################################################

ANACONDA=/home/arnob/anaconda3/bin
FLATBUFFERS=/home/arnob/binaries/flatbuffers
CHROME=/usr/lib/chrome
DOTFILES='~/dotfiles'
SAVE_CMD="python3 ~/dotfiles/save_command.py"
#phantomjs required for youtube-dl
#PHANTOMJS=/home/arnob/Downloads/phantomjs-2.1.3/bin
LIVE_LATEX_PREVIEW='~/.vim/bundle/vim-live-latex-preview/bin/'
DOT_SETUP_FILE='~/dotfiles/dot_setup.sh'

################################################################
# EXPORT
################################################################

export PATH=$PATH:$CHROME:$LIVE_LATEX_PREVIEW
export EDITOR=vim
export MYVIMRC=~/.vimrc
export HISTFILE=~/.bash_history
#export PS1=${debian_chroot:+($debian_chroot)}\u@\h:\w\$ #old value
#export PS1="[\u]:[\W]$" #[username]:[baseWorkingDirectory]

################################################################
# ALIAS
################################################################

alias gp="git push"
alias gl="git pull"
alias st="git status"
alias br="git branch"
alias log="git log"
alias emacs="emacs & &> /dev/null"
alias suvim="sudo -E gvim"
 #remove unused packages(orphans): if none found o/p :"no targets specified"
alias cleanpac="sudo pacman -Rns $(pacman -Qtdq)"
alias cdp="cd /mnt/windows/projects"
alias diffhead="git diff --ignore-cr-at-eol --ignore-space-at-eol --ignore-all-space --ignore-space-change --ignore-blank-lines HEAD"
alias prp="pipenv run python"
alias psh="pipenv shell"
alias ipshow="ip link show"
alias tux="sudo arpon -d -i wlp3s0 -D"
alias vvim="vim ~/.vimrc"
alias vbash="vim ~/.bashrc"
alias sbash="source ~/.bashrc"
alias gv="gvim"
alias spac="$SAVE_CMD sudo pacman"
alias syao="$SAVE_CMD yaourt"
alias v="vim "
alias gv="gvim "
alias vd="vimdiff "
alias gvd="gvimdiff "
alias wg="wget --recursive --timestamping --level=inf --no-remove-listing --convert-links --show-progress --progress=bar:force --no-parent --execute robots=off --compression=auto --verbose --continue --wait=2 --random-wait --reject htm,html,tmp,dstore,db,dll --directory-prefix=wget_dl --regex-type=pcre"
alias cdw="cd /mnt/windows/Users/AB/Downloads/"
alias tv="find media/TV\ Series/ -maxdepth 2 -mindepth 2 -type d  | sed -e 's/^.*\///g' | sort -bdf > list_tv.txt"
alias u0="du --max-depth=0 -h"
alias u1="du --max-depth=1 -h"
alias l="ls -lrth --color=auto"
alias upe="cat updatelog | xargs -I{} pacman -Qo {} 2>&1 | sed 's/^error:.*owns //g' > noowner && cat noowner | xargs sudo rm -rf"

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

################################################################
########           copied from su ~/.bashrc      ###############
################################################################

 [[ $- != *i* ]] && return

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

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

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

	if [[ ${EUID} == 0 ]] ; then
		PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
	else
		PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
	fi

	alias ls='ls --color=auto'
	alias grep='grep --colour=auto'
	alias egrep='egrep --colour=auto'
	alias fgrep='fgrep --colour=auto'
else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \$ '
	else
		PS1='\u@\h \w \$ '
	fi
fi

unset use_color safe_term match_lhs sh

alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias np='nano -w PKGBUILD'
alias more=less

xhost +local:root > /dev/null 2>&1

complete -cf sudo

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

shopt -s expand_aliases

# export QT_SELECT=4

# Enable history appending instead of overwriting.  #139609
shopt -s histappend

#
# # ex - archive extractor
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1     ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# better yaourt colors
export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"

