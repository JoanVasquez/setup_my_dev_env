#!/usr/bin/env bash
# Local status helpers work on Arch, Debian and Fedora without extra plugins.
case "${1:-}" in
    sessions)
        [[ $# == 2 ]] || exit 1
        sessions="$(tmux list-sessions -F '#{session_id}' 2>/dev/null)" || exit 0
        while IFS= read -r session; do
            [[ -n "$session" ]] || continue
            if [[ "$session" == "$2" ]]; then printf '👻 '
            else printf '● '; fi
        done <<< "$sessions" ;;
    uptime)
        # /proc exposes seconds consistently across Linux distro families.
        [[ -r /proc/uptime ]] || exit 0
        read -r seconds _ < /proc/uptime
        seconds="${seconds%%.*}"
        [[ "$seconds" =~ ^[0-9]+$ ]] || exit 0
        days=$((seconds / 86400))
        hours=$((seconds / 3600 % 24))
        minutes=$((seconds / 60 % 60))
        if ((days)); then printf '%dd %dh %dm' "$days" "$hours" "$minutes"
        elif ((hours)); then printf '%dh %dm' "$hours" "$minutes"
        else printf '%dm' "$minutes"; fi ;;
    *) exit 1 ;;
esac
