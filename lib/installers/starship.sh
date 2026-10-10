#!/usr/bin/env bash
# Arch installs Starship through pacman; Debian/Fedora use the upstream script
# only when no executable is present. A writable user bin directory avoids sudo.
install_starship() {
    if [[ "$family" == arch ]] || tool_installed starship; then return; fi
    printf 'Install Starship into ~/.local/bin using its upstream installer\n'
    if ((dry)); then return; fi
    mkdir -p "$HOME/.local/bin"
    fetch_script https://starship.rs/install.sh "$work_dir/starship-install.sh"
    sh "$work_dir/starship-install.sh" --yes --bin-dir "$HOME/.local/bin"
}
