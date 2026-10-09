#!/usr/bin/env bash
# Arch already installs Starship through pacman; Debian uses the upstream script
# only when no executable is present. A writable user bin directory avoids sudo.
install_starship() {
    if [[ "$family" == arch ]] || command -v starship >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/starship" ]]; then return; fi
    printf 'Install Starship into ~/.local/bin using its upstream installer\n'
    if ((dry)); then return; fi
    mkdir -p "$HOME/.local/bin"
    fetch_script https://starship.rs/install.sh "$work_dir/starship-install.sh"
    sh "$work_dir/starship-install.sh" --yes --bin-dir "$HOME/.local/bin"
}
# A configured tmux needs the manager plus the persistence plugins it loads.
# Probe and clone each checkout separately, preserving existing plugin versions.
tmux_plugins_ready() {
    local repository entry
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        [[ -x "$HOME/.tmux/plugins/${repository##*/}/$entry" ]] || return 1
    done < "$ROOT/packages/tmux-plugins.tsv"
}
install_tpm() {
    local repository entry destination
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        destination="$HOME/.tmux/plugins/${repository##*/}"
        if [[ -x "$destination/$entry" ]]; then
            printf 'skip: %s already installed\n' "${repository##*/}"
            continue
        fi
        [[ ! -e "$destination" ]] || die "Incomplete tmux plugin directory: $destination; repair or move it before installing."
        if ((!dry)); then mkdir -p "$(dirname "$destination")"; fi
        run git clone --depth 1 "https://github.com/$repository" "$destination"
        if ((!dry)); then [[ -x "$destination/$entry" ]] || die "Missing tmux plugin entrypoint: $destination/$entry"; fi
    done < "$ROOT/packages/tmux-plugins.tsv"
}
