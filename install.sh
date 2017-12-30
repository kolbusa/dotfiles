#!/bin/bash

# for f in $(find install-parts -type f -iname "*.sh" | sort -n); do
#     source $f
# done

source install-parts/01-init.sh
source install-parts/02-homebrew.sh
source install-parts/03-dotfiles.sh
source install-parts/04-vim.sh
source install-parts/05-perl.sh
source install-parts/06-python.sh
