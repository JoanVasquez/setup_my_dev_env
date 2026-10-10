#!/usr/bin/env bash
# Order matters: collect choices -> validate/probe -> show/confirm -> install -> link.
# Tools are installed before their configs are activated, then chsh runs last.
perform_setup() {
    setup_wizard
    resolve_setup
    show_plan
    if ! confirm; then printf 'Cancelled\n'; return; fi
    prepare_workspace
    if ((!no_packages)); then apply_packages; fi
    local name
    for name in "${chosen[@]}"; do install_one "$name"; done
    if ((!no_packages)); then bootstrap_neovim; fi
    install_system_zshenv
    change_login_shell
    printf '\nSetup complete%s. Open a new shell to load the configuration.\n' "$([[ "$dry" == 1 ]] && printf ' (preview only)' || true)"
}
