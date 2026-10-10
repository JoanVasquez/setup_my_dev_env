#!/usr/bin/env bash
# Apply only the missing distro packages. An empty plan avoids sudo and metadata refreshes.
install_packages() {
    [[ "$family" != unsupported ]] || die 'Only Debian, Arch and Fedora families support package installation. Use setup --no-packages for configs.'
    if ((${#pkgs[@]} == 0)); then printf 'No missing distro packages to install.\n'; return; fi
    if [[ "$family" == arch ]]; then
        # Do not refresh repository databases or force a global upgrade here.
        # Failed runtime probes must permit reinstallation of the same package version.
        local -a pacman_options=(--needed)
        ((${#repair_pkgs[@]} == 0)) || pacman_options=()
        privileged pacman -S "${pacman_options[@]}" --noconfirm -- "${pkgs[@]}"
    elif [[ "$family" == fedora ]]; then
        if ((!dry)) && ! command_exists dnf; then
            die 'Fedora package installation requires dnf. Use setup --no-packages for configs.'
        fi
        # DNF4 and DNF5 share this syntax. Missing package names abort the
        # transaction; never use --skip-unavailable or --allowerasing.
        privileged dnf --refresh install -y -- "${pkgs[@]}"
        if ((${#repair_pkgs[@]})); then privileged dnf reinstall -y -- "${repair_pkgs[@]}"; fi
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
        # Reinstall requested packages when the runtime probe failed.
        privileged apt-get install -y --reinstall -- "${pkgs[@]}"
    fi
}
