#!/usr/bin/env bash
# A built-in menu works before optional tools such as fzf are installed.
# Read single keys without changing persistent terminal settings. All rendering
# goes to stderr; printf -v returns the logical value to the caller.
prompt_choice() {
    local variable="$1" label="$2" default="$3"
    shift 3
    local -a menu_options=("$@")
    local menu_index=0 menu_row menu_key menu_sequence menu_drawn=0
    for menu_row in "${!menu_options[@]}"; do
        [[ "${menu_options[menu_row]}" != "$default" ]] || menu_index="$menu_row"
    done
    while true; do
        if ((menu_drawn)); then printf '\033[%dA' "$((${#menu_options[@]} + 2))" >&2; fi
        printf '\r\033[2K%s\n' "$label" >&2
        for menu_row in "${!menu_options[@]}"; do
            if ((menu_row == menu_index)); then
                printf '\r\033[2K > %d) %s\n' "$((menu_row + 1))" "${menu_options[menu_row]}" >&2
            else
                printf '\r\033[2K   %d) %s\n' "$((menu_row + 1))" "${menu_options[menu_row]}" >&2
            fi
        done
        printf '\r\033[2KUp/Down: move | Enter: select | number: highlight | q: cancel\n' >&2
        menu_drawn=1
        IFS= read -r -s -n 1 menu_key || die 'Input closed'
        case "$menu_key" in
            '') printf -v "$variable" '%s' "${menu_options[menu_index]}"; return ;;
            $'\033')
                menu_sequence=''
                IFS= read -r -s -n 1 -t 0.2 menu_sequence || true
                if [[ "$menu_sequence" == '[' || "$menu_sequence" == O ]]; then
                    IFS= read -r -s -n 1 -t 0.2 menu_sequence || true
                    case "$menu_sequence" in
                        A) menu_index=$(((menu_index + ${#menu_options[@]} - 1) % ${#menu_options[@]})) ;;
                        B) menu_index=$(((menu_index + 1) % ${#menu_options[@]})) ;;
                    esac
                fi ;;
            k) menu_index=$(((menu_index + ${#menu_options[@]} - 1) % ${#menu_options[@]})) ;;
            j) menu_index=$(((menu_index + 1) % ${#menu_options[@]})) ;;
            [1-9])
                if ((menu_key <= ${#menu_options[@]})); then menu_index=$((menu_key - 1)); fi ;;
            y|Y|n|N)
                # Keep familiar shortcuts for the two-option confirmation menus.
                if [[ "${menu_options[*]}" == 'no yes' ]]; then
                    case "$menu_key" in y|Y) menu_index=1 ;; n|N) menu_index=0 ;; esac
                fi ;;
            q|Q) die 'Selection cancelled' ;;
        esac
    done
}
# Every confirmation defaults to no and uses the same selectable menu.
prompt_boolean() {
    local variable="$1" label="$2" menu_answer
    prompt_choice menu_answer "$label" no no yes
    case "$menu_answer" in
        yes) printf -v "$variable" 1 ;;
        no) printf -v "$variable" 0 ;;
    esac
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
