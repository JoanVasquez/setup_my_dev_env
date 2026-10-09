# The plugin defines its cursor constants before calling zvm_config.
zvm_config() {
    # Use ZLE's key reader so custom Escape bindings also handle key prefixes.
    ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_ZLE
    ZVM_KEYTIMEOUT=0.03
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VI_HIGHLIGHT_BACKGROUND=none
    ZVM_VI_HIGHLIGHT_FOREGROUND=none
    ZVM_VI_HIGHLIGHT_EXTRASTYLE=none
}
_dotfiles_escape() { zle redisplay; }
zle -N _dotfiles_escape

_dotfiles_bindings() {
    KEYTIMEOUT=3
    # Escape cancels a picker/search without leaving the prompt in vi command mode.
    bindkey -M viins '^[' _dotfiles_escape
    # fzf's initialization can be guarded against a second source. Restore its
    # widgets explicitly after vi-mode replaces the keymap.
    local keymap
    for keymap in emacs viins vicmd; do
        if (( $+widgets[fzf-history-widget] )); then
            bindkey -M "$keymap" '^R' fzf-history-widget
        fi
        if (( $+widgets[fzf-file-widget] )); then
            bindkey -M "$keymap" '^T' fzf-file-widget
        fi
        if (( $+widgets[fzf-cd-widget] )); then
            bindkey -M "$keymap" '\ec' fzf-cd-widget
        fi
    done
    bindkey -M viins '^[[1;5C' forward-word
    bindkey -M viins '^[[1;5D' backward-word
    bindkey -M viins '^F' _fzf_file_no_hidden
    if (( $+widgets[autosuggest-toggle] )); then bindkey -M viins '^\' autosuggest-toggle; fi
    if (( $+widgets[history-substring-search-up] )); then
        bindkey -M viins '^[[A' history-substring-search-up
        bindkey -M viins '^[[B' history-substring-search-down
    else
        bindkey -M viins '^[[A' up-line-or-history
        bindkey -M viins '^[[B' down-line-or-history
    fi
}
# Reapply fzf/custom keys after zsh-vi-mode initialization, which resets viins.
zvm_after_init() { _dotfiles_fzf_init; _dotfiles_bindings; }
