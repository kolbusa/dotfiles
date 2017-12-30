[ "$PROFILE_SOURCED" = "1" ] && return

export LANG=en_US.UTF8
export LC_COLLATE=C

if [ -d $HOME/.homebrew ]; then
    export PATH=$HOME/bin:$PATH
    export PATH=$HOME/.homebrew/bin:$PATH
    export MANPATH=$HOME/.homebrew/share/man:$MANPATH
    export INFOPATH=$HOME/.homebrew/share/info:$INFOPATH
fi

if [ -f $HOME/.bashrc -a -n "$BASH" ]; then
    source $HOME/.bashrc
fi

PROFILE_SOURCED=1
