# DOTFILES_SHELL is set by the shell-specific entrypoint.
# Each program emits shell-specific initialization code; eval installs its functions/hooks.
# Check availability first so the config works even with a smaller tool selection.
command -v starship >/dev/null 2>&1 && eval "$(starship init "$DOTFILES_SHELL")"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init "$DOTFILES_SHELL")"
# Older fzf packages may lack --bash/--zsh; ignore that optional integration failure.
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf "--$DOTFILES_SHELL" 2>/dev/null)" || true
fi
