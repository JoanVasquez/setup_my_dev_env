#!/usr/bin/env bash
# The imported tmux config reloads ~/.tmux.conf. Manage that startup link as well
# as the support directory, including when the directory link already exists.
# Link individual Zsh files rather than replacing the entire directory, preserving
# local.zsh and any unrelated user configuration. Runtime plugins/history live elsewhere.
zsh_support_links=(zsh-env zsh-node zsh-fzf zsh-aliases zsh-functions zsh-bindings zsh-plugins zsh-prompt zsh-plugin-list zsh-starship zsh-bootstrap zsh-legacy)
install_one() {
    local support
    if [[ "$1" == fish ]]; then install_fish_config; return; fi
    install_link "$1"
    if [[ "$1" == ssh-agent ]]; then install_link ssh-agent-service; fi
    if [[ "$1" == zsh ]]; then
        for support in "${zsh_support_links[@]}"; do install_link "$support"; done
        if ((!dry)); then mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"; fi
    fi
    if [[ "$1" == tmux ]]; then install_link tmux-startup; fi
}
unlink_one() {
    local support
    if [[ "$1" == fish ]]; then unlink_fish_config; return; fi
    unlink_link "$1"
    if [[ "$1" == ssh-agent ]]; then unlink_link ssh-agent-service; fi
    if [[ "$1" == zsh ]]; then
        for support in "${zsh_support_links[@]}"; do unlink_link "$support"; done
    fi
    if [[ "$1" == tmux ]]; then unlink_link tmux-startup; fi
}

