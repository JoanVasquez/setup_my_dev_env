# Portable file discovery: Debian installs fd as fdfind. Use find as a final fallback.
if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
elif (( $+commands[fdfind] )); then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
else
    export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/.git/*'"
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --prompt="  " --pointer="▶" --marker="✓" --preview-window=right:65%:wrap'
if (( $+commands[bat] )); then
    export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
elif (( $+commands[batcat] )); then
    export _FZF_PREVIEW_CMD='batcat --color=always --style=plain,numbers --line-range=:500 {}'
else
    export _FZF_PREVIEW_CMD='head -n 500 -- {}'
fi
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD' --bind 'ctrl-/:toggle-preview'"
export FZF_ALT_C_OPTS='--preview "ls -lah -- {}"'
export FZF_CTRL_R_OPTS='--preview-window=hidden --header="CTRL-R: sort • ESC: cancel"'

# Ctrl-F excludes hidden files. Invoke argv directly instead of eval-ing a command string.
_fzf_file_no_hidden() {
    (( $+commands[fzf] )) || { zle redisplay; return; }
    local selected_file
    if (( $+commands[fd] )); then
        selected_file="$(command fd --type f --exclude .git | command fzf --preview "$_FZF_PREVIEW_CMD")"
    elif (( $+commands[fdfind] )); then
        selected_file="$(command fdfind --type f --exclude .git | command fzf --preview "$_FZF_PREVIEW_CMD")"
    else
        selected_file="$(command find . -type f -not -path '*/.*' | command fzf --preview "$_FZF_PREVIEW_CMD")"
    fi
    # Quote filenames with spaces/metacharacters before inserting them into the command line.
    [[ -z "$selected_file" ]] || LBUFFER+="${(q)selected_file}"
    zle reset-prompt
}
zle -N _fzf_file_no_hidden

# fzf snapshots/restores the options array. Zsh rejects reassignment of zle
# in some startup contexts, so restore the other options without touching it.
# Only trusted fzf initialization text is evaluated; filenames never pass here.
_dotfiles_fzf_eval() {
    local initialization="$1"
    local old_snapshot='${(kv)options[@]}' new_snapshot='${(kv)dotfiles_fzf_options[@]}'
    local -A dotfiles_fzf_options
    zmodload zsh/parameter
    dotfiles_fzf_options=("${(@kv)options}")
    unset 'dotfiles_fzf_options[zle]'
    initialization=${initialization//"$old_snapshot"/"$new_snapshot"}
    eval "$initialization"
}

# This function is called once now, and again after zsh-vi-mode resets the keymap.
# Prefer modern `fzf --zsh`; older packages use distro/Homebrew/Git shell files.
_dotfiles_fzf_init() {
    (( $+commands[fzf] )) || return 0
    local initialization binding_file completion_file
    if initialization="$(command fzf --zsh 2>/dev/null)"; then
        _dotfiles_fzf_eval "$initialization"
        return
    fi
    for binding_file in "$HOME/.fzf/shell/key-bindings.zsh" /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
        /usr/local/opt/fzf/shell/key-bindings.zsh /usr/share/fzf/key-bindings.zsh /usr/share/fzf/shell/key-bindings.zsh \
        /usr/share/doc/fzf/examples/key-bindings.zsh; do
        [[ -r "$binding_file" ]] || continue
        _dotfiles_fzf_eval "$(command cat -- "$binding_file")"
        completion_file="${binding_file:h}/completion.zsh"
        [[ ! -r "$completion_file" ]] || _dotfiles_fzf_eval "$(command cat -- "$completion_file")"
        break
    done
}
