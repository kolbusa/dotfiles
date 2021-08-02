#!/bin/bash

(
    ROOT=$DOTFILES/fzf
    fzf=$ROOT/$(uname -s)-$(uname -m)/fzf
    mkdir -p $HOME/bin
    ln -sf $fzf $HOME/bin/fzf
    ln -sf $ROOT/completion.bash $HOME/.fzf-completion.bash
    ln -sf $ROOT/key-bindings.bash $HOME/.fzf-key-bindings.bash
    ln -sf $ROOT/completion.zsh $HOME/.fzf-completion.zsh
    ln -sf $ROOT/key-bindings.zsh $HOME/.fzf-key-bindings.zsh
)

# vim: et ts=4 sw=4
