#! /bin/bash

# latest golang
VERSION=`curl -s -L https://golang.org/VERSION?m=text | head -n1`
sudo rm -rf /usr/local/go || true

ARCHIVE_NAME="${VERSION}.linux-amd64.tar.gz"
wget "https://go.dev/dl/${ARCHIVE_NAME}"
sudo tar -C /usr/local -xzf "${ARCHIVE_NAME}"
rm "${ARCHIVE_NAME}"

# latest rust (beta)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain beta --profile default
source "$HOME/.cargo/env"

# latest clang
curl -s -L https://apt.llvm.org/llvm.sh | sudo sh
