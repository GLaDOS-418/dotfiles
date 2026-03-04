# dotfiles

## Starter (bootstrap)

Run this from a fresh machine (WSL Ubuntu/Oracle/Arch):

```bash
git clone https://github.com/GLaDOS-418/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
./dot_setup.sh --start-over
```

Non-interactive mode:

```bash
./dot_setup.sh --start-over --yes
```

Run bootstrap + post-setup automation in one go:

```bash
./dot_setup.sh --start-over --run-post-setup
./dot_setup.sh --start-over --yes --run-post-setup
```

Notes:
- `sudo` is required.
- `dot_setup.sh` installs base packages, verifies references, installs distro-specific packages, and creates symlinks in `$HOME`.

## Post-setup automation

This actually executes non-interactive plugin setup and language installers:

```bash
bash "$HOME/dotfiles/installers/post-setup.sh"
```

Non-interactive mode:

```bash
bash "$HOME/dotfiles/installers/post-setup.sh" --yes
```

Optional modes:

```bash
# Plugins only
bash "$HOME/dotfiles/installers/post-setup.sh" --plugins-only

# Languages only
bash "$HOME/dotfiles/installers/post-setup.sh" --languages-only

# Limit languages
bash "$HOME/dotfiles/installers/post-setup.sh" --langs rust,go,node
```

Manual equivalents:

```bash
# Neovim plugin install/update
nvim --headless '+PlugInstall --sync' +qa

# Vim plugin install/update
vim -E -s -u "$HOME/vim/vimrc" '+PlugInstall --sync' +qa

# Language installers
source "$HOME/dotfiles/shell-config/languagerc"
install_cpp
install_rust
install_go
install_java
install_node
```

## Manual linking (if you do not want full bootstrap)

Remove any existing conflicting file before running these commands:

```bash
ln -s "$HOME/dotfiles/home-config/bashrc"    "$HOME/.bashrc"
ln -s "$HOME/dotfiles/home-config/inputrc"   "$HOME/.inputrc"
ln -s "$HOME/dotfiles/home-config/tmux.conf" "$HOME/.tmux.conf"
ln -s "$HOME/dotfiles/home-config/rgignore"  "$HOME/.rgignore"

touch "$HOME/.gitconfig"
git config --global include.path "$HOME/dotfiles/shell-config/gitconfig-shared"
```

## Other script-provided commands

These are commands exposed by scripts in this repo (not external tool commands by themselves).

Installer scripts:

```bash
bash "$HOME/dotfiles/installers/install-tools.sh"
bash "$HOME/dotfiles/installers/install-rust-tools.sh"
bash "$HOME/dotfiles/installers/install-go-tools.sh"
bash "$HOME/dotfiles/installers/install-npm-tools.sh"
bash "$HOME/dotfiles/installers/install-python-tools.sh"
bash "$HOME/dotfiles/installers/install-universal-ctags.sh"
bash "$HOME/dotfiles/installers/install-snap.sh"
bash "$HOME/dotfiles/installers/upgrade-all.sh"
```

Maintenance/automation scripts:

```bash
bash "$HOME/dotfiles/bin/update-tools"
python3 "$HOME/dotfiles/automation/save_command.py" <your command and args>
pwsh -File "$HOME/dotfiles/automation/activity.ps1"
```

Shell functions loaded from dotfiles (after `source ~/.bashrc`):

```bash
# General helpers
gpp gpd gpe flame ex ar peek mcd rcopen rclang

# Media/system helpers
split_video update_calibre nerd_font_install plantuml_server linux_cleanup

# Package helper wrappers (expect distro package managers)
spac syay spip ssnap

# Language helpers
source "$HOME/dotfiles/shell-config/languagerc"
install_cpp install_rust install_go install_java install_node
```

Discover all function/alias commands defined by these files:

```bash
awk '/^alias / {print $2}' "$HOME/dotfiles/shell-config/bash_aliases" | cut -d= -f1 | sort -u
awk '/^function [A-Za-z_][A-Za-z0-9_]* *\{/ {print $2} /^[A-Za-z_][A-Za-z0-9_]*\(\) *\{/ {sub(/\(\).*/,"",$1); print $1}' "$HOME/dotfiles/shell-config/bash_functions" | sort -u
awk '/^function [A-Za-z_][A-Za-z0-9_]* *\{/ {print $2} /^[A-Za-z_][A-Za-z0-9_]*\(\) *\{/ {sub(/\(\).*/,"",$1); print $1}' "$HOME/dotfiles/shell-config/languagerc" | sort -u
```

## Directory naming

Current names:
- `home-config`
- `shell-config`
- `installers`
- `automation`
- `bin`

Compatibility symlinks are intentionally kept so old paths still work:
- `dotbase -> home-config`
- `dotrc -> shell-config`
- `dotinstall -> installers`
- `dotscripts -> automation`
- `tools -> bin`

**TODO**: explore [GNU Stow](https://www.gnu.org/software/stow/)
