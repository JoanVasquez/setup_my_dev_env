#!/usr/bin/env bash
# Run upstream installers only for missing tools, after distro prerequisites are ready.
install_vendors() {
    local component
    for component in "${missing_components[@]}"; do
        case "$component" in
            nvim) install_neovim_runtime ;;
            lf) install_lf ;;
            tree-sitter) install_tree_sitter ;;
            starship) install_starship ;;
            docker) install_docker ;;
            nvm) install_nvm ;;
            tpm) install_tpm ;;
            aws) install_aws ;;
            zsh-plugins) install_zsh_plugins ;;
        esac
    done
    # Codex must be installed after Node even when listed before nvm.
    if [[ " ${missing_components[*]} " == *' codex '* ]]; then install_codex; fi
    # New Node installations must also be visible to subsequent editor/tool processes.
    local node_bins
    if node_bins="$(bash "$ROOT/shell/common/node-bin")"; then export PATH="$node_bins:$PATH"; fi
    hash -r
    # Service/group choices still apply when Docker itself was skipped.
    if [[ " ${package_components[*]} " == *' docker '* ]]; then configure_docker; fi
}

# Do not declare success based on package-manager exit status alone. Report all
# failures together, including stale user launchers shadowing repaired packages.
verify_installations() {
    ((dry)) && return 0
    hash -r
    local component
    local -a failures=()
    for component in "${package_components[@]}"; do
        if ! tool_installed "$component"; then failures+=("$component"); fi
    done
    if ((${#failures[@]})); then
        die "Runtime verification failed: ${failures[*]}. Check PATH overrides and run ./bin/dotfiles doctor; setup can be rerun after repair."
    fi
    printf 'Verified selected tools and requirements.\n'
}
