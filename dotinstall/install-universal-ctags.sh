#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect the Linux distribution
if command_exists pacman; then
    # Arch Linux
    package_manager="pacman"
elif command_exists apt; then
    # Ubuntu
    package_manager="apt"
elif command_exists dnf; then
    # Oracle
    package_manager="dnf"
else
    echo "Unsupported Linux distribution. Please install Universal-ctags manually."
    exit 1
fi

# Clone the Universal-ctags repository
git clone --depth=1 https://github.com/universal-ctags/ctags.git

# Change to the ctags directory
cd ctags

# Install the necessary dependencies
if [ "$package_manager" = "pacman" ]; then
    sudo pacman -Syu --needed --noconfirm autoconf pkg-config jansson seccomp
elif [ "$package_manager" = "apt" ]; then
    sudo apt update
    sudo apt install -y autoconf pkg-config libjansson-dev libseccomp-dev
elif [ "$package_manager" = "dnf" ]; then
  sudo dnf update -y
  sudo dnf install -y automake libXmu libXmu-devel
fi

# Configure, build, and install Universal-ctags
./autogen.sh
./configure
make
sudo make install

# Clean up the temporary files
cd ..
rm -rf ctags

# Print a success message
echo "Universal-ctags installation completed."
