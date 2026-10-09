# DOTFILES_SHELL is set by the shell-specific entrypoint.
# Each program emits shell-specific initialization code; eval installs its functions/hooks.
# Check availability first so the config works even with a smaller tool selection.
command -v starship >/dev/null 2>&1 && eval "$(starship init "$DOTFILES_SHELL")"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init "$DOTFILES_SHELL")"
# Older distro fzf packages ship initialization files instead of --bash/--zsh.
if command -v fzf >/dev/null 2>&1; then
    if dotfiles_fzf_init="$(fzf "--$DOTFILES_SHELL" 2>/dev/null)"; then
        eval "$dotfiles_fzf_init"
    else
        for dotfiles_fzf_dir in "$HOME/.fzf/shell" /usr/share/fzf /usr/share/fzf/shell /usr/share/doc/fzf/examples; do
            [[ -r "$dotfiles_fzf_dir/key-bindings.$DOTFILES_SHELL" ]] || continue
            source "$dotfiles_fzf_dir/key-bindings.$DOTFILES_SHELL"
            [[ ! -r "$dotfiles_fzf_dir/completion.$DOTFILES_SHELL" ]] || source "$dotfiles_fzf_dir/completion.$DOTFILES_SHELL"
            break
        done
    fi
    unset dotfiles_fzf_init dotfiles_fzf_dir
fi
