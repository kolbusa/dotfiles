#!/bin/bash

[[ "$SKIP_BREW" == 1 ]] && return

BOOTSTRAP=$DOTFILES/bootstrap

if [[ "$(uname -s)" == Linux ]]; then
    git_ok=0
    type -p git &> /dev/null && git_ok=1
    [[ -n "$FORCE_BOOTSTRAP_GIT" ]] && git_ok=0

    if [[ $git_ok == 0 ]]; then
        # Bootstrap git
        (
            mkdir -p $BOOTSTRAP/git
            cd $BOOTSTRAP/git
            wget --no-check-certificate https://www.kernel.org/pub/software/scm/git/git-2.11.0.tar.gz
            tar xzf git-2.11.0.tar.gz
            cd git-2.11.0
            patch < $DOTFILES/patches/git-patch-no-perl
            autoreconf
            ./configure --prefix=$BOOTSTRAP/git/install --without-perl
            make -j && make install
        )
        export PATH=$BOOTSTRAP/git/install/bin:$PATH
        git --version
    fi 2>&1 | tee $LOGS/0bootstrap.git

    ruby_ok=0
    if type -p ruby &> /dev/null && \
        ruby -e \
            'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("1.8.6"))' &> /dev/null
    then
        ruby_ok=1
    fi
    [[ -n "$DONT_BOOTSTRAP_RUBY" ]] && ruby_ok=1
    [[ -n "$FORCE_BOOTSTRAP_RUBY" ]] && ruby_ok=0

    if [[ $ruby_ok == 0 ]]; then
        # Bootstrap ruby
        (
            mkdir -p $BOOTSTRAP/ruby
            cd $BOOTSTRAP/ruby
            wget --no-check-certificate https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.6.tar.gz
            tar xzf ruby-2.2.6.tar.gz
            cd ruby-2.2.6
            ./configure --prefix=$BOOTSTRAP/ruby/install
            make -j && make install
        )
        export PATH=$BOOTSTRAP/ruby/install/bin:$PATH
    fi 2>&1 | tee $LOGS/0bootstrap.ruby
fi

if [[ "$(uname -s)" == Darwin ]]; then
    true
fi

###############################################################################

HOMEBREW_DIRNAME=.homebrew
HOMEBREW=$HOME/$HOMEBREW_DIRNAME
if [[ -n "$OVERLAY" ]]; then
    HOMEBREW_OVERLAY=$OVERLAY/$HOMEBREW_DIRNAME
    mkdir -p $HOMEBREW_OVERLAY
    ln -sf $HOMEBREW_OVERLAY $HOMEBREW
else
    mkdir -p $HOMEBREW
fi

###############################################################################

if [[ "$(uname -s)" == "Linux" ]]; then
    unset APPS APPS_LOCAL
    export LANG=C
    unset LC_COLLATE
    export HOMEBREW_ARCH=core2

    git clone --depth 1 \
        https://github.com/Linuxbrew/brew.git \
        $HOMEBREW
    mkdir -p $HOMEBREW/Cache
    mkdir -p $HOME/.cache
    rm -rf $HOME/.cache/Homebrew
    ln -sf $HOMEBREW/Cache $HOME/.cache/Homebrew
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    # TODO
    git clone --depth 1 \
        https://github.com/Homebrew/brew.git \
        $HOMEBREW
fi

(
    unset LD_LIBRARY_PATH
    export PATH=$HOMEBREW/bin:$PATH
    brew analytics off

    # TODO: figure this one out
    brew install perl
    export PERL5LIB=$HOME/perl5
    echo yes | $HOMEBREW/bin/cpan install local::lib
    echo yes | $HOMEBREW/bin/cpan install SVN::Core
    echo yes | $HOMEBREW/bin/cpan install Term::ReadKey

    brew install python
    $HOMEBREW/bin/python2 -s $HOMEBREW/bin/pip2 install protobuf xlsxwriter

    brew install neovim

    brew install bash-completion

    brew install tmux

    brew install subversion --with-perl
    brew install git
    brew install bash-git-prompt

    brew install wget

    brew install cmake
    brew install gcc
    brew install clang
    brew install gdb

    brew install coreutils
    brew install ctags
    brew install dash
)

# vim: et ts=4 sw=4

