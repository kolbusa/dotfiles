#!/bin/bash

# TODO: support extra dotfiles dirs

for dfd in $EXTRA_DOTFILES $DOTFILES/dotfiles; do
    [[ -d "$dfd" ]] || continue
    dfd=$(realpath $dfd)
    for d in $(cd $dfd; find . -mindepth 1 -maxdepth 1 -type d); do
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
done

declare -A dotfiles_seen
for dfd in $EXTRA_DOTFILES $DOTFILES/dotfiles; do
    [[ -d "$dfd" ]] || continue
    dfd=$(realpath $dfd)
    for f in $(cd $dfd; find . -type f -o -type l); do
        d=$(dirname $f)

        # EXTRA_DOTFILES take precedence
        [[ -n "${dotfiles_seen[$f]}" ]] && continue
        dotfiles_seen[$f]=1

        if [[ -f $HOME/$f ]]; then
            mkdir -p $BACKUP/$d
            mv $HOME/$f $BACKUP/$d/
        fi

        mkdir -p $HOME/$d
        if [[ -f $dfd/$f ]]; then
            ln -sf $dfd/$f $HOME/$f
        else
            cp -a $dfd/$f $HOME/$f
        fi
    done
done

# vim: et ts=4 sw=4
