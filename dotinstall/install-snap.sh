#!/usr/bin/env bash

# Ensure snapd is ready
sudo systemctl enable --now snapd.socket
[[ -e /snap ]] || sudo ln -s /var/lib/snapd/snap /snap

# Snap installs
sudo snap install hugo # This builds the extended version. Don't add using 'go install'
sudo snap install docker
