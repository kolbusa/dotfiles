# vim: et ts=4 sw=4 ft=bash

(
    export PATH=$HOME/.linuxbrew/bin:$PATH
    pip install protobuf xlsxwriter # for analyzer
) 2>&1 | tee $LOGS/5python.pip

