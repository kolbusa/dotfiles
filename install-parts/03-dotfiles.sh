#!/bin/bash

# TODO: support extra dotfiles dirs

declare -A moved_dirs
for d in $(cd $DOTFILES/dotfiles; find . -mindepth 1 -maxdepth 1 -type d); do
    case $d in
    ./bin) mode=merge ;;
    .) mode=merge ;;
    *) mode=replace ;;
    esac

    if [[ $mode == replace && -d $HOME/$d ]]; then
        [[ -d $BACKUP/$d ]] && rm -rf $BACKUP/$d
        mv $HOME/$d $BACKUP/
    fi
done

for f in $(cd $DOTFILES/dotfiles; find . -type f -o -type l); do
    d=$(dirname $f)

    if [[ -f $HOME/$f ]]; then
        mkdir -p $BACKUP/$d
        mv $HOME/$f $BACKUP/$d/
    fi

    mkdir -p $HOME/$d
    if [[ -f $DOTFILES/dotfiles/$f ]]; then
        ln -sf $DOTFILES/dotfiles/$f $HOME/$f
    else
        cp -a $DOTFILES/dotfiles/$f $HOME/$f
    fi
done

# vim: et ts=4 sw=4
