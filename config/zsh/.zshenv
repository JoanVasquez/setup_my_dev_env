# Environment for every Zsh process. Keep interactive hooks out of this file.
# Respect explicitly supplied XDG directories instead of resetting them.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
export EDITOR="${EDITOR:-nvim}" VISUAL="${VISUAL:-$EDITOR}"

# Add personal binaries once; Zsh's path array is tied to the exported PATH.
typeset -U path
path=("$HOME/.local/bin" $path)
export PATH

# Keep man-page formatting when choosing a colorized pager.
if (( $+commands[bat] )); then
    export MANPAGER='bat -l man -p'
elif (( $+commands[batcat] )); then
    export MANPAGER='batcat -l man -p'
fi
# Noninteractive processes may have no terminal: do not export "not a tty".
if [[ -t 0 ]] && (( $+commands[tty] )); then export GPG_TTY="$(tty)"; fi

# The installer links this to the same Starship configuration used by Fish.
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$ZDOTDIR/starship.toml}"
