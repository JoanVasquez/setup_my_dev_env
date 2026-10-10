#!/usr/bin/env bash
dispatch_command() {
    # Dispatch only after parsing. setup installs and links; packages only installs.
    case "$cmd" in
        doctor) doctor ;;
        aliases) list_configured_aliases "$([[ "$shell_explicit" == 1 ]] && printf '%s' "$shell_choice" || printf all)" ;;
        install|unlink)
            select_components
            printf '%s: %s\n' "$cmd" "${chosen[*]:-none}"
            if confirm; then link_components; else printf 'Cancelled\n'; fi ;;
        setup) perform_setup ;;
        packages) perform_packages ;;
    esac
}
