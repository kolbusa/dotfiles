#!/bin/bash

(
    export PATH=$HOME/.linuxbrew/bin:$PATH
    if [[ -d $HOME/work/.vim ]]; then
        rm -rf $HOME/work/.vim.old
        mv $HOME/work/.vim $HOME/work/.vim.old
    fi
    mv $HOME/.vim $HOME/work/
    ln -sf $HOME/work/.vim $HOME/.vim
    cat $HOME/.vim/vimrc | sed '/call plug#begin/,/call plug#end/!d' > /tmp/vimrc
    vim --cmd 'so /tmp/vimrc|PlugInstall|qa'
    rm /tmp/vimrc
    reset
)

# vim: et ts=4 sw=4
