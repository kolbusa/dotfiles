###### Early exits

# environment has already been set up
[[ -n "$BASHRC_SOURCED" ]] && return

# This is kind of broken... we sometimes need to load most of the environment
# (mostly local modules) in order to start-up the tmux sel... so we skip the
# check for PS1 here but don't modify PS1/PROMPT_COMMAND...
#
# non-interactive shell
[[ -z "$PS1$PROMPT" && -z "$PLEASE_SOURCE_BASHRC" ]] && return

find_program() {
    if [[ -n "$ZSH_VERSION" ]]; then
        whence $1
    else
        type -P $1
    fi
}

prepend_to_path() {
    local varname=$1
    shift
    local p
    for p in "$@"; do
        [[ -d $p ]] || continue
        eval "echo ":\$$varname:" | grep -qse ":$p:" || export $varname=\"$p:\$$varname\""
    done
}

use_location() {
    if [[ -d $1/bin ]]; then
        prepend_to_path PATH $1/bin
    else
        prepend_to_path PATH $1
    fi
    prepend_to_path MANPATH $1/share/man
}

###### Source the local configuration first
[[ -f $HOME/.bashrc.local ]] && source $HOME/.bashrc.local

###### Fixup locale in case it is not supported on this system
locale_ok=0
if test -n "$(find_program locale)"; then
    if locale -a | sed 's/-//g' | grep -iqs $(echo $LANG | sed 's/-//g'); then
        locale_ok=1
    fi
fi
if test "$locale_ok" = "0"; then
    export LANG=C
    export LC_ALL=C
    export LC_CTYPE=C
else
    export LC_ALL=
    export LC_CTYPE=
fi

##### Per-user tools
export PATH=$HOME/bin:$PATH

