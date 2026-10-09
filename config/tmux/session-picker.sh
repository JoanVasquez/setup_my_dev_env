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
            bg:#222436,
            fg:#c8d3f5,
            hl:#86e1fc,
            fg+:#c8d3f5,
            bg+:#3b4261,
            hl+:#c099ff,
            pointer:#ff757f,
            prompt:#82aaff,
            border:#444a73,
            header:#ffc777
        '
); then
    # Escape / Ctrl-C cancels without surfacing an error in the popup.
    exit 0
fi

# Switch to the selected session
if [[ -n "$session" ]]; then
    tmux switch-client -t "=$session"
fi
