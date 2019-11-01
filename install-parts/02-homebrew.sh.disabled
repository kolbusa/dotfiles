#!/bin/bash

set -e

[[ "$SKIP_BREW" == 1 ]] && return

export HOMEBREW_TEMP=$DOTFILES/tmp
mkdir -p $HOMEBREW_TEMP

BOOTSTRAP=$DOTFILES/bootstrap
rm -rf $BOOTSTRAP

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
        export GIT_COMMAND=$BOOTSTRAP/git/install/bin/git
        git --version
    fi

    ruby_ok=0
    if type -p ruby &> /dev/null && \
        ruby -e \
            'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.3.0"))' &> /dev/null
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
            wget --no-check-certificate https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz
            tar xzf ruby-2.5.0.tar.gz
            cd ruby-2.5.0
            wget --no-check-certificate https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz
            ./configure --prefix=$BOOTSTRAP/ruby/install
            make -j && make install
        )
        export PATH=$BOOTSTRAP/ruby/install/bin:$PATH
        export HOMEBREW_RUBY_PATH=$BOOTSTRAP/ruby/install/bin/ruby
    fi
fi

if [[ "$(uname -s)" == Darwin ]]; then
    true
fi

###############################################################################

if [[ "$(uname -s)" == "Linux" ]]; then
    HOMEBREW_DIRNAME=.linuxbrew
else
    HOMEBREW_DIRNAME=.homebrew
fi

HOMEBREW=$HOME/$HOMEBREW_DIRNAME
if [[ -n "$OVERLAY" ]]; then
    HOMEBREW_OVERLAY=$OVERLAY/$HOMEBREW_DIRNAME
    rm -rf $HOMEBREW_OVERLAY $HOMEBREW
    mkdir -p $HOMEBREW_OVERLAY
    ln -sf $HOMEBREW_OVERLAY $HOMEBREW
else
    rm -rf $HOMEBREW
    mkdir -p $HOMEBREW
fi

###############################################################################

if [[ "$(uname -s)" == "Linux" ]]; then
    unset APPS APPS_LOCAL
    export LANG=C
    unset LC_COLLATE
    export HOMEBREW_ARCH=core2
    export HOMEBREW_NO_ENV_FILTERING=1
    export HOMEBREW_DEVELOPER=1
    git clone --depth 1 \
        https://github.com/Linuxbrew/brew.git \
        $HOMEBREW

    #### Taken care of in 01-overlay.sh
    # mkdir -p $HOMEBREW/Cache
    # mkdir -p $HOME/.cache
    # rm -rf $HOME/.cache/Homebrew
    # ln -sf $HOMEBREW/Cache $HOME/.cache/Homebrew

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
    export LD_LIBRARY_PATH
    set
    export HOMEBREW_NO_AUTO_UPDATE=1
    brew analytics off
    if [[ -n "$OLD_SYSTEM" ]]; then
        # XXX: this is very hacky
        brew install binutils
        # XXX: patch gcc formula to use Homebrew ld (system ld may be broken)
        sed -i -e '/MAKEINFO=/a"LD=#{HOMEBREW_PREFIX}/bin/ld",' \
            $HOMEBREW/Library/Taps/homebrew/homebrew-core/Formula/gcc@4.9.rb
        HOMEBREW_BUILD_FROM_SOURCE=1 brew install gcc@4.9
        gcc_keg_path="$(brew info gcc@4.9 | grep Cellar | cut -f1 -d' ')"
        gcc_keg_ver=$(basename $gcc_keg_path)
        if [[ ! -f $gcc_keg_path/lib/gcc/x86_64-unknown-linux-gnu/$gcc_keg_ver/specs.orig ]]; then
            (
                cd $gcc_keg_path/lib/gcc/x86_64-unknown-linux-gnu/
                d=$(ls -d 4.9*)
                ln -sf $d $gcc_keg_ver
            )
        fi
        brew install glibc
        brew remove gcc@4.9
        brew install gcc

        # XXX: work around old curl
        sed -i -e 's/https:/http:/' \
            $HOMEBREW/Library/Taps/homebrew/homebrew-core/Formula/perl.rb
        brew install perl
        brew install curl
        sed -i -e '/system "\.\/configure",/a"--with-included-libxml",' \
            $HOMEBREW/Library/Taps/homebrew/homebrew-core/Formula/gettext.rb
        HOMEBREW_BUILD_FROM_SOURCE=1 brew install gettext
        brew install pcre --without-check
    else
        brew install gcc
        brew install perl
        brew install curl
    fi

    brew install wget
    # TODO: figure this one out
    export PERL5LIB=$HOME/perl5
    export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    echo yes | $HOMEBREW/bin/cpan install local::lib
    echo yes | $HOMEBREW/bin/cpan install Term::ReadKey

    brew install python
    $HOMEBREW/bin/python2 -s $HOMEBREW/bin/pip2 install protobuf xlsxwriter pycodestyle neovim
    brew install python3
    $HOMEBREW/bin/python3 -s $HOMEBREW/bin/pip3 install neovim

    brew install mawk
    grep -qs "mawk" \
        $HOMEBREW/Library/Taps/homebrew/homebrew-core/Formula/apr-util.rb ||
        sed -i -e '/depends_on "apr"/adepends_on "mawk"' \
            $HOMEBREW/Library/Taps/homebrew/homebrew-core/Formula/apr-util.rb
    brew install neovim

    brew install bash-completion

    brew install tmux

    brew install subversion --with-perl
    echo yes | $HOMEBREW/bin/cpan install SVN::Core
    brew install git

    brew install cmake
    brew install llvm
    brew install gdb

    brew install coreutils
    brew install ctags
    brew install dash
)

# vim: et ts=4 sw=4

