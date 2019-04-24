#!/bin/bash

for dfd in $EXTRA_DOTFILES $DOTFILES/dotfiles; do
    [[ -d "$dfd" ]] || continue
    dfd=$(realpath $dfd)
    for d in $(cd $dfd; find . -mindepth 1 -maxdepth 1 -type d); do
        case $d in
        ./bin) mode=merge ;;
        .) mode=merge ;;
        *) mode=replace ;;
        esac

        if [[ "$mode" == replace ]]; then
            rm -rf $BACKUP/$d
            mv -f $HOME/$d $BACKUP/
        fi
    done
done

dotfiles_seen=""
for dfd in $EXTRA_DOTFILES $DOTFILES/dotfiles; do
    [[ -d "$dfd" ]] || continue
    dfd=$(realpath $dfd)
    for f in $(cd $dfd; find . -type f -o -type l); do
        d=$(dirname $f)

        # EXTRA_DOTFILES take precedence
        # XXX: this is a workaround for lack of associative arrays in macOS's bash 3.x
        grep -Fqs "@$f@" <<< "$dotfiles_seen" && continue
        dotfiles_seen="$dotfiles_seen@$f@"

        # TODO: clean up
        suffix=''
        [[ "$(basename $f)" == ".bashrc" && "$BASHRC_USER_SUFFIX" == "1" ]] \
            && suffix=.$USER
        [[ "$(basename $f)" == ".profile" && "$PROFILE_USER_SUFFIX" == "1" ]] \
            && suffix=.$USER

        if [[ -f $HOME/$f$suffix ]]; then
            mkdir -p $BACKUP/$d
            mv $HOME/$f$suffix $BACKUP/$d/
        fi

        mkdir -p $HOME/$d
        if [[ -f $dfd/$f ]]; then
            ln -sf $dfd/$f $HOME/$f$suffix
        else
            cp -a $dfd/$f $HOME/$f$suffix
        fi
    done
done

# vim: et ts=4 sw=4
