#! /bin/bash

#TODO: make sure only the items in the package list gets updated
#

pipx upgrade-all
cargo install-update -a
npm update -g
