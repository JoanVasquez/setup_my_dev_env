#!/usr/bin/env bash
# Shared presentation primitives. Styling is enabled only for a real terminal and
# respects NO_COLOR; redirected output remains stable and easy to parse in CI.
ui_init() {
    local fd="${1:-1}"
    UI_RESET='' UI_BOLD='' UI_DIM='' UI_ACCENT='' UI_SUCCESS='' UI_WARNING='' UI_MUTED=''
    if [[ -t "$fd" && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
        UI_RESET=$'\033[0m'
        UI_BOLD=$'\033[1m'
        UI_DIM=$'\033[2m'
        UI_ACCENT=$'\033[38;5;141m'
        UI_SUCCESS=$'\033[38;5;114m'
        UI_WARNING=$'\033[38;5;221m'
        UI_MUTED=$'\033[38;5;245m'
    fi
}

ui_banner() {
    ui_init 2
    printf '\n%s%s  DEV ENVIRONMENT%s\n' "$UI_BOLD" "$UI_ACCENT" "$UI_RESET" >&2
    printf '%s  Reproducible workstation setup · safe, modular, testable%s\n\n' "$UI_MUTED" "$UI_RESET" >&2
}

ui_section() {
    local title="$1" fd="${2:-1}"
    ui_init "$fd"
    printf '\n%s%s%s%s\n' "$UI_BOLD" "$UI_ACCENT" "$title" "$UI_RESET" >&"$fd"
}

ui_note() {
    ui_init 2
    printf '%s  %s%s\n' "$UI_MUTED" "$*" "$UI_RESET" >&2
}

ui_success() {
    ui_init 1
    if [[ -n "$UI_SUCCESS" ]]; then
        printf '\n%s✓%s %s\n' "$UI_SUCCESS" "$UI_RESET" "$*"
    else
        printf '\n[ok] %s\n' "$*"
    fi
}

ui_bool() {
    if (($1)); then printf 'yes'; else printf 'no'; fi
}
