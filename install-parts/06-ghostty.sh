#!/bin/sh

(
    ROOT=$DOTFILES/ghostty

    CFGDIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    mkdir -p "$CFGDIR"
    test -f "$CFGDIR/config" && mv "$CFGDIR/config" "$CFGDIR/config.sv"
    ln -sf "$ROOT/config" "$CFGDIR"
    ln -sf "$ROOT/theme.dark" "$CFGDIR"
    ln -sf "$ROOT/theme.light" "$CFGDIR"
    cat "$ROOT/theme.dark" > "$CFGDIR/theme"

    THMDIR="$HOME/.config/ghostty"
    mkdir -p "$THMDIR"
    test -d "$THMDIR/themes" && mv "$THMDIR/themes" "$THMDIR/themes.sv"
    ln -sf "$ROOT/themes" "$THMDIR"
)

# vim: et ts=4 sw=4
