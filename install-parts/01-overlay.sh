#!/bin/bash -x

set -e

# No support for refreshing
[[ "$REFRESH"  == "1" ]] && return

# Overlay is disabled
[[ -z "$OVERLAY" ]] && return

# Move pre-existing directories
for d in .cache .local .ccache .debug; do
    if [[ -d "$HOME/$d" ]]; then
        mv "$HOME/$d" "$OVERLAY/"
    else
        mkdir "$OVERLAY/$d"
    fi
    ln -sf "$OVERLAY/$d" $HOME/
done
