# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=2000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias tlvl='tmux a -t morning_level'
alias tmain='tmux a -t main'

# Alias to run command to see what port theme webserver is running on
alias webport='lsof -i | grep node'
# alias to clean /tmp/ but to leave tmux and ssh
alias cleantmp='find /tmp/ -maxdepth 1 -user sweinbrenner ! -name "tmux*" ! -name "ssh*" -exec rm -fr "{}" \;'

#cdls function alias
function cdl () {
  cd $1
  ls -alF
}

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

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

# Adding export path for devtools per Development_tools wiki
export PATH=$PATH:~/projects/theme_devtools/
# Ccache related
export PATH=/usr/lib/ccache:$PATH
export CCACHE_BASEDIR=$HOME

#githelpfulhints
function git_branch_line
{
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function gack
{
  project_root=`git rev-parse --show-toplevel`
  ack "$@" $project_root
}

BLUE="\[\033[0;34m\]"
RED="\[\033[0;31m\]"
LIGHT_GRAY="\[\033[0;37m\]"
NOCOLOR="\[\033[00m\]"

PS1="$LIGHT_GRAY\u@\h$NOCOLOR:$BLUE\w$NOCOLOR$RED\
  \$(git_branch_line)$NOCOLOR\$ "

export PATH=/home/theme/bin:$PATH

if [ ! "${THEME_HOST}" ]; then
  export THEME_HOST=$(dig axfr $(dnsdomainname) | grep CNAME | grep $(hostname) | cut -f1 -d. | grep -v -E -e '-sf$|-centreon|-graphite|-ldap|-ntp')
  if [ ! "${THEME_HOST}" ]; then
    export THEME_HOST=$(hostname)
  fi
fi

if [ ! "${THEME_SYS}" ]; then
  export THEME_SYS=$(echo ${THEME_HOST} | grep -o '[^-]*$')
fi

if [ ! "${ALL_HOSTS}" ]; then
  export ALL_HOSTS="$(echo $(dig axfr $(dnsdomainname) | grep CNAME | cut -f1 -d. | grep -- -${THEME_SYS} | grep -v -E -e '-sf$|-centreon|-graphite|-ldap|-ntp'))"
fi
if [ ! "${OTHER_HOSTS}" ]; then
  OTHER_HOSTS=""
  for h in ${ALL_HOSTS}; do
    if [ "${h}" != "${THEME_HOST}" ]; then
      if [ "${OTHER_HOSTS}" ]; then
        OTHER_HOSTS="${OTHER_HOSTS} ${h}"
      else
        OTHER_HOSTS="${h}"
      fi
    fi
  done
  export OTHER_HOSTS
fi

case "$THEME_SYS" in
  prod|dr)  hostcolor='\[\033[00;31m\]' ;;
  uat|dev8) hostcolor='\[\033[00;35m\]' ;;
  pre)      hostcolor='\[\033[00;36m\]' ;;
esac


# Modify prompt
# ☞
# ⚡
# 
symbol="->"
function parse_git_dirty { # show * next to branch name if unclean
    [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working directory clean" ]] && echo "*"
}
parse_git_branch () { # show current branch name
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
}
function git_stash_size { # show # of stashes for current repo
  lines=$(git stash list -n 100 2> /dev/null) || return
  if [ "${#lines}" -gt 0 ]
  then
    count=$(echo "$lines" | wc -l | sed 's/^[ \t]*//') # strip tabs
    echo " ["${count#}"] "
  fi
}
PROMPT_DIRTRIM=4
export PS1="\u@${hostcolor}${THEME_HOST}:\[\033[1m\]\w\[\033[00m\]\[\033[33m\]\$(parse_git_branch)\[\033[31m\]\$(git_stash_size)\[\033[00m\] \[\033[36m\]$symbol\[\033[00m\] "
