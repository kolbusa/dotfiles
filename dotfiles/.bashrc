###### Early exits

# environment has already been set up
[[ -n "$BASHRC_SOURCED" ]] && return

# This is kind of broken... we sometimes need to load most of the environment
# (mostly local modules) in order to start-up the tmux sel... so we skip the
# check for PS1 here but don't modify PS1/PROMPT_COMMAND...
#
# non-interactive shell
[[ -z "$PS1" && -z "$PLEASE_SOURCE_BASHRC" ]] && return

###### Source the local configuration first
[[ -f $HOME/.bashrc.local ]] && source $HOME/.bashrc.local

###### PS1 setup
if [[ -n "$PS1" ]]; then
    # Save history continuously
    export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;} history -a"

    # Base PS1 setup
    PS1_PRE="\033[0;32m\u\033[0m@\033[0;31m\h${STY:+($STY)}\033[0m \t \W"
    PS1_POST="]\033[0m\r\n\\$ "

    # Add job and shell level information
    export BASE_SHLVL=$SHLVL
    REL_SHLVL=$(($SHLVL - $BASE_SHLVL))
    PS1_PRE="\033[0m[(lvl: $REL_SHLVL) (bg: \j) $PS1_PRE"

    # Load git bash prompt if available
    if [[ -f $HOME/.git-prompt.sh ]]; then
        source $HOME/.git-prompt.sh
        export GIT_PS1_SHOWCOLORHINTS=1
        # It is important to prepend to work better with the modules ps1
        export PROMPT_COMMAND="__git_ps1 \"$PS1_PRE\" \"$PS1_POST\"; \
            $PROMPT_COMMAND"
    else
        function __plain_ps1() {
            PS1="$1$2"
        }
        # It is important to prepend to work better with the modules ps1
        export PROMPT_COMMAND="__plain_ps1 \"$PS1_PRE\" \"$PS1_POST\"; \
            $PROMPT_COMMAND"
    fi

    # Add virtualenv if available
    function __venv_ps1() {
        PS1="${VIRTUAL_ENV:+\033[0;35m(${VIRTUAL_ENV##*/})\033[0m\n}$PS1"
    }
    # It is important to append since we are overwriting PS1 after the git bash
    # prompt
    export PROMPT_COMMAND="$PROMPT_COMMAND; __venv_ps1"
fi

###### Configure the shell optons
shopt -s extglob progcomp histappend checkwinsize cdspell
shopt -s checkhash no_empty_cmd_completion hostcomplete
[[ $BASH_VERSINFO -gt 3 ]] && shopt -s autocd checkjobs dirspell

###### Configure history
HISTFILE=$HOME/.my_bash_history
HISTFILESIZE=100000
HISTSIZE=100000

###### Detect if neovim is available
if [[ -z "$EDITOR" ]]; then
    if [[ -n "$(which nvim 2> /dev/null)" ]]; then
        export VISUAL=nvim
        export EDITOR=nvim
    else
        export VISUAL=vim
        export EDITOR=vim
    fi
fi

###### Check if less version is sufficiently new
if [[ -z "$PAGER" ]]; then
    export PAGER=less
    if [[ $(less -V | sed '1!d;s/^less \([0-9]\+\).*/\1/') -ge 530 ]]; then
        export LESS="-RF"
    else
        export LESS="-R"
    fi
fi

###### If there is a custom pythonrc, source it!
[[ -f $HOME/.pythonrc ]] && export PYTHONSTARTUP=$HOME/.pythonrc

###### Aliases
[[ "$VISUAL" == "nvim" ]] && alias vim=nvim
unset -f which
alias sc='tmux new-window'
alias tm='tmux new-window'
alias vimdiff='nvim -d'
alias h='history'
alias view='vim -R'
alias psmy='ps -U rsdubtso -u rsdubtso -o pid,%cpu,%mem,state,vsize,cmd'

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

# Support non-GNU ls too
if [[ -z "$LSCOLORS" ]]; then
    if ls --color=auto &>/dev/null; then
        # Linux or GNU ls
        alias ls='ls --color=auto -F --group-directories-first'
        eval `dircolors -b` # assumes that dircolors is always available
    else
        # BSD (tested on Darwin only)
        alias ls='ls -G'
        export LSCOLORS=ExfxcxdxCxegedabagacad
    fi
fi

###### Conversion utils
sanitize_hex() { echo $* | sed 's/0x//' | tr '[:lower:]' '[:upper:]'; }
d2h () { echo "obase=16; $*" | bc; }
h2d () { echo "ibase=16; $(sanitize_hex $*)" | bc; }
d2b () { echo "obase=2; $*" | bc; }
b2d () { echo "ibase=2; $*" | bc; }
h2b () { echo "ibase=16;obase=2; $(sanitize_hex $*)" | bc; }
b2h () { echo "obase=16;ibase=2; $*" | bc; }
h2float () { perl -e '$f = unpack "f", pack "L", hex shift; printf "%f\n", $f;' $*; }
float2h () { perl -e '$f = unpack "L", pack "f", shift; printf "0x%x\n", $f;' $*; }

###### Find clangd and clang-format -- PATH or Debian/Ubuntu version
for ver in '' -9 -8 -7; do
    clangd__=$(type -P clangd$ver)
    clang_format__=$(type -P clang-format$ver)
    [[ -z "$CLANGD_PATH" && -n "$clangd__" ]] \
        && export CLANGD_PATH="$clangd__"
    [[ -z "$CLANG_FORMAT" && -n "$clang_format__" ]] \
        && export CLANG_FORMAT="$clang_format__"
done

BASHRC_SOURCED=1 # do not export -- subsequent shells may need this...
