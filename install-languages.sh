#! /bin/bash

# Check for Go installation and install if not found
echo "Checking for Go installation..."
if ! command -v go &> /dev/null; then
    echo "Go not found. Installing Go..."
    VERSION=$(curl -s -L https://golang.org/VERSION?m=text | head -n1)
    sudo rm -rf /usr/local/go || true

    ARCHIVE_NAME="${VERSION}.linux-amd64.tar.gz"
    wget "https://go.dev/dl/${ARCHIVE_NAME}"
    sudo tar -C /usr/local -xzf "${ARCHIVE_NAME}"
    rm "${ARCHIVE_NAME}"
    echo "Go installation completed."
else
    echo "Go is already installed. Skipping installation."
fi

# Check for Rust installation and install if not found
echo "Checking for Rust installation..."
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain beta --profile default
    source "$HOME/.cargo/env"
    echo "Rust installation completed."
else
    echo "Rust is already installed. Skipping installation."
fi

# Check for Clang installation and install if not found
echo "Checking for Clang installation..."
if ! command -v clang &> /dev/null; then
    echo "Clang not found. Installing Clang..."
    curl -s -L https://apt.llvm.org/llvm.sh | sudo sh
    echo "Clang installation completed."
else
    echo "Clang is already installed. Skipping installation."
fi

