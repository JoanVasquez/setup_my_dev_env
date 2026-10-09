#!/usr/bin/env bash
# Package mappings live in packages/components.tsv; vendor installs are separate.
# Argument: logical component. Read its Debian/Arch package names from the manifest.
# A cell can contain several comma-separated packages (for example clipboard tools).
package_for() {
    local component="$1" key deb arch
    while read -r key deb arch; do
        [[ "$key" == "$component" ]] || continue
        if [[ "$family" == arch ]]; then printf '%s\n' "$arch"; else printf '%s\n' "$deb"; fi
        return
    done < "$ROOT/packages/components.tsv"
    die "Missing package mapping: $component"
}
# Expand a CSV package cell into pkgs, excluding duplicates and locally installed packages.
add_package() {
    local package
    local -a additions
    IFS=, read -r -a additions <<< "$1"
    for package in "${additions[@]}"; do
        if [[ " ${pkgs[*]} " != *" $package "* ]] && ! package_installed "$package"; then pkgs+=("$package"); fi
    done
}
# Download prerequisites belong only to installers that actually fetch upstream
# artifacts. Java and other repository-only tools need no curl/Git/Node bootstrap.
add_command_package() {
    command_exists "$2" || add_package "$1"
    return 0
}
add_download_requirements() {
    add_package ca-certificates
    add_command_package curl curl
}
# Input: missing_components from detection. Output: pkgs for the distro package manager.
# Vendor-managed tools are handled later, but their prerequisites are added here.
build_packages() {
    pkgs=()
    # If every selected tool is present, do not install even general prerequisites.
    ((${#missing_components[@]})) || return 0
    local component
    for component in "${missing_components[@]}"; do
        case "$component" in
            starship)
                if [[ "$family" == arch ]]; then add_package starship
                else add_download_requirements; add_command_package tar tar; fi ;;
            # Arch packages the engine and Compose separately. Preserve an existing engine.
            # Debian Docker is handled by its dedicated installer/repository logic.
            docker)
                if [[ "$family" == arch ]]; then
                    if ! docker_present; then add_package docker,docker-buildx; fi
                    if ! compose_present; then add_package docker-compose; fi
                elif ! docker_present; then add_download_requirements
                fi ;;
            tree-sitter)
                if [[ "$family" == arch ]]; then add_package tree-sitter-cli
                else add_download_requirements; add_command_package gzip gzip; fi ;;
            aws) add_download_requirements; add_package unzip,gnupg,groff,less ;;
            nvm) add_download_requirements; add_command_package tar tar ;;
            codex|tpm|zsh-plugins|none) : ;;
            clipboard)
                command_exists xclip || add_package xclip
                command_exists wl-copy || add_package wl-clipboard ;;
            *) add_package "$(package_for "$component")" ;;
        esac
    done
}
# Apply only the missing distro packages. An empty plan avoids sudo and metadata refreshes.
install_packages() {
    [[ "$family" != unsupported ]] || die 'Only Debian and Arch families support package installation. Use setup --no-packages for configs.'
    if ((${#pkgs[@]} == 0)); then printf 'No missing distro packages to install.\n'; return; fi
    if [[ "$family" == arch ]]; then
        # Do not refresh repository databases or force a global upgrade here.
        # --needed also asks pacman to skip packages already at the requested version.
        privileged pacman -S --needed --noconfirm -- "${pkgs[@]}"
    else
        privileged apt-get update
        # Check candidate availability after refreshing APT, before requesting installation.
        # Preview mode never queries refreshed metadata or mutates the machine.
        if ((!dry)); then
            local package candidate
            for package in "${pkgs[@]}"; do
                candidate="$(apt-cache policy "$package" | awk '/Candidate:/ {print $2; exit}')"
                [[ -n "$candidate" && "$candidate" != '(none)' ]] || die "No APT candidate for $package. Choose another terminal/tool or enable a suitable repository."
            done
        fi
        # --no-upgrade preserves already-installed packages named in this request.
        privileged apt-get install -y --no-upgrade -- "${pkgs[@]}"
    fi
}
# Run upstream installers only for missing tools, after distro prerequisites are ready.
install_vendors() {
    local component
    for component in "${missing_components[@]}"; do
        case "$component" in
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
    # Service/group choices still apply when Docker itself was skipped.
    if [[ " ${package_components[*]} " == *' docker '* ]]; then configure_docker; fi
}
