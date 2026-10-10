#!/usr/bin/env bash
# Convert auto defaults and CSV selections into validated arrays before mutation.
# Outputs: chosen (configs), package_components (tools), and the missing package plan.
resolve_setup() {
    # Installing a standalone tool must not implicitly select the current shell's
    # complete profile. Package-only profiles/terminals require explicit flags.
    if [[ "$cmd" == packages ]]; then
        ((shell_explicit)) || shell_choice=none
        ((terminal_explicit)) || terminal_choice=none
    fi
    [[ "$shell_choice" != auto ]] || shell_choice="$(detect_shell)"
    [[ "$terminal_choice" != auto ]] || terminal_choice="$(detect_terminal)"
    validate_choice "$shell_choice" "${shells_available[@]}" none
    validate_choice "$terminal_choice" "${terminals_available[@]}" none
    if ((system_zshenv)); then [[ "$shell_choice" == zsh ]] || die '--system-zshenv requires --shell zsh'; fi
    if [[ "$tools" == none ]]; then tools=""; else validate_list "$tools" "${tools_available[@]}"; fi
    if ((enable_docker || docker_group)); then
        contains "$tools" docker && ((!no_packages)) || die 'Docker service/group options require docker and package installation.'
    fi
    # A normal setup installs and activates the chosen shell by default.
    # Config-only/package-only runs preserve the account shell unless explicitly requested.
    if ((login_shell < 0)); then
        login_shell=0
        if [[ "$cmd" == setup && "$shell_choice" != none ]] && ((!no_packages)); then login_shell=1; fi
    fi
    if ((login_shell)); then [[ "$shell_choice" != none ]] || die '--login-shell requires a shell selection'; fi
    # Configs and install candidates are separate lists: zoxide has no standalone config,
    # while nvim/tmux/starship have both a package and a repository template.
    chosen=()
    local component
    local -a roots=() optional_components=()
    [[ "$shell_choice" == none ]] || { roots+=("$shell_choice"); append_unique chosen "$shell_choice"; }
    [[ "$terminal_choice" == none ]] || { roots+=("$terminal_choice"); append_unique chosen "$terminal_choice"; }
    if [[ -n "$tools" ]]; then IFS=, read -r -a optional_components <<< "$tools"; fi
    roots+=("${optional_components[@]}")
    if ((login_shell)) && ! command_exists chsh; then
        if ((no_packages)); then die 'Changing the login shell requires chsh; install it first or omit --login-shell.'; fi
        roots+=(chsh)
    fi
    resolve_dependencies "${roots[@]}"
    package_components=("${resolved_components[@]}")
    # A dependency with a bundled config gets that config linked too.
    for component in "${package_components[@]}"; do
        case "$component" in tmux|nvim|starship) append_unique chosen "$component" ;; esac
    done
    # Config-only runs work on other distros; package runs need a supported family.
    # Docker conflict checks run before any package-manager changes.
    if ((!no_packages)); then
        [[ "$family" != unsupported ]] || die 'Unsupported distro: use --no-packages to link configs only.'
        if [[ "$family" == fedora ]] && fedora_atomic; then
            die 'Fedora Atomic/OSTree hosts need image-based package management. Use --no-packages to link configs, or run package installation in a DNF-based container.'
        fi
        plan_installations
        build_packages
        if [[ " ${missing_components[*]} " == *' docker '* ]]; then docker_preflight; fi
    fi
}
# Display the resolved plan so the final confirmation applies to concrete selections.
show_plan() {
    printf '\nPlatform: %s (%s)\nShell: %s | Terminal: %s\n' "$(os_field ID)" "$family" "$shell_choice" "$terminal_choice"
    printf 'Configs: %s\nOptional tools: %s\nAutomatic requirements: %s\n' "${chosen[*]:-none}" "${tools:-none}" "${automatic_components[*]:-none}"
    if ((no_packages)); then printf 'Package installation: skipped\n'; else printf 'Missing tools: %s\nDistro packages: %s\n' "${missing_components[*]:-none}" "${pkgs[*]:-none}"; fi
    printf 'System Zsh XDG bootstrap: %s\n' "$system_zshenv"
    printf 'Change login shell: %s | Enable Docker: %s | Docker group: %s\n' "$login_shell" "$enable_docker" "$docker_group"
}
