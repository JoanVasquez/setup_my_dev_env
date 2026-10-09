#!/usr/bin/env bash
# Probe executables, including local installs, before scheduling any installation.
# Probes return status 0 for present and nonzero for absent, so callers can use if/!.
# command -v checks PATH without launching the program.
command_exists() { command -v "$1" >/dev/null 2>&1; }
# Fish uses the native nvm.fish imported from the system; Bash/Zsh use nvm-sh.
uses_native_fish_nvm() {
    [[ "${shell_choice:-auto}" == fish ]] ||
        [[ "${shell_choice:-auto}" == auto && "$(detect_shell)" == fish ]]
}
fish_nvm_data() { printf '%s\n' "${nvm_data:-${XDG_DATA_HOME:-$HOME/.local/share}/nvm}"; }
fish_lts_bin() {
    local directory node
    directory="$(fish_nvm_data)"
    # Inspect installed binaries, newest first, without starting an interactive
    # Fish shell or downloading its remote version index.
    local -a candidates
    mapfile -t candidates < <(printf '%s\n' "$directory"/v*/bin/node | sort -Vr)
    for node in "${candidates[@]}"; do
        [[ -x "$node" ]] || continue
        if [[ "$("$node" -p 'Boolean(process.release.lts)' 2>/dev/null)" == true ]]; then
            printf '%s\n' "${node%/node}"
            return
        fi
    done
    return 1
}
# nvm is a sourced shell function, so checking PATH alone cannot detect it.
# Bash/Zsh require a default LTS Node; Fish requires its local index and an installed LTS.
nvm_ready() {
    if uses_native_fish_nvm; then
        [[ -r "$(fish_nvm_data)/.index" ]] && fish_lts_bin >/dev/null
        return
    fi
    local directory="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$directory/nvm.sh" ]] || return 1
    # Probe in a child Bash shell; --no-use avoids changing this installer's Node environment.
    # nvm which resolves a local executable; this check does not fetch remote releases.
    NVM_DIR="$directory" bash -c '
        source "$NVM_DIR/nvm.sh" --no-use >/dev/null || exit 1
        node_path=$(nvm which default 2>/dev/null) || exit 1
        [[ -x "$node_path" ]] || exit 1
        [[ $("$node_path" -p "Boolean(process.release.lts)" 2>/dev/null) == true ]]
    ' >/dev/null 2>&1
}
# A global/local Codex command counts as installed. Also check nvm's default
# environment, whose bin directory may not yet be in the installer's PATH.
codex_present() {
    command_exists codex && return 0
    local fish_bin
    if fish_bin="$(fish_lts_bin)" && [[ -x "$fish_bin/codex" ]]; then return 0; fi
    local directory="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$directory/nvm.sh" ]] || return 1
    NVM_DIR="$directory" bash -c 'source "$NVM_DIR/nvm.sh" >/dev/null && command -v codex >/dev/null' >/dev/null 2>&1
}
# Docker CLI presence and Compose plugin availability are separate checks.
# `docker compose version` works without contacting the Docker daemon.
docker_present() {
    if [[ "${family:-}" == fedora ]] && package_installed podman-docker; then return 1; fi
    command_exists docker
}
compose_present() { docker_present && docker compose version >/dev/null 2>&1; }
# The Lua configuration uses APIs introduced in Neovim 0.11.3. Executable
# presence alone is insufficient on stable distro releases.
neovim_compatible() {
    local executable="${1:-nvim}" version
    version="$("$executable" --version 2>/dev/null)" || return 1
    [[ "$version" =~ ^NVIM[[:space:]]v([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
    local major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}" patch="${BASH_REMATCH[3]}"
    ((10#$major > 0 || 10#$minor > 11 || (10#$minor == 11 && 10#$patch >= 3)))
}
# Translate logical tool names into the appropriate executable or composite check.
# javac verifies a JDK; Debian may expose fd/bat as fdfind/batcat.
tool_installed() {
    case "$1" in
        nvim) command_exists nvim && neovim_compatible ;;
        nvm) nvm_ready ;;
        zsh-plugins) zsh_plugins_ready ;;
        cachyos-fish-config) [[ -r /usr/share/cachyos-fish-config/cachyos-config.fish ]] ;;
        codex) codex_present ;;
        docker) docker_present && compose_present ;;
        tpm) tmux_plugins_ready ;;
        python) command_exists python3 && python3 -c 'import venv, ensurepip' >/dev/null 2>&1 ;;
        c-compiler) command_exists cc || command_exists gcc || command_exists clang ;;
        tree-sitter) command_exists tree-sitter ;;
        java) command_exists javac ;;
        ripgrep) command_exists rg ;;
        fd) command_exists fd || command_exists fdfind ;;
        bat) command_exists bat || command_exists batcat ;;
        clipboard) command_exists xclip && command_exists wl-copy ;;
        *) command_exists "$1" ;;
    esac
}
# Argument: distro package name. Consult the local package database without installing.
# This prevents adding already-installed prerequisites to the package transaction.
package_installed() {
    case "$family" in
        debian) [[ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null || true)" == 'install ok installed' ]] ;;
        arch) pacman -Q "$1" >/dev/null 2>&1 ;;
        fedora) rpm -q -- "$1" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}
# Input: package_components. Output: missing_components and installed_components.
# Keep config selection separate: an installed tool may still need its config linked.
plan_installations() {
    missing_components=()
    installed_components=()
    local component
    for component in "${package_components[@]}"; do
        # Avoid duplicate selections and probes.
        [[ " ${missing_components[*]} ${installed_components[*]} " != *" $component "* ]] || continue
        if tool_installed "$component"; then
            installed_components+=("$component")
            printf 'skip: %s already installed\n' "$component"
        else
            missing_components+=("$component")
        fi
    done
}
