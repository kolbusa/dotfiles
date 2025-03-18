###### Early exits

# environment has already been set up
[[ -n "${BASHRC_SOURCED+X}" ]] && return
[[ -n "${CRUDE_NORC+X}" ]] && return

# This is kind of broken... we sometimes need to load most of the environment
# (mostly local modules) in order to start-up the tmux sel... so we skip the
# check for PS1 here but don't modify PS1/PROMPT_COMMAND...
#
# non-interactive shell
[[ -z "${PS1+X}${PROMPT+X}" && "${PLEASE_SOURCE_BASHRC+X}" == "X" ]] && return

find_program() {
    if [[ -n "${ZSH_VERSION+X}" ]]; then
        whence $1 || true
    else
        type -P $1 || true
    fi
}

add_to_path() {
    local mode=$1
    local varname="$2"
    shift 2
    local p
    for p in "$@"; do
        [[ -d $p ]] || continue
        if [[ "$mode" == "append" ]]; then
            ppre=""
            ppost=":$p"
        else
            ppre="$p:"
            ppost=""
        fi
        # eval "echo ":\$$varname:" | grep -qse ":$p:" || export $varname=\"$ppre\$$varname$ppost\""
        eval "export $varname=\"$ppre$(echo \$$varname | sed 's/:$p://g')$ppost\""
    done
}

use_location() {
    local method=$1
    local location=$2
    if [[ -d $location/bin ]]; then
        add_to_path $method PATH $location/bin
    else
        add_to_path $method PATH $location
    fi
    if [[ -d $location/share/man ]]; then
        add_to_path $method MANPATH $location/share/man
    fi
}

###### Source the local configuration first
[[ -f $HOME/.bashrc.local ]] && source $HOME/.bashrc.local

