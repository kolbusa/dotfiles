#!/bin/bash -x

function realpath() {
    if [[ "$(uname -s)" == "Linux" ]]; then
        readlink -f $1
    else
        if [[ -d "$1" ]]; then
            cd $1
            pwd -P
        else
            cd $(dirname $1)
            echo $(pwd -P)/$(basename $1)
        fi
    fi
}

HOME="$(realpath "$HOME")"
mkdir -p "$HOME"
if [[ -n "$OVERLAY" ]]; then
    OVERLAY="$(realpath "$OVERLAY")"
    mkdir -p "$OVERLAY"
fi

DOTFILES="$(dirname $(realpath $0))"
LOGS="$DOTFILES/logs"
BACKUP="$DOTFILES/backup"

rm -rf "$LOGS"
mkdir -p "$LOGS"
rm -rf "$BACKUP"
mkdir -p "$BACKUP"

for f in 01-overlay.sh 03-dotfiles.sh 04-vim.sh 05-fzf.sh 06-ghostty.sh; do
    source $DOTFILES/install-parts/$f 2>&1 | tee $LOGS/$(basename ${f/.sh/.log})
done
