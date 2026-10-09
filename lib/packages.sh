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
    local component mapped_package
    for component in "${missing_components[@]}"; do
        case "$component" in
            nvim)
                # Try the distro package for a missing editor; an older existing
                # binary is preserved and gets a compatible user runtime instead.
                command_exists nvim || add_package "$(package_for nvim)"
                add_download_requirements; add_command_package tar tar; add_command_package gzip gzip ;;
            starship)
                if [[ "$family" == arch ]]; then add_package starship
                else add_download_requirements; add_command_package tar tar; add_command_package gzip gzip; fi ;;
            # Arch packages the engine and Compose separately. Preserve an existing engine.
            # Fedora uses its native Moby stack; Debian Docker is handled by its dedicated installer/repository logic.
            docker)
                if [[ "$family" == arch ]]; then
                    if ! docker_present; then add_package docker,docker-buildx; fi
                    if ! compose_present; then add_package docker-compose; fi
                elif [[ "$family" == fedora ]]; then
                    if ! docker_present; then add_package moby-engine,docker-cli,docker-buildx; fi
                    if ! compose_present; then add_package docker-compose; fi
                elif ! docker_present; then add_download_requirements
                fi ;;
            tree-sitter)
                if [[ "$family" == arch || "$family" == fedora ]]; then add_package tree-sitter-cli
                else add_download_requirements; add_command_package gzip gzip; fi ;;
            aws)
                add_download_requirements
                if [[ "$family" == fedora ]]; then add_package unzip,gnupg2,groff,less
                else add_package unzip,gnupg,groff,less; fi ;;
            lf)
                if [[ "$family" == fedora ]]; then
                    add_download_requirements; add_command_package tar tar; add_command_package gzip gzip
                else add_package "$(package_for lf)"; fi ;;
            nvm) add_download_requirements; add_command_package tar tar; add_command_package gzip gzip ;;
            codex|tpm|zsh-plugins|none) : ;;
            clipboard)
                command_exists xclip || add_package xclip
                command_exists wl-copy || add_package wl-clipboard ;;
            *)
                mapped_package="$(package_for "$component")" || return 1
                add_package "$mapped_package" ;;
        esac
    done
}
# Apply only the missing distro packages. An empty plan avoids sudo and metadata refreshes.
install_packages() {
    [[ "$family" != unsupported ]] || die 'Only Debian, Arch and Fedora families support package installation. Use setup --no-packages for configs.'
    if ((${#pkgs[@]} == 0)); then printf 'No missing distro packages to install.\n'; return; fi
    if [[ "$family" == arch ]]; then
        # Do not refresh repository databases or force a global upgrade here.
        # --needed also asks pacman to skip packages already at the requested version.
        privileged pacman -S --needed --noconfirm -- "${pkgs[@]}"
    elif [[ "$family" == fedora ]]; then
        if ((!dry)) && ! command_exists dnf; then
            die 'Fedora package installation requires dnf. Use setup --no-packages for configs.'
        fi
        # DNF4 and DNF5 share this syntax. Missing package names abort the
        # transaction; never use --skip-unavailable or --allowerasing.
        privileged dnf --refresh install -y -- "${pkgs[@]}"
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
    # Service/group choices still apply when Docker itself was skipped.
    if [[ " ${package_components[*]} " == *' docker '* ]]; then configure_docker; fi
}
