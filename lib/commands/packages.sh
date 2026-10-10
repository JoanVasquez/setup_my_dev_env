#!/usr/bin/env bash
perform_packages() {
    local name
    # Build the same install plan as setup without running its interactive wizard.
    resolve_setup
    if ((extra)); then
        for name in kitty alacritty konsole ghostty clipboard; do
            if tool_installed "$name"; then printf 'skip: %s already installed\n' "$name"
            else add_package "$(package_for "$name")"; fi
        done
    fi
    show_plan
    if confirm; then
        # Downloaded scripts/keys live in a temporary directory removed on process exit.
        prepare_workspace
        apply_packages
    else printf 'Cancelled\n'; fi
}