###### PS1 setup
# XXX: additional check for __venv_ps1 is there to prevent duplicate entries
# in the PROMPT_COMMAND. Update the check if a change in the PROMPT_COMMAND
# logic affects it.
# TODO: zsh version
if [[ -n "$PS1$PROMPT" ]]; then
    # Save history continuously
    if [[ -n "$BASH_VERSION" ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;} history -a"
    fi

    # Base PS1 setup
    hostnamecolor=$(hostname \
        | od \
        | tr ' ' '\n' \
        | awk '{total = total + $1} END{print 1 + (total % 6)}')

    [[ -z $BASE_SHLVL ]] && export BASE_SHLVL=$SHLVL
    REL_SHLVL=$(($SHLVL - $BASE_SHLVL))
    if [[ -n "$ZSH_VERSION" ]]; then
        PS1_PRE="[(lvl: $REL_SHLVL) (bg: %j) %F{green}%n%f@%F{${hostnamecolor}}%m%f${STY:+$($STY)} %* %1~"
        PS1_POST="]"$'\n'"\\$ "
    else
        PS1_PRE="\033[0;32m\u\033[0m@\033[0;$((30 + ${hostnamecolor}))m\h${STY:+($STY)}\033[0m \t \W"
        PS1_PRE="\033[0m[(lvl: $REL_SHLVL) (bg: \j) $PS1_PRE"
        PS1_POST="]\033[0m\r\n\\$ "
        # Add job and shell level information
    fi

    # Load git bash prompt if available
    if [[ -f $HOME/.git-prompt.sh ]]; then
        # Must be sourced first?
        bash_git_completion=$HOME/.git-completion.bash
        if [[ -n "$BASH_VERSION" ]]; then
            [[ -f $bash_git_completion ]] && source $bash_git_completion
        fi
        if [[ -n "$ZSH_VERSION" ]]; then
            fpath=($HOME/.zsh $fpath)
        fi

        source $HOME/.git-prompt.sh
        GIT_PS1_SHOWCOLORHINTS=1
        # It is important to prepend to work better with the modules ps1
        PROMPT_COMMAND="__git_ps1 \"$PS1_PRE\" \"$PS1_POST\"; \
            $PROMPT_COMMAND"
    else
        function __plain_ps1() {
            PS1="$1$2"
        }
        # It is important to prepend to work better with the modules ps1
        PROMPT_COMMAND="__plain_ps1 \"$PS1_PRE\" \"$PS1_POST\"; \
            $PROMPT_COMMAND"
    fi

    # Add virtualenv if available
    function __venv_ps1() {
        if [[ -z "$ZSH_VERSION" ]]; then
            PS1="${VIRTUAL_ENV:+\033[0;35m(${VIRTUAL_ENV##*/})\033[0m\n}$PS1"
        else
            PS1=${VIRTUAL_ENV:+%F{cyan}"(${VIRTUAL_ENV##*/})"%f$'\n'}$PS1
        fi
    }
    # It is important to append since we are overwriting PS1 after the git bash
    # prompt
    PROMPT_COMMAND="$PROMPT_COMMAND; __venv_ps1"

    # Add SCL information if available
    function __scl_ps1() {
        if [[ -z "$ZSH_VERSION" ]]; then
            PS1="${X_SCLS:+\033[0;91m(${X_SCLS%% })\033[0m\n}$PS1"
        else
            PS1=${X_SCLS:+%F{red}"(${X_SCLS%% })"%f$'\n'}$PS1
        fi
    }
    # It is important to append since we are overwriting PS1 after the git bash
    # prompt
    PROMPT_COMMAND="$PROMPT_COMMAND; __scl_ps1"

    # List loaded modules
    function __modules_ps1() {
        if [[ -z "$ZSH_VERSION" ]]; then
            PS1="${LOADEDMODULES:+\033[0;94m(${LOADEDMODULES%% })\033[0m\n}$PS1"
        else
            PS1=${LOADEDMODULES:+%F{blue}"(${LOADEDMODULES//:/ })"%f$'\n'}$PS1
        fi
    }
    # It is important to append since we are overwriting PS1 after the git bash
    # prompt
    PROMPT_COMMAND="$PROMPT_COMMAND; __modules_ps1"
fi

###### Configure the shell optons
if [[ -n "$BASH_VERSION" ]]; then
    shopt -s extglob progcomp histappend checkwinsize cdspell
    shopt -s checkhash no_empty_cmd_completion hostcomplete
    [[ $BASH_VERSINFO -gt 3 ]] && shopt -s autocd checkjobs dirspell
fi
if [[ -n "$ZSH_VERSION" ]]; then
    bindkey -e
    autoload -U select-word-style
    select-word-style bash
    setopt +o nomatch

    autoload -U compinit && compinit -i
    zmodload -i zsh/complist

    bindkey "\e[3~" delete-char

    setopt interactive_comments

    unset PROMPT

    function precmd() {
        eval "$PROMPT_COMMAND"
    }

    iterm2_shell_integration=$HOME/.iterm2_shell_integration.zsh
    [[ -e $iterm2_shell_integration ]] && source $iterm2_shell_integration
fi


###### Configure history
HISTFILE=$HOME/.my_bash_history
HISTFILESIZE=100000
HISTSIZE=100000
if [[ -n "$ZSH_VERSION" ]]; then
    SAVEHIST=$HISTSIZE
    setopt SHAREHISTORY
    setopt INC_APPEND_HISTORY
    setopt HIST_IGNORE_DUPS
    setopt EXTENDED_HISTORY
fi

export FZF_DEFAULT_OPTS='--layout=reverse --height=15 --tiebreak=begin,length,index'
if [[ -n "$(find_program fzf)" ]]; then
    [[ -n "$BASH_VERSION" && -f $HOME/.fzf-completion.bash ]] && source $HOME/.fzf-completion.bash
    [[ -n "$BASH_VERSION" && -f $HOME/.fzf-key-bindings.bash ]] && source $HOME/.fzf-key-bindings.bash
    [[ -n "$ZSH_VERSION" && -f $HOME/.fzf-completion.zsh ]] && source $HOME/.fzf-completion.zsh
    [[ -n "$ZSH_VERSION" && -f $HOME/.fzf-key-bindings.zsh ]] && source $HOME/.fzf-key-bindings.zsh
fi

###### Detect if neovim is available
if [[ -z "$EDITOR" ]]; then
    if [[ -n "$(find_program nvim)" ]]; then
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
    if [[ $(less -V | sed -E '1!d;s/^less ([0-9]+).*$/\1/') -ge 530 ]]; then
        export LESS="-RF"
    else
        export LESS="-R"
    fi
fi

###### If there is a custom pythonrc, source it!
[[ -f $HOME/.pythonrc ]] && export PYTHONSTARTUP=$HOME/.pythonrc

###### Aliases
[[ "$VISUAL" == "nvim" ]] && alias vim=nvim
#unset -f which
alias sc='tmux new-window'
alias tm='tmux new-window'
alias vimdiff='nvim -d'
alias h='history'
alias view='vim -R'
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    alias psmy="ps -U $USER -u $USER -o pid,%cpu,%mem,state,vsize,cmd"
else
    alias psmy="ps -U $USER -u $USER -o pid,%cpu,%mem,state,vsize,command"
fi
alias dark='export DARK_MODE=1'
alias light='export DARK_MODE=0'

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
if [[ -n "$(find_program dircolors)" ]]; then
    eval $(dircolors -b)
    # I don't like bold
    export LS_COLORS=$(echo $LS_COLORS | sed 's/01;/00;/g' | sed 's/or=[^:]\+:/or=00;31:/')
else
    [[ -z "$LSCOLORS" ]] && export LSCOLORS=ExfxcxdxCxegedabagacad
fi
lsopts="-F"
if ls --group-directories-first &>/dev/null; then
    lsopts="$lsopts --group-directories-first"
fi
if ls --color=auto &>/dev/null; then
    lsopts="$lsopts --color=auto"
fi
if ls -G &>/dev/null; then
    lsopts="$lsopts -G"
fi
alias ls="ls $lsopts"

###### This seems to be generally useful
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    function tabcolor_ {
      echo -n -e "\033]6;1;bg;red;brightness;$1\a"
      echo -n -e "\033]6;1;bg;green;brightness;$2\a"
      echo -n -e "\033]6;1;bg;blue;brightness;$3\a"
    }
    function tabcolor {
        tabcolor_ $(jot -r 1 0 255) $(jot -r 1 0 255) $(jot -r 1 0 255)
    }
    tabcolor
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
h2double () { perl -e '$f = unpack "d", pack "Q", hex shift; printf "%f\n", $f;' $*; }
double2h () { perl -e '$f = unpack "Q", pack "d", shift; printf "0x%x\n", $f;' $*; }

###### Find clangd and clang-format -- PATH or Debian/Ubuntu version
for ver in -12 -11 '' -10 -9 -8 -7; do
    clangd__=$(find_program clangd$ver)
    clang_format__=$(find_program clang-format$ver)
    [[ -z "$CLANGD_PATH" && -n "$clangd__" ]] \
        && export CLANGD_PATH="$clangd__"
    [[ -z "$CLANG_FORMAT" && -n "$clang_format__" ]] \
        && export CLANG_FORMAT="$clang_format__"
done

if [[ -z "$PYLSP_PATH" ]]; then
    PYLSP_PATH=$HOME/.local/python-Linux/bin/pylsp
    if [[ -x "$PYLSP_PATH" ]]; then
        export PYLSP_PATH
    else
        unset PYLSP_PATH
    fi
fi

BASHRC_SOURCED=1 # do not export -- subsequent shells may need this...
