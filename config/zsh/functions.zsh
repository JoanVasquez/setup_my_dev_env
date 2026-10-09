# Functions need native Zsh syntax; they cannot source your Fish definitions directly.
croot() { builtin cd "$(command git rev-parse --show-toplevel 2>/dev/null)" || return; }

tmux() {
    if (( $# )); then command tmux "$@"; return; fi
    if [[ -n "${TMUX:-}" ]]; then print 'Already inside tmux.'; return; fi
    command tmux new-session -A -s main
}
dbf() { command docker build -f "${1:-Dockerfile}" -t "${2:-latest-app}" "${3:-.}"; }

# Use real cat when reading machine-readable output: the cat alias may add colors.
lf() {
    (( $+commands[lf] )) || { print -u2 'lf is not installed'; return 1; }
    local last_dir_file chosen_dir result
    last_dir_file="$(mktemp)" || return
    command lf -last-dir-path="$last_dir_file" "$@"
    result=$?
    chosen_dir="$(command cat -- "$last_dir_file")"
    command rm -f -- "$last_dir_file"
    if (( result == 0 )) && [[ -d "$chosen_dir" ]]; then builtin cd -- "$chosen_dir"; else return "$result"; fi
}

# Match your Fish branch picker: include local branches and origin branches.
gcofzf() {
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { print -u2 'Not inside a Git repository'; return 1; }
    (( $+commands[fzf] )) || { print -u2 'fzf is not installed'; return 1; }
    local branch
    branch="$(command git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ |
        command sed 's#^origin/##; /^HEAD$/d; /\/HEAD$/d' | command sort -u |
        fzf --prompt=' Branch > ' --header='ENTER: switch branch • ESC: cancel' --height=60% --border=rounded)" || return 0
    [[ -z "$branch" ]] || command git switch -- "$branch"
}
killfzf() {
    (( $+commands[fzf] )) || { print -u2 'fzf is not installed'; return 1; }
    local selected_pid
    selected_pid="$(command ps -eo pid,comm,args | fzf --prompt='Kill process > ' | command awk '{print $1}')" || return 0
    [[ "$selected_pid" == <-> ]] || return 0
    # Preserve your explicit force-kill helper; a cancelled/header selection does nothing.
    command kill -9 -- "$selected_pid"
}

# List the live alias table, including aliases added by personal overrides.
aliases() { builtin alias; }
