# This file is meant to be sourced not only by bash by by other shells as
# well, hence it contains the most basic setup and then sources ~/.bashrc if
# the current shell is bash.

[ "${PROFILE_SOURCED+X}" = "1" ] && return
[ -n "${CRUDE_NORC+X}" ] && return

if [ "${OSTYPE+X}" = "Linux" ]; then
    export LANG=en_US.UTF8
else
    export LANG=en_US.UTF-8
fi
export LC_COLLATE=C

if [ -d $HOME/bin ]; then
    export PATH=$HOME/bin:$PATH
fi

if [ -f $HOME/.profile.local ]; then
    source $HOME/.profile.local
fi

if [ -f $HOME/.bashrc -a -n "${BASH_VERSION+X}${ZSH_VERSION+X}" ]; then
    source $HOME/.bashrc
fi

PROFILE_SOURCED=1 # do not export; may be needed by a subsequent shell
