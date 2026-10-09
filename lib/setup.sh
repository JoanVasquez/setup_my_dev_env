#!/usr/bin/env bash
# Arguments: destination variable name, question, default, allowed choices.
# printf -v assigns the answer by variable name without evaluating user input.
prompt_choice() {
    local variable="$1" label="$2" default="$3" answer
    shift 3
    while true; do
        read -r -p "$label ($*) [$default]: " answer || die 'Input closed'
        answer="${answer:-$default}"
        if [[ " $* " == *" $answer "* ]]; then printf -v "$variable" '%s' "$answer"; return; fi
        printf 'Choose one of: %s\n' "$*"
    done
}
# Arguments: destination variable name and question. Empty input means no;
# retry unexpected answers and stop cleanly if stdin closes.
prompt_boolean() {
    local variable="$1" label="$2" answer
    while true; do
        read -r -p "$label [y/N]: " answer || die 'Input closed'
        case "$answer" in y|Y|yes) printf -v "$variable" 1; return ;; ''|n|N|no) printf -v "$variable" 0; return ;; esac
    done
}
# Collect preferences only. No packages or configs are changed during these prompts.
setup_wizard() {
    printf 'Detected distro: %s (%s) | shell: %s | terminal: %s\n' "$(os_field ID)" "$family" "$(detect_shell)" "$(detect_terminal)"
    # Unattended and preview modes use CLI choices/defaults without reading stdin.
    if ((yes || dry)); then return; fi
    [[ -t 0 ]] || die 'Interactive setup needs a terminal; use --yes with explicit selections.'
    if (( !shell_explicit )); then
        prompt_choice shell_choice 'Shell' "$(detect_shell)" bash fish zsh none
    fi
    if (( !terminal_explicit )); then
        prompt_choice terminal_choice 'Terminal' "$(detect_terminal)" kitty konsole alacritty ghostty none
    fi
    # Resolve auto before filtering questions: the effective shell owns its dependencies.
    [[ "$shell_choice" != auto ]] || shell_choice="$(detect_shell)"
    if (( !tools_explicit )); then
        local tool pick label
        local -a wizard_tools=(nvim tmux docker java codex aws)
        for tool in "${tools_available[@]}"; do append_unique wizard_tools "$tool"; done
        tools=""
        refresh_wizard_dependencies
        printf 'Required by the selected shell (automatic): %s\n' "${automatic_components[*]:-none}"
        printf 'Choose optional tools. Their dependencies are automatic; installed tools are skipped.\n'
        # Offer each logical tool individually; labels explain installed-tool skips.
        # Selecting an installed tool can still enable its bundled config.
        for tool in "${wizard_tools[@]}"; do
            case "$tool" in tpm|zsh-plugins) continue ;; esac
            [[ " ${resolved_components[*]} " != *" $tool "* ]] || continue
            label="$tool"
            case "$tool" in
                nvim) label='Neovim' ;;
                nvm) label='nvm + Node.js LTS' ;;
                docker) label='Docker + Compose' ;;
                java) label='Java JDK' ;;
                codex) label='Codex CLI' ;;
                aws) label='AWS CLI' ;;
                zsh-plugins) label='Zsh autosuggestions/history/vi-mode/highlighting plugins' ;;
            esac
            if tool_installed "$tool"; then label="$label (already installed; installation will be skipped)"; fi
            pick=0
            prompt_boolean pick "Install/configure $label?"
            if ((pick)); then
                tools="${tools:+$tools,}$tool"
                refresh_wizard_dependencies
            fi
        done
        tools="${tools:-none}"
    fi
    if (( !no_packages )); then
        local install_choice=0
        prompt_boolean install_choice 'Install the selected tools and their required dependencies?'
        ((install_choice)) || no_packages=1
    fi
    if contains "$tools" docker && (( !no_packages )); then
        if ((!enable_docker)); then prompt_boolean enable_docker 'Enable and start Docker?'; fi
        if ((!docker_group)); then prompt_boolean docker_group 'Join the Docker group (grants root-level access)?'; fi
    fi
}
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
    validate_list "$shell_choice" bash fish zsh none
    validate_list "$terminal_choice" kitty konsole alacritty ghostty none
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
# Changing a shell startup file does not change the account's login shell.
# Setup activates its selected shell after installation/linking. Only shell paths
# registered by the system are accepted; --keep-shell disables this step.
change_login_shell() {
    ((login_shell)) || return 0
    if ((dry)); then printf 'Change login shell to %s using chsh\n' "$shell_choice"; return; fi
    local path current registry="${SHELLS_FILE:-/etc/shells}"
    path="$(command -v "$shell_choice")" || die "Shell missing: $shell_choice"
    [[ "$path" == /* ]] || die 'Expected an absolute shell executable path'
    [[ -r "$registry" ]] || die "Cannot read the registered shell list: $registry"
    if ! grep -Fxq "$path" "$registry"; then
        # Some systems list /bin while PATH resolves /usr/bin (or vice versa).
        local listed
        while read -r listed; do
            if [[ "$listed" == /* && "$listed" -ef "$path" ]]; then path="$listed"; break; fi
        done < "$registry"
    fi
    grep -Fxq "$path" "$registry" || die "$path is not registered in $registry"
    current="$(account_shell)"
    # /bin and /usr/bin may name the same executable. Compare files as well as strings.
    if [[ "$current" == "$path" || ( -n "$current" && "$current" -ef "$path" ) ]]; then
        printf 'skip: %s is already your default login shell\n' "$shell_choice"
        return
    fi
    # Use the invoking user explicitly; sudo must not accidentally change root's shell.
    privileged chsh -s "$path" "$(id -un)"
    printf 'Default login shell set to %s. Log out and back in to use it.\n' "$shell_choice"
}
# Order matters: collect choices -> validate/probe -> show/confirm -> install -> link.
# Tools are installed before their configs are activated, then chsh runs last.
perform_setup() {
    setup_wizard
    resolve_setup
    show_plan
    if ! confirm; then printf 'Cancelled\n'; return; fi
    if ((!dry)); then
        work_dir="$(mktemp -d)"
        # Clean only this run's temporary downloads, including when a later step fails.
        trap 'rm -rf -- "$work_dir"' EXIT
    fi
    if ((!no_packages)); then install_packages; install_vendors; fi
    local name
    for name in "${chosen[@]}"; do install_one "$name"; done
    install_system_zshenv
    change_login_shell
    printf '\nSetup complete%s. Open a new shell to load the configuration.\n' "$([[ "$dry" == 1 ]] && printf ' (preview only)' || true)"
}
