#!/usr/bin/env bash
# Resolve Docker's upstream APT distro/release, which can differ from a derivative's ID.
# Explicit DOCKER_DISTRO/DOCKER_CODENAME values take precedence over detected metadata.
docker_platform() {
    docker_distro="${DOCKER_DISTRO:-}"
    docker_codename="${DOCKER_CODENAME:-}"
    if [[ -z "$docker_distro" ]]; then
        if [[ "$(os_field ID)" == ubuntu || -n "$(os_field UBUNTU_CODENAME)" ]]; then
            docker_distro=ubuntu
        elif [[ "$(os_field ID)" == debian ]]; then docker_distro=debian
        else die 'Set DOCKER_DISTRO=debian|ubuntu and DOCKER_CODENAME to the base release for this derivative.'; fi
    fi
    # Ubuntu derivatives often expose their base release through UBUNTU_CODENAME.
    if [[ -z "$docker_codename" ]]; then
        if [[ "$docker_distro" == ubuntu ]]; then docker_codename="$(os_field UBUNTU_CODENAME)"; fi
        docker_codename="${docker_codename:-$(os_field VERSION_CODENAME)}"
    fi
    [[ "$docker_distro" == debian || "$docker_distro" == ubuntu ]] || die 'Invalid DOCKER_DISTRO'
    [[ "$docker_codename" =~ ^[a-z][a-z0-9-]*$ ]] || die 'Cannot determine Docker base release; set DOCKER_CODENAME.'
}
# Before installing Docker, check repository metadata and conflicting providers.
# An existing engine uses the Compose-only path and does not need repository replacement.
docker_preflight() {
    if [[ "$family" == fedora ]]; then
        # podman-docker provides a docker command but is a different engine.
        package_installed podman-docker && die 'Docker conflicts with installed podman-docker. Resolve that provider deliberately or omit docker from --tools.'
        return 0
    fi
    [[ "$family" == debian ]] || return 0
    if docker_present; then return 0; fi
    docker_platform
    docker_repo_available=0
    if ((dry)); then return 0; fi
    # Reuse an existing official source rather than adding a duplicate signed-by entry.
    if apt-cache policy docker-ce 2>/dev/null | grep -F "download.docker.com/linux/$docker_distro" >/dev/null; then
        docker_repo_available=1
    fi
    # Docker's upstream packages conflict with these distro packages; never auto-remove them.
    local package status
    for package in docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc; do
        status="$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)"
        [[ "$status" != 'install ok installed' ]] || die "Docker's repository conflicts with installed $package. Remove it deliberately before rerunning, or omit docker from --tools."
    done
}
# Preserve an existing engine and find a Compose v2 package from configured APT sources.
install_compose_only() {
    printf 'Docker is already installed; install only the missing Compose plugin.\n'
    if ((dry)); then
        printf 'Choose an available Compose v2 package compatible with the installed engine.\n'
        return
    fi
    privileged apt-get update
    local package candidate
    local -a candidates=(docker-compose-plugin docker-compose-v2 docker-compose)
    # The official docker-compose-plugin can depend on Docker CE packages.
    # Restrict choices for a distro docker.io engine to avoid replacing it.
    if package_installed docker.io; then candidates=(docker-compose-v2 docker-compose); fi
    for package in "${candidates[@]}"; do
        candidate="$(apt-cache policy "$package" | awk '/Candidate:/ {print $2; exit}')"
        [[ -n "$candidate" && "$candidate" != '(none)' ]] || continue
        # Old distro docker-compose packages provide Compose v1, not `docker compose`.
        if [[ "$package" == docker-compose ]]; then
            # Strip a Debian version epoch such as 1: before comparing the major version.
            candidate="${candidate#*:}"
            [[ "$candidate" =~ ^([0-9]+)\. && "${BASH_REMATCH[1]}" -ge 2 ]] || continue
        fi
        privileged apt-get install -y --no-upgrade "$package"
        docker compose version
        return
    done
    die 'Docker was preserved, but no compatible Compose v2 package is available. Install the Compose plugin for your existing engine and rerun.'
}
# Arch/Fedora missing packages were handled earlier; Debian either adds Compose alone
# or installs the engine/plugins through a signed official APT repository.
install_docker() {
    if tool_installed docker; then printf 'skip: docker and Compose already installed\n'; return; fi
    if [[ "$family" == debian ]] && docker_present; then
        install_compose_only
        return
    fi
    if [[ "$family" == debian ]]; then
        printf 'Docker repository: %s / %s\n' "$docker_distro" "$docker_codename"
        if ((dry)); then
            printf 'Install Docker signing key and /etc/apt/sources.list.d/dotfiles-docker.sources\n'
        elif ((docker_repo_available)); then
            printf 'Reuse the configured official Docker APT repository\n'
        else
            fetch_script "https://download.docker.com/linux/$docker_distro/gpg" "$work_dir/docker.asc"
            local architecture
            architecture="$(dpkg --print-architecture)"
            # Generate deb822 source metadata locally, then copy it with sudo.
            # The signing key is scoped to this source through Signed-By.
            cat > "$work_dir/docker.sources" <<REPO
Types: deb
URIs: https://download.docker.com/linux/$docker_distro
Suites: $docker_codename
Components: stable
Architectures: $architecture
Signed-By: /etc/apt/keyrings/dotfiles-docker.asc
REPO
            privileged install -d -m 0755 /etc/apt/keyrings
            privileged install -m 0644 "$work_dir/docker.asc" /etc/apt/keyrings/dotfiles-docker.asc
            privileged install -m 0644 "$work_dir/docker.sources" /etc/apt/sources.list.d/dotfiles-docker.sources
        fi
        privileged apt-get update
        privileged apt-get install -y --no-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    if ((!dry)); then docker compose version; fi
}
# These explicit system changes are independent of installing the executable.
# Even a skipped, already-installed Docker can have its service/group configured.
configure_docker() {
    if ((enable_docker)); then privileged systemctl enable --now docker; fi
    if ((docker_group)); then
        privileged usermod -aG docker "$(id -un)"
        printf 'Docker group membership grants root-level access. Log out and back in to apply it.\n'
    fi
}
