#!/usr/bin/env bash
# Selection priority: explicit --components, then --all, then detected installed apps.
# Used by install/unlink; setup builds its own chosen array from the wizard.
wanted() {
    local name="$1"
    if [[ -n "$selected" ]]; then
        [[ ",$selected," == *",$name,"* ]]
        return
    fi
    if ((all)); then return 0; fi
    case "$name" in
    ssh-agent) return 1 ;; # Explicit selection or --all; requires socket-aware OpenSSH.
    bash | zsh | fish) [[ "$(detect_shell)" == "$name" ]] || command -v "$name" >/dev/null ;;
    *) command -v "$name" >/dev/null 2>&1 ;;
    esac
}

# Validate explicit names before collecting config components into chosen.
select_components() {
    local name
    chosen=()
    if [[ -n "$selected" ]]; then validate_list "$selected" "${components[@]}"; fi
    for name in "${components[@]}"; do
        if wanted "$name"; then chosen+=("$name"); fi
    done
}
# cmd is install or unlink; select the corresponding helper for every chosen config.
link_components() {
    local name
    for name in "${chosen[@]}"; do "${cmd}_one" "$name"; done
}

