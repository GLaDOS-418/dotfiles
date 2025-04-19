#! /bin/bash

python3 -m pip install --user -U pipx
pipx completions
pipx install yt-dlp
pipx install bpytop
pipx install conan
pipx install thefuck
pipx install jupyter --include-deps
