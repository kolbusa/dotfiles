#!/bin/sh

(
    ROOT=$DOTFILES/ghostty

    CFGDIR="$HOME/.config/ghostty"
    mkdir -p "$CFGDIR"
    test -f "$CFGDIR/config" && mv "$CFGDIR/config" "$CFGDIR/config.sv"
    ln -sf "$ROOT/config" "$CFGDIR"
    ln -sf "$ROOT/theme.dark" "$CFGDIR"
    ln -sf "$ROOT/theme.light" "$CFGDIR"
    cat "$ROOT/theme.dark" > "$CFGDIR/theme"

    mkdir -p "$CFGDIR"
    test -d "$CFGDIR/themes" && mv "$CFGDIR/themes" "$CFGDIR/themes.sv"
    ln -sf "$ROOT/themes" "$CFGDIR"
)

# vim: et ts=4 sw=4
