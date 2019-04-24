[ "$PROFILE_SOURCED" = "1" ] && return

if [ "$OSTYPE" == "Linux" ]; then
    export LANG=en_US.UTF8
else
    # Darwin
    export LANG=en_US.UTF-8
fi
export LC_COLLATE=C

if [[ "$(uname -s)" == "Linux" ]]; then
    HOMEBREW=$(readlink -f $HOME/.linuxbrew)
else
    HOMEBREW=$HOME/.homebrew
fi

export PATH=$HOME/bin:$PATH
if [ -d $HOMEBREW/ ]; then
    export HOMEBREW
    export HAVE_HOMEBREW=1
    export PATH=$HOMEBREW/bin:$PATH
    export PATH=$HOMEBREW/sbin:$PATH
    export MANPATH=$HOMEBREW/share/man:$MANPATH
    export INFOPATH=$HOMEBREW/share/info:$INFOPATH
    for u in coreutils findutils gnu-sed; do
        gnubin=$HOMEBREW/opt/$u/libexec/gnubin
        if [ -d $gnubin ]; then
            export PATH=$gnubin:$PATH
        fi
    done
else
    export HAVE_HOMEBREW=0
    unset HOMEBREW
fi

if [ -f $HOME/.profile.local ]; then
    source $HOME/.profile.local
fi

if [ -f $HOME/.bashrc -a -n "$BASH" ]; then
    source $HOME/.bashrc
fi

PROFILE_SOURCED=1 # may be needed by a subsequent shell
