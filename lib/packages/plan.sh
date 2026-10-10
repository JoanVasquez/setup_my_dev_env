#!/usr/bin/env bash
# Package mappings live in packages/components.tsv; vendor installs are separate.
# Argument: logical component. Read its distro package names from the manifest.
# A cell can contain several comma-separated packages (for example clipboard tools).
package_for() {
    local component="$1" key deb arch fedora package
    while read -r key deb arch fedora; do
        [[ "$key" == "$component" ]] || continue
        case "$family" in
            debian) package="$deb" ;;
            arch) package="$arch" ;;
            fedora) package="$fedora" ;;
            *) die "Unsupported package family: $family" ;;
        esac
        [[ -n "$package" && "$package" != - ]] || die "No $family package mapping for $component"
        printf '%s\n' "$package"
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
        if [[ " ${pkgs[*]} " != *" $package "* ]] && { [[ "${2:-0}" == 1 ]] || ! package_installed "$package"; }; then
            pkgs+=("$package")
            if [[ "${2:-0}" == 1 ]] && package_installed "$package"; then
                append_unique repair_pkgs "$package"
            fi
        fi
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
    repair_pkgs=()
    # If every selected tool is present, do not install even general prerequisites.
    ((${#missing_components[@]})) || return 0
    local component mapped_package
    for component in "${missing_components[@]}"; do
        case "$component" in
            nvim)
                # Try the distro package for a missing editor; an older existing
                # binary is preserved and gets a compatible user runtime instead.
                command_exists nvim || add_package "$(package_for nvim)"
                add_download_requirements; add_command_package tar tar; add_command_package gzip gzip ;;
            starship)
                if [[ "$family" == arch ]]; then add_package starship 1
                else add_download_requirements; add_command_package tar tar; add_command_package gzip gzip; fi ;;
            # Arch packages the engine and Compose separately. Preserve an existing engine.
            # Fedora uses its native Moby stack; Debian Docker is handled by its dedicated installer/repository logic.
            docker)
                if [[ "$family" == arch ]]; then
                    if ! docker_present; then add_package docker,docker-buildx 1; fi
                    if ! compose_present; then add_package docker-compose 1; fi
                elif [[ "$family" == fedora ]]; then
                    if ! docker_present; then add_package moby-engine,docker-cli,docker-buildx 1; fi
                    if ! compose_present; then add_package docker-compose 1; fi
                elif ! docker_present; then add_download_requirements
                fi ;;
            tree-sitter)
                if [[ "$family" == arch || "$family" == fedora ]]; then add_package tree-sitter-cli 1
                else add_download_requirements; add_command_package gzip gzip; fi ;;
            aws)
                add_download_requirements
                if [[ "$family" == fedora ]]; then add_package unzip,gnupg2,groff,less
                else add_package unzip,gnupg,groff,less; fi ;;
            lf)
                if [[ "$family" == fedora ]]; then
                    add_download_requirements; add_command_package tar tar; add_command_package gzip gzip
                else add_package "$(package_for lf)" 1; fi ;;
            nvm) add_download_requirements; add_command_package tar tar; add_command_package gzip gzip ;;
            codex|tpm|zsh-plugins|none) : ;;
            clipboard)
                command_exists xclip || add_package xclip
                command_exists wl-copy || add_package wl-clipboard ;;
            *)
                mapped_package="$(package_for "$component")" || return 1
                add_package "$mapped_package" 1 ;;
        esac
    done
}
