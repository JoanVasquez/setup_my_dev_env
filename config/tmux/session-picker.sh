#!/usr/bin/env bash

set -o pipefail

# Fall back to tmux's built-in tree when fzf is unavailable.
if ! command -v fzf >/dev/null 2>&1; then
    tmux choose-tree -s
    exit
fi

# Get running tmux sessions
if ! session=$(
    tmux list-sessions -F '#{session_name}' |
    fzf \
        --reverse \
        --border=rounded \
        --prompt='󰆍 Sessions ❯ ' \
        --pointer='❯' \
        --header='ENTER: Switch | ESC: Cancel' \
        --color='
            bg:#1e1e2e,
            fg:#cdd6f4,
            hl:#fab387,
            fg+:#cdd6f4,
            bg+:#313244,
            hl+:#cba6f7,
            pointer:#f38ba8,
            prompt:#89b4fa,
            border:#585b70,
            header:#f9e2af
        '
); then
    # Escape / Ctrl-C cancels without surfacing an error in the popup.
    exit 0
fi

# Switch to the selected session
if [[ -n "$session" ]]; then
    tmux switch-client -t "=$session"
fi
