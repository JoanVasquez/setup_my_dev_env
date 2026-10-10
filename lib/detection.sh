#!/usr/bin/env bash
# Probe executables, including local installs, before scheduling any installation.
# Probes return status 0 for present and nonzero for absent, so callers can use if/!.
# command -v checks PATH without launching the program.
command_exists() { command -v "$1" >/dev/null 2>&1; }
# Launch a harmless probe: a file on PATH can still have missing libraries,
# a stale interpreter, or a broken launcher. Never contact services here.
command_healthy() {
    command_exists "$1" || return 1
    if command_exists timeout; then timeout 10 "$@" >/dev/null 2>&1
    else "$@" >/dev/null 2>&1; fi
}
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
        local fish_bin fish_version
        fish_bin="$(fish_lts_bin)" || return 1
        fish_version="${fish_bin%/bin}"
        fish_version="${fish_version##*/}"
        [[ -s "$(fish_nvm_data)/.index" ]] || return 1
        awk -v version="$fish_version" '$1 == version && $2 ~ /^lts\// {found=1} END {exit !found}' "$(fish_nvm_data)/.index" || return 1
        PATH="$fish_bin:$PATH" command_healthy npm --version
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
        [[ $("$node_path" -p "Boolean(process.release.lts)" 2>/dev/null) == true ]] || exit 1
        PATH="${node_path%/*}:$PATH" npm --version >/dev/null 2>&1
    ' >/dev/null 2>&1
}
# A global/local Codex command counts as installed. Also check nvm's default
# environment, whose bin directory may not yet be in the installer's PATH.
codex_present() {
    command_healthy codex --version && return 0
    local fish_bin
    if fish_bin="$(fish_lts_bin)" && PATH="$fish_bin:$PATH" command_healthy "$fish_bin/codex" --version; then return 0; fi
    local directory="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$directory/nvm.sh" ]] || return 1
    NVM_DIR="$directory" bash -c 'source "$NVM_DIR/nvm.sh" >/dev/null && codex --version >/dev/null' >/dev/null 2>&1
}
# Docker CLI presence and Compose plugin availability are separate checks.
# `docker compose version` works without contacting the Docker daemon.
docker_present() {
    if [[ "${family:-}" == fedora ]] && package_installed podman-docker; then return 1; fi
    command_healthy docker --version
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
# The editor's Java language server requires JDK 21+, not just any javac.
java_compatible() {
    local version
    version="$(javac -version 2>&1)" || return 1
    [[ "$version" =~ javac[[:space:]]+([0-9]+) ]] || return 1
    ((10#${BASH_REMATCH[1]} >= 21))
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
        c-compiler) command_healthy cc --version || command_healthy gcc --version || command_healthy clang --version ;;
        tree-sitter) command_healthy tree-sitter --version ;;
        java) command_exists javac && java_compatible ;;
        ripgrep) command_healthy rg --version ;;
        fd) command_healthy fd --version || command_healthy fdfind --version ;;
        bat) command_healthy bat --version || command_healthy batcat --version ;;
        clipboard) command_exists xclip && command_exists wl-copy ;;
        bash|zsh|fish|git|starship|zoxide|fzf|aws|eza|vim|tree|fastfetch|make|curl|tar|gzip)
            command_healthy "$1" --version ;;
        unzip) command_healthy unzip -v ;;
        tmux) command_healthy tmux -V ;;
        lf) command_healthy lf -version ;;
        go) command_healthy go version ;;
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
