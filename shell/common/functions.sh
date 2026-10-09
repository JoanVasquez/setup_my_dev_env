# Shared Bash/Zsh functions
# Move to the root of the current Git repository; leave cwd unchanged on failure.
croot() { cd "$(git rev-parse --show-toplevel 2>/dev/null)" || return; }
# With arguments, pass through to tmux. Without them, attach/create the main session
# unless already inside tmux (TMUX is set by an active tmux client).
tmux-smart() {
  if [ "$#" -gt 0 ]; then command tmux "$@"; return; fi
  if [ -n "${TMUX:-}" ]; then printf 'Already in tmux\n'; return; fi
  command tmux new-session -A -s main
}
# List local branch names, let fzf pick one, and switch to it.
# An empty/cancelled picker is treated as doing nothing, not an installation error.
gcofzf() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'Not inside Git repository' >&2; return 1; }
  command -v fzf >/dev/null 2>&1 || { echo 'fzf not installed' >&2; return 1; }
  local branch
  branch=$(git branch --format='%(refname:short)' | fzf --border=rounded --prompt='Branch > ') || return 0
  [ -n "$branch" ] && git switch -- "$branch"
}
