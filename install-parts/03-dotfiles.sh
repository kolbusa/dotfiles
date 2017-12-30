#!/bin/bash

declare -A moved_dirs
for d in $(cd $DOTFILES_ROOT/dotfiles; find -mindepth 1 -maxdepth 1 -type d); do
    case $d in
    ./bin) mode=merge ;;
    .) mode=merge ;;
    *) mode=replace ;;
    esac

    if [[ $mode == replace && -d $HOME/$d ]]; then
        [[ -d $OLD_DOTFILES/$d ]] && rm -rf $OLD_DOTFILES/$d
        mv $HOME/$d $OLD_DOTFILES/
    fi
done

for f in $(cd $DOTFILES_ROOT/dotfiles; find -type f); do
    d=$(dirname $f)

    if [[ -f $HOME/$f ]]; then
        mkdir -p $OLD_DOTFILES/$d
        mv $HOME/$f $OLD_DOTFILES/$d/
    fi

    mkdir -p $HOME/$d
    ln -sf $DOTFILES_ROOT/dotfiles/$f $HOME/$f
done

# vim: et ts=4 sw=4
