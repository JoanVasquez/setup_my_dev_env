#!/usr/bin/env bash
# Initialize detection and backup paths after arguments have been accepted.
initialize_runtime() {
    # Include per-user installs when checking what is already available.
    export PATH="$HOME/.local/bin:$PATH"
    # Include a managed Node prefix even when invoked from a newly switched shell.
    if node_bin="$(bash "$ROOT/shell/common/node-bin")"; then export PATH="$node_bin:$PATH"; fi
    unset node_bin
    family="$(os_family)"
    # XDG_STATE_HOME overrides the default state directory. Timestamp + PID separates runs.
    backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
}

# Setup and packages share one temporary download lifecycle and install pipeline.
prepare_workspace() {
    (( !dry )) || return 0
    work_dir="$(mktemp -d)"
    trap 'rm -rf -- "$work_dir"' EXIT
}
apply_packages() {
    install_packages
    install_vendors
    verify_installations
}
