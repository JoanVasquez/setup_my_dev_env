#!/usr/bin/env bash
# Read distro metadata in a subshell so it cannot alter installer variables.
# Argument: an os-release field name. Parentheses isolate sourced variables in a subshell.
# OS_RELEASE_FILE lets tests supply distro metadata without changing /etc.
os_field() (
    local field="$1"
    [[ -r "${OS_RELEASE_FILE:-/etc/os-release}" ]] || exit 0
    source "${OS_RELEASE_FILE:-/etc/os-release}"
    # Bash and Zsh use different indirect expansion syntax. This helper is sourced
    # by both shells, so expand the field with the active shell's own mechanism.
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        printf '%s\n' "${(P)field}"
    else
        printf '%s\n' "${!field:-}"
    fi
)
# Return arch, debian, fedora, or unsupported on stdout. Check the exact ID first,
# then split ID_LIKE into ancestry tokens; substring matches would misidentify names.
os_family() {
    local token
    for token in "$(os_field ID)" $(os_field ID_LIKE); do
        case "$token" in
            arch|manjaro|cachyos|endeavouros) printf 'arch\n'; return ;;
            debian|ubuntu|linuxmint|pop) printf 'debian\n'; return ;;
            fedora|nobara|ultramarine) printf 'fedora\n'; return ;;
        esac
    done
    printf 'unsupported\n'
}
# Prefer SHELL (normally the login shell), then the account database, then Bash.
# This detects a setup default, not necessarily the process running the installer.
# Read the account's current login shell, not a possibly stale inherited SHELL.
# A fallback keeps detection usable when the account database is unavailable.
account_shell() {
    local record=""
    if command -v getent >/dev/null 2>&1; then record="$(getent passwd "$(id -un)" || true)"; fi
    if [[ -n "$record" ]]; then printf '%s\n' "${record##*:}"; else printf '%s\n' "${SHELL:-}"; fi
}
detect_shell() {
    local current="${SHELL:-}"
    if [[ -z "$current" ]] && command -v getent >/dev/null; then
        current="$(getent passwd "$(id -un)" | cut -d: -f7)"
    fi
    case "${current##*/}" in bash|zsh|fish) printf '%s\n' "${current##*/}" ;; *) printf 'bash\n' ;; esac
}
# Prefer clues exported by the running terminal. If they are absent (for example
# in SSH), suggest the first supported executable on PATH, or none.
detect_terminal() {
    case "${TERM_PROGRAM:-}" in
        ghostty|kitty|alacritty) printf '%s\n' "$TERM_PROGRAM"; return ;;
    esac
    if [[ -n "${KONSOLE_VERSION:-}" ]]; then printf 'konsole\n'; return; fi
    if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then printf 'kitty\n'; return; fi
    case "${TERM:-}" in *kitty*) printf 'kitty\n'; return ;; *alacritty*) printf 'alacritty\n'; return ;; esac
    local app
    for app in kitty konsole alacritty ghostty; do
        if command -v "$app" >/dev/null 2>&1; then printf '%s\n' "$app"; return; fi
    done
    printf 'none\n'
}

# OSTree/image-based desktops require a different installation lifecycle.
# Keep config-only operations available instead of attempting host DNF writes.
fedora_atomic() {
    [[ -e /run/ostree-booted ]] && return 0
    case "$(os_field VARIANT_ID)" in
        silverblue|kinoite|sericea|onyx|coreos|sway-atomic|budgie-atomic) return 0 ;;
    esac
    return 1
}
# Zsh's global startup file is compiled to different distro paths.
system_zshenv_path() {
    if [[ -n "${ZSH_GLOBAL_ENV_FILE:-}" ]]; then printf '%s\n' "$ZSH_GLOBAL_ENV_FILE"
    elif [[ "$family" == debian ]]; then printf '/etc/zsh/zshenv\n'
    else printf '/etc/zshenv\n'; fi
}
