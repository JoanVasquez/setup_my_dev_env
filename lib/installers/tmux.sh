#!/usr/bin/env bash
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
        install_plugin "$repository" "$destination" "$entry"
    done < "$ROOT/packages/tmux-plugins.tsv"
}

