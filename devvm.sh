#!/bin/bash

apt install \
    cmake \
    git \
    gcc \
    g++ \
    doxygen \
    graphviz \
    tmux \
    neovim \
    gpg

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat > /etc/apt/sources.list.d/llvm.list <<EOF
# i386 not available
deb http://apt.llvm.org/disco/ llvm-toolchain-disco main
deb-src http://apt.llvm.org/disco/ llvm-toolchain-disco main
# 7
deb http://apt.llvm.org/disco/ llvm-toolchain-disco-7 main
deb-src http://apt.llvm.org/disco/ llvm-toolchain-disco-7 main
# 8
deb http://apt.llvm.org/disco/ llvm-toolchain-disco-8 main
deb-src http://apt.llvm.org/disco/ llvm-toolchain-disco-8 main
# 9
deb http://apt.llvm.org/disco/ llvm-toolchain-disco-9 main
deb-src http://apt.llvm.org/disco/ llvm-toolchain-disco-9 main
EOF
apt-get update
apt-get install -y clang-8 clangd-8 clang-format-8
apt-get install -y clang-9 clangd-9 clang-format-9



