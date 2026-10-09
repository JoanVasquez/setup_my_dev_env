# Clone during the installation phase, never while starting a shell.
# Data-directory storage prevents downloaded plugins from modifying the checkout.
ZPLUGINDIR="${ZPLUGINDIR:-$XDG_DATA_HOME/zsh/plugins}"
_zplugin_load() {
    local plugin_file="$ZPLUGINDIR/${1:t}/$2"
    [[ ! -r "$plugin_file" ]] || source "$plugin_file"
}

# Fallback native vi bindings remain usable when plugins were not selected/installed.
bindkey -v
_dotfiles_fzf_init
_dotfiles_bindings
local zplugin_repo zplugin_entry
while read -r zplugin_repo zplugin_entry; do
    [[ -n "$zplugin_repo" && "$zplugin_repo" != \#* ]] || continue
    _zplugin_load "$zplugin_repo" "$zplugin_entry"
done < "$ZDOTDIR/plugins.list"
unset zplugin_repo zplugin_entry

# Updates happen only when you explicitly invoke this function.
zplugin-update() {
    local plugin_dir
    for plugin_dir in "$ZPLUGINDIR"/*(/N); do
        [[ -d "$plugin_dir/.git" ]] || continue
        print "Updating ${plugin_dir:t}..."
        command git -C "$plugin_dir" pull --ff-only || return
    done
}
