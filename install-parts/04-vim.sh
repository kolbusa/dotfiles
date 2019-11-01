#!/bin/bash

(
    # XXX: this is problematic if the system has an old vim...
    if [[ -n "$HOMEBREW" && -d "$HOMEBREW/" ]]; then
        export PATH=$HOMEBREW/bin:$PATH
    fi

    if type -p "nvim" >& /dev/null; then
        vim=nvim
    else
        vim=vim
    fi

    # backup the overlay .vim
    if [[ -d $OVERLAY/.vim ]]; then
        mv $OVERLAY/.vim $BACKUP/
    fi

    if [[ -n "$OVERLAY" ]]; then
        mv $HOME/.vim $OVERLAY/
        ln -sf $OVERLAY/.vim $HOME/.vim
    fi
    cat $HOME/.vim/vimrc \
        | sed '/call plug#begin/,/call plug#end/!d' \
        > /tmp/vimrc
    $vim --cmd 'so /tmp/vimrc|PlugInstall|qa'
    rm /tmp/vimrc
    reset
)

# vim: et ts=4 sw=4
