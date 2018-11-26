[ "$PROFILE_SOURCED" = "1" ] && return

if [ "$OSTYPE" == "Linux" ]; then
    export LANG=en_US.UTF8
else
    # Darwin
    export LANG=en_US.UTF-8
fi
export LC_COLLATE=C

if [[ "$(uname -s)" == "Linux" ]]; then
    HOMEBREW_DIRNAME=.linuxbrew
else
    HOMEBREW_DIRNAME=.homebrew
fi
HOMEBREW=$HOME/$HOMEBREW_DIRNAME

export PATH=$HOME/bin:$PATH
if [ -d $HOMEBREW/ ]; then
    HAVE_HOMEBREW=1
    export PATH=$HOMEBREW/bin:$PATH
    export MANPATH=$HOMEBREW/share/man:$MANPATH
    export INFOPATH=$HOMEBREW/share/info:$INFOPATH
fi

if [ -f $HOME/.profile.local ]; then
    source $HOME/.profile.local
fi

if [ -f $HOME/.bashrc -a -n "$BASH" ]; then
    source $HOME/.bashrc
fi

PROFILE_SOURCED=1 # may be needed by a subsequent shell
