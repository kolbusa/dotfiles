#!/bin/bash -x

set -e

[[ -z "$OVERLAY" ]] && return

if [[ -d "$HOME/.cache" ]]; then
    mv $HOME/.cache $OVERLAY/
else
    mkdir $OVERLAY/.cache
fi

ln -sf $OVERLAY/.cache $HOME/
