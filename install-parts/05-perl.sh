#!/bin/bash

(
    export PATH=$HOME/.linuxbrew/bin:$PATH
    echo yes | cpan install local::lib # for EC scripts
    echo yes | cpan install SVN::Core # for subversion
    echo yes | cpan install Term::ReadKey # for subversion
) 2>&1 | tee $LOGS/4perl.cpan

# vim: et ts=4 sw=4
