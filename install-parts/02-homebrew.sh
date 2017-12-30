#!/bin/bash

[[ "$SKIP_BREW" == 1 ]] && return

if [[ "$(uname -s)" == Linux ]]; then
    git_ok=0
    type -p git &> /dev/null && git_ok=1
    [[ -n "$FORCE_BOOTSTRAP_GIT" ]] && git_ok=0

    if [[ $git_ok == 0 ]]; then
        # Bootstrap git
        (
            mkdir -p $BOOTSTRAP_ROOT/git
            cd $BOOTSTRAP_ROOT/git
            wget --no-check-certificate https://www.kernel.org/pub/software/scm/git/git-2.11.0.tar.gz
            tar xzf git-2.11.0.tar.gz
            cd git-2.11.0
            patch < $DOTFILES_ROOT/patches/git-patch-no-perl
            autoreconf
            ./configure --prefix=$BOOTSTRAP_ROOT/git/install --without-perl
            make -j && make install
        )
        export PATH=$BOOTSTRAP_ROOT/git/install/bin:$PATH
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
            mkdir -p $BOOTSTRAP_ROOT/ruby
            cd $BOOTSTRAP_ROOT/ruby
            wget --no-check-certificate https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.6.tar.gz
            tar xzf ruby-2.2.6.tar.gz
            cd ruby-2.2.6
            ./configure --prefix=$BOOTSTRAP_ROOT/ruby/install
            make -j && make install
        )
        export PATH=$BOOTSTRAP_ROOT/ruby/install/bin:$PATH
    fi 2>&1 | tee $LOGS/0bootstrap.ruby

fi

if [[ "$(uname -s)" == Darwin ]]; then
fi

unset APPS APPS_LOCAL
export LANG=C
unset LC_COLLATE
export HOMEBREW_ARCH=core2
mkdir -p $HOMEBREW_ROOT
ln -sf $HOMEBREW_ROOT $HOME/.linuxbrew || true
git clone --depth 1 https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew 2>&1 | tee $LOGS/1brew.0clone
mkdir -p $HOMEBREW_ROOT/Cache
mkdir -p $HOME/.cache
ln -sf $HOMEBREW_ROOT/Cache $HOME/.cache/Homebrew || true
export PATH=$HOME/.linuxbrew/bin:$PATH
unset LD_LIBRARY_PATH
brew analytics off
while IFS='' read -r package || [[ -n "$package" ]]; do
    package_name=$(echo $package | awk '{print $1}' | sed 's/\//_/g')
    set -e
    brew install $package 2>&1 | tee $LOGS/1brew.1install.$package_name
    echo "Installed $package: rc = $?" >> $LOGS/1brew.1install.$package_name
done < brew.txt

# vim: et ts=4 sw=4

