#!/usr/bin/env bash
# Collect preferences only. No packages or configs are changed during these prompts.
setup_wizard() {
    printf 'Detected distro: %s (%s) | shell: %s | terminal: %s\n' "$(os_field ID)" "$family" "$(detect_shell)" "$(detect_terminal)"
    # Unattended and preview modes use CLI choices/defaults without reading stdin.
    if ((yes || dry)); then return; fi
    [[ -t 0 ]] || die 'Interactive setup needs a terminal; use --yes with explicit selections.'
    if (( !shell_explicit )); then
        prompt_choice shell_choice 'Step 1 · Shell' "$(detect_shell)" "${shells_available[@]}" none
    fi
    if (( !terminal_explicit )); then
        prompt_choice terminal_choice 'Step 2 · Terminal' "$(detect_terminal)" "${terminals_available[@]}" none
    fi
    # Resolve auto before filtering questions: the effective shell owns its dependencies.
    [[ "$shell_choice" != auto ]] || shell_choice="$(detect_shell)"
    if (( !tools_explicit )); then
        local tool label
        local -a wizard_tools=(nvim tmux docker java codex aws) offered_tools=() menu_labels=()
        for tool in "${tools_available[@]}"; do append_unique wizard_tools "$tool"; done
        tools=""
        refresh_wizard_dependencies
        printf 'Required by the selected shell (automatic): %s\n' "${automatic_components[*]:-none}"
        # Shell requirements and internal plugin bundles cannot be deselected.
        # Resolve optional dependencies after the checklist so its rows stay stable.
        for tool in "${wizard_tools[@]}"; do
            case "$tool" in tpm|zsh-plugins) continue ;; esac
            [[ " ${resolved_components[*]} " != *" $tool "* ]] || continue
            label="$(tool_label "$tool")"
            if tool_installed "$tool"; then label+=" (installed; config can still be applied)"; fi
            offered_tools+=("$tool")
            menu_labels+=("$label")
        done
        prompt_menu tools 'Optional tools — choose everything you want to install/configure' none multiple "${offered_tools[@]}"

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

# Human-readable names belong to the wizard, not the package identifiers.
tool_label() {
    case "$1" in
        nvim) printf 'Neovim editor' ;;
        tmux) printf 'tmux terminal multiplexer' ;;
        nvm) printf 'nvm + Node.js LTS' ;;
        docker) printf 'Docker + Compose' ;;
        java) printf 'Java JDK' ;;
        codex) printf 'Codex CLI' ;;
        aws) printf 'AWS CLI' ;;
        *) printf '%s' "$1" ;;
    esac
}
