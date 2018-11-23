[[ -z "$PS1" ]] && return
[[ -n "$BASHRC_SOURCED" ]] && return

# TODO: shell level

PS1_PRE="\033[0m[\033[0;32m\u\033[0m@\033[0;31m\h${STY:+($STY)}\033[0m \t \W"
PS1_POST="]\033[0m\r\n\\$ "
export PROMPT_COMMAND="history -a"
if [[ -f $HOME/.git-prompt.sh ]]; then
    export GIT_PS1_SHOWCOLORHINTS=1
    export PROMPT_COMMAND="$PROMPT_COMMAND; __git_ps1 \"$PS1_PRE\" \"$PS1_POST\""
else
    export PS1="$PS1_PRE$PS1_POST"
fi

if [[ "$(uname -s)" == "Linux" ]]; then
    HOMEBREW_DIRNAME=.linuxbrew
else
    HOMEBREW_DIRNAME=.homebrew
fi
HOMEBREW=$HOME/$HOMEBREW_DIRNAME
__completion=$HOMEBREW/etc/bash_completion
[[ -f $__completion ]] && source $__completion

if [[ `uname -s` == "Darwin" ]]; then
    alias ls='ls -G'
    export LSCOLORS=ExfxcxdxCxegedabagacad
else
    eval `dircolors -b`
    alias ls='ls --color=auto -F --group-directories-first'
fi

unset -f which

if [[ -n "$(which nvim 2> /dev/null)" ]]; then
    export VISUAL=nvim
    export EDITOR=nvim
    alias vim=nvim
else
    export VISUAL=vim
    export EDITOR=vim
fi
export PAGER=less
export LESS="-RF"

# export GREP_OPTIONS=--color
export PYTHONSTARTUP=$HOME/.pythonrc

export GIT_PROMPT_FETCH_REMOTE_STATUS=0

alias sc='tmux new-window'
alias tm='tmux new-window'
alias vimdiff='nvim -d'
alias h='history'
alias view='vim -R'
alias psmy='ps -U rsdubtso -u rsdubtso -o pid,%cpu,%mem,state,vsize,cmd'
alias hidebrew='source ~/bin/hidebrew'

# Typos
alias mkdor='mkdir'
alias maek='make'
alias vmi='vim'
alias ivm='vmi'
alias dc='cd'
alias mkdr='mkdir'
alias it='git'
alias gi='git'
alias greo='grep'

# Conversion utils
sanitize_hex() { echo $* | sed 's/0x//' | tr '[:lower:]' '[:upper:]'; }
d2h () { echo "obase=16; $*" | bc; }
h2d () { echo "ibase=16; $(sanitize_hex $*)" | bc; }
d2b () { echo "obase=2; $*" | bc; }
b2d () { echo "ibase=2; $*" | bc; }
h2b () { echo "ibase=16;obase=2; $(sanitize_hex $*)" | bc; }
b2h () { echo "obase=16;ibase=2; $*" | bc; }
h2float () { perl -e '$f = unpack "f", pack "L", hex shift; printf "%f\n", $f;' $*; }
float2h () { perl -e '$f = unpack "L", pack "f", shift; printf "0x%x\n", $f;' $*; }

shopt -s extglob progcomp histappend checkwinsize cdspell
shopt -s checkhash no_empty_cmd_completion hostcomplete
[[ $BASH_VERSINFO -gt 3 ]] && shopt -s autocd checkjobs dirspell

HISTFILE=$HOME/.my_bash_history
HISTFILESIZE=100000
HISTSIZE=100000

[[ -f $HOME/.bashrc.local ]] && source $HOME/.bashrc.local

BASHRC_SOURCED=1