##### Common local
if [[ "$(uname -s)" == "Darwin" ]]; then
    __latest_ver() {
        echo $1/$(cd $1 ; ls | sort -n | sed '1!d')
    }

    export DARK_MODE=1
    export P4CONFIG=.p4config
    export CLANGD_PATH=/opt/homebrew/opt/llvm/bin/clangd
    export CLANG_FORMAT=/opt/homebrew/opt/llvm/bin/clang-format
    export PYLSP_PATH=$HOME/Library/Python/3.9/bin/pylsp

    add_to_path prepend PATH /opt/homebrew/bin
    add_to_path prepend PATH $(__latest_ver /opt/homebrew/Cellar/coreutils)/libexec/gnubin
    add_to_path prepend PATH $(__latest_ver /opt/homebrew/Cellar/findutils)/libexec/gnubin
    add_to_path prepend PATH $(__latest_ver /opt/homebrew/Cellar/gnu-tar)/libexec/gnubin
    add_to_path prepend PATH $(__latest_ver /opt/homebrew/Cellar/gnu-sed)/libexec/gnubin
    add_to_path prepend /Library/TeX/texbin

    function ssh {
        if [[ $# > 1 ]]; then
            command ssh "${(z)@}"
        else
            command ssh "${(z)@}" -t 'if test -e $HOME/bin/tmuxsel; then $HOME/bin/tmuxsel - ; else $SHELL -l ; fi'
        fi
    }

    alias tun='command ssh -L 5900:localhost:5900 -L 5001:localhost:5001 -L 10222:localhost:10222 -L 10122:localhost:10122 -N -f -T dubtsov.net'

    if [[ -n "$(find_program fortune)" ]]; then
        case $- in
            *i*)
            echo
            fortune -e -s
            echo
            ;;
        esac
    fi
    function dark() {
        export DARK_MODE=1
        local ghostty_config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
        cp $ghostty_config_dir/theme.dark $ghostty_config_dir/theme
    }
    function light() {
        export DARK_MODE=1
        local ghostty_config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
        cp $ghostty_config_dir/theme.light $ghostty_config_dir/theme
    }
else
    alias dark='export DARK_MODE=1'
    alias light='export DARK_MODE=1'

    ###### Find clangd and clang-format -- PATH or Debian/Ubuntu version
    for ver in -12 -11 '' -10 -9 -8 -7; do
        clangd__=$(find_program clangd$ver)
        clang_format__=$(find_program clang-format$ver)
        [[ -z "${CLANGD_PATH+X}" && -n "$clangd__" ]] \
            && export CLANGD_PATH="$clangd__"
        [[ -z "${CLANG_FORMAT+X}" && -n "$clang_format__" ]] \
            && export CLANG_FORMAT="$clang_format__"
    done

    if [[ -z "${PYLSP_PATH+X}" ]]; then
        PYLSP_PATH=$HOME/.local/python-Linux/bin/pylsp
        if [[ -x "$PYLSP_PATH" ]]; then
            export PYLSP_PATH
        else
            unset PYLSP_PATH
        fi
    fi
fi

###### Fixup locale in case it is not supported on this system
locale_ok=0
if test -n "$(find_program locale)"; then
    if locale -a 2>/dev/null | sed 's/-//g' | grep -iqs "$(echo $LANG | sed 's/-//g')"; then
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
if [[ -n "${PS1+X}${PROMPT+X}" ]]; then
    # Save history continuously
    if [[ -n "${BASH_VERSION+X}" ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;} history -a"
    fi

    # Base PS1 setup
    if [[ -n "${ZSH_VERSION+X}" ]]; then
        hn=${HOSTNAMEOVERRIDE:-%m}
    else
        hn=${HOSTNAMEOVERRIDE:-\\h}
    fi
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        hnfull=${HOSTNAMEOVERRIDE:-$(cat /proc/sys/kernel/hostname)}
    else
        hnfull=${HOSTNAMEOVERRIDE:-$(hostname)}
    fi

    good_fg=(1 2 3 4 5 6 8 12)
    fgc=${HOSTNAMECOLOR-}
    if [[ -z ${fgc-} ]]; then
        fgc=$(echo $hnfull \
            | od -tu1 -An \
            | tr ' ' '\n' \
            | awk '{total = total + $1} END{print total % 8}')
        if [[ -n "${ZSH_VERSION+X}" ]]; then
            fgc=$((fgc+1))
        fi
        fgc=${good_fg[$fgc]}
    fi
    bgc=${HOSTNAMEBGCOLOR:-15}

    [[ -z ${BASE_SHLVL+X} ]] && export BASE_SHLVL=$SHLVL
    REL_SHLVL=$(($SHLVL - $BASE_SHLVL))
    if [[ -n "${ZSH_VERSION+X}" ]]; then
        # TODO: background
        PS1_PRE="[(lvl: $REL_SHLVL) (bg: %j) %F{green}%n%f@%F{${fgc}}${hn}%f${STY:+$($STY)} %* %1~"
        PS1_POST="]"$'\n'"\\$ "
    else
        if [[ $fgc -gt 7 ]]; then
            fgc_idx=$((90 + $fgc - 7))
        else
            fgc_idx=$((30 + $fgc))
        fi
        if [[ $bgc -gt 7 ]]; then
            bgc_idx=$((100 + $bgc - 7))
        else
            bgc_idx=$((40 + $bgc))
        fi
        PS1_PRE="\033[0;32m\u\033[0m@\033[0;${fgc_idx}m\033[${bgc_idx}m${hn}${STY:+($STY)}\033[0m \t \W"
        # Add job and shell level information
        PS1_PRE="\033[0m[(lvl: $REL_SHLVL) (bg: \j) $PS1_PRE"
        PS1_POST="]\033[0m\r\n\\$ "
    fi

    # Load git bash prompt if available
    if [[ -f $HOME/.git-prompt.sh ]]; then
        # Must be sourced first?
        bash_git_completion=$HOME/.git-completion.bash
        if [[ -n "${BASH_VERSION-}" ]]; then
            [[ -f $bash_git_completion ]] && source $bash_git_completion
        fi
        if [[ -n "${ZSH_VERSION-}" ]]; then
            fpath=($HOME/.zsh $fpath)
        fi

        source $HOME/.git-prompt.sh
        GIT_PS1_SHOWCOLORHINTS=1
        # It is important to prepend to work better with the modules ps1
        PROMPT_COMMAND="__git_ps1 \"$PS1_PRE\" \"$PS1_POST\"; \
            ${PROMPT_COMMAND-}"
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
        local env=""
        if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
            env="$CONDA_DEFAULT_ENV"
        elif [[ -n "$VIRTUAL_ENV" ]]; then
            env="$VIRTUAL_ENV"
        fi
        if [[ -z "${ZSH_VERSION+X}" ]]; then
            PS1="${env:+\033[0;35m(${env##*/})\033[0m\n}$PS1"
        else
            PS1=${env:+%F{cyan}"(${env##*/})"%f$'\n'}$PS1
        fi
    }
    # It is important to append since we are overwriting PS1 after the git bash
    # prompt
    PROMPT_COMMAND="$PROMPT_COMMAND; __venv_ps1"

    # Add SCL information if available
    function __scl_ps1() {
        if [[ -z "${ZSH_VERSION+X}" ]]; then
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
        if [[ -z "${ZSH_VERSION+X}" ]]; then
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
if [[ -n "${BASH_VERSION+X}" ]]; then
    shopt -s extglob progcomp histappend checkwinsize cdspell
    shopt -s checkhash no_empty_cmd_completion hostcomplete
    [[ $BASH_VERSINFO -gt 3 ]] && shopt -s autocd checkjobs dirspell
fi
if [[ -n "${ZSH_VERSION+X}" ]]; then
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
if [[ -n "${ZSH_VERSION+X}" ]]; then
    SAVEHIST=$HISTSIZE
    setopt SHAREHISTORY
    setopt INC_APPEND_HISTORY
    setopt HIST_IGNORE_DUPS
    setopt EXTENDED_HISTORY
fi

export FZF_DEFAULT_OPTS='--layout=reverse --height=15 --tiebreak=begin,length,index'
if [[ -n "$(find_program fzf)" ]]; then
    [[ -n "${BASH_VERSION+X}" && -f $HOME/.fzf-completion.bash ]] && source $HOME/.fzf-completion.bash
    [[ -n "${BASH_VERSION+X}" && -f $HOME/.fzf-key-bindings.bash ]] && source $HOME/.fzf-key-bindings.bash
    [[ -n "${ZSH_VERSION+X}" && -f $HOME/.fzf-completion.zsh ]] && source $HOME/.fzf-completion.zsh
    [[ -n "${ZSH_VERSION+X}" && -f $HOME/.fzf-key-bindings.zsh ]] && source $HOME/.fzf-key-bindings.zsh
fi

###### Detect if neovim is available
if [[ -z "${EDITOR+X}" ]]; then
    if [[ -n "$(find_program nvim)" ]]; then
        export VISUAL=nvim
        export EDITOR=nvim
    else
        export VISUAL=vim
        export EDITOR=vim
    fi
fi


###### Check if less version is sufficiently new
if [[ -z "${PAGER+X}" ]]; then
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
if [[ "${VISUAL-X}" == "nvim" ]]; then
    alias vim=nvim
    alias vi='vim -u NONE -c "set ts=4 sw=4 et nosmartcase noignorecase mouse=nvi autochdir|syntax off|filetype off|let &inccommand = \"\""'
fi
#unset -f which
alias sc='tmux new-window -a'
alias tm='tmux new-window -a'
alias vimdiff='$EDITOR -d'
alias h='history'
alias view='$EDITOR -R'
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    alias psmy="ps -U ${USER:-$SLURM_JOB_USER} -u ${USER:-$SLURM_JOB_USER} -o pid,%cpu,%mem,state,vsize,cmd"
else
    alias psmy="ps -U ${USER:-$SLURM_JOB_USER} -u ${USER:-$SLURM_JOB_USER} -o pid,%cpu,%mem,state,vsize,command"
fi

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

which() {
    find_program "$@"
}

# Support non-GNU ls too
if [[ -n "$(find_program dircolors)" ]]; then
    eval $(dircolors -b)
    # I don't like bold
    export LS_COLORS=$(echo $LS_COLORS | sed 's/01;/00;/g' | sed 's/or=[^:]\+:/or=00;31:/')
else
    [[ -z "${LSCOLORS+X}" ]] && export LSCOLORS=ExfxcxdxCxegedabagacad
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
if [[ "${TERM_PROGRAM-X}" == "iTerm.app" ]]; then
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
grp() { local s=${1:-8}; sed 's/ //g' | sed -E "s/.{$s}/& /g"; }
zp() { perl -ne 'use POSIX; chomp; $s = $_; $l = length($s); $po2 = 2**POSIX::ceil(log($l)/log(2)); $padd = $po2 - $l; print "0" x $padd, $s, "\n";'; }
sanitize_hex() { echo $* | sed 's/0x//' | tr '[:lower:]' '[:upper:]'; }
d2h () { perl -e 'printf "%x\n", shift' $* | bc | zp; }
h2d () { perl -e 'printf "%d\n", hex(shift)' $* | bc | zp; }
d2b () { echo "obase=2; $*" | bc | zp; }
b2d () { echo "ibase=2; $*" | bc; }
h2b () { echo "ibase=16;obase=2; $(sanitize_hex $*)" | bc | zp; }
b2h () { echo "obase=16;ibase=2; $*" | bc | zp; }
h2e2m1 () { perl -e '$h = hex shift; $s = $h & 0x8; $e = ($h & 0x6) >> 1; $m = $h & 0x1; if ($e == 0) { $k = 0.5 * $m; printf "%s%s\n", $s ? "-" : "+", $k; } else { printf "%s%s\n", $s ? "-" : "+", 2**($e-1)*(2+$m)/2; }' $*; }
h2e4m3 () { perl -e '$h = hex shift; $s = ($h & 0x80) >> 7; $e = ($h & 0x78) >> 3; $m = $h & 0x7; if ($h & 0x7f == 0x7f) { printf "nan"; } else { $f = ($s << 31) | ((($e - 7) + 127) << 23) | ($m << 20); $f = unpack("f", pack("I", $f)); printf "%f %e %a\n", $f, $f, $f}' $*; }
h2half () { perl -e '$h = hex shift; $s = $h & 0x8000; $e = ($h & 0x7c00) >> 10; $m = $h & 0x3ff; if ($e == 0x1f) { if ($m == 0) { $k = "inf" } else { $k = "nan"}; printf "%s%s\n", $s ? "-" : "+", $k; } else { $e += 112; $f = ($s << 16) | ($e << 23) | ($m << 13); $f = unpack("f", pack("I", $f)); printf "%f %e %a\n", $f, $f, $f}' $*; }
h2bf16 () { perl -e '$h = hex shift; $h = $h << 16; $f = unpack("f", pack("I", $h)); printf "%f %e %a\n", $f, $f, $f;' $*; }
half2h () { perl -e '$f = unpack "I", pack "f", shift; $s = ($f & 0x80000000) >> 16; $e = (($f & 0x7f800000) >> 23) - 112; $m = ($f & 0x007fffff) >> 13; $h = ($s << 16) | ($e << 10) | $m; printf "0x%x\n", $h' $*; }
h2float () { perl -e '$f = unpack "f", pack "I", hex shift; printf "%f %e %a\n", $f, $f, $f;' $*; }
float2h () { perl -e '$f = unpack "I", pack "f", shift; printf "%x\n", $f;' $* | zp; }
h2double () { perl -e '$f = unpack "d", pack "Q", hex shift; printf "%f %e %a\n", $f, $f, $f;' $*; }
double2h () { perl -e '$f = unpack "Q", pack "d", shift; printf "%x\n", $f;' $* | zp; }
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
safelink_decode() {
    if [[ "$1" =~ safelinks.protection.outlook.com ]]; then
        urldecode "$(echo "$1" | sed 's/[&?]/\n/g' | sed '/^url=/!d;s/url=//')"
    else
        echo "$1"
    fi
}

export DARK_MODE=1
export P4CONFIG=.p4config

BASHRC_SOURCED=1 # do not export -- subsequent shells may need this...
