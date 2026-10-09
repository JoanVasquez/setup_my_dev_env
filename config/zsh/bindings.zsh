# The plugin defines its cursor constants before calling zvm_config.
zvm_config() {
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VI_HIGHLIGHT_BACKGROUND=none
    ZVM_VI_HIGHLIGHT_FOREGROUND=none
    ZVM_VI_HIGHLIGHT_EXTRASTYLE=none
}
_dotfiles_bindings() {
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
