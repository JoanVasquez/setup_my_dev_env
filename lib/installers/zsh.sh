#!/usr/bin/env bash
# The runtime loader and installer share the same repository/entrypoint manifest.
zsh_plugin_directory() { printf '%s\n' "${ZPLUGINDIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"; }
zsh_plugins_ready() {
    local repository entry directory
    directory="$(zsh_plugin_directory)"
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        [[ -r "$directory/${repository##*/}/$entry" ]] || return 1
    done < "$ROOT/config/zsh/plugins.list"
}
install_zsh_plugins() {
    local repository entry directory destination
    directory="$(zsh_plugin_directory)"
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        destination="$directory/${repository##*/}"
        if [[ -r "$destination/$entry" ]]; then
            printf 'skip: %s already installed\n' "${repository##*/}"
            continue
        fi
        [[ ! -e "$destination" ]] || die "Incomplete Zsh plugin directory: $destination; repair or move it before rerunning."
        if ((!dry)); then mkdir -p "$directory"; fi
        run git clone --depth 1 "https://github.com/$repository.git" "$destination"
        if ((!dry)); then [[ -r "$destination/$entry" ]] || die "Missing Zsh plugin entrypoint: $destination/$entry"; fi
    done < "$ROOT/config/zsh/plugins.list"
}

# Optional system-wide bootstrap. Append a marked fragment instead of overwriting
# distro defaults. The user-level ~/.zshenv bridge works without this system change.
install_system_zshenv() {
    ((system_zshenv)) || return 0
    local destination
    destination="$(system_zshenv_path)"
    local fragment="$ROOT/config/zsh/system-zshenv.zsh"
    if [[ -r "$destination" ]] && grep -Fxq '# dotfiles-pro: XDG Zsh startup' "$destination"; then
        printf 'skip: system Zsh XDG bootstrap already installed\n'
        return
    fi
    printf 'Append XDG bootstrap to %s\n' "$destination"
    if ((dry)); then return; fi
    privileged install -d "$(dirname "$destination")"
    if [[ -e "$destination" ]]; then
        mkdir -p "$backup_dir/system"
        privileged cp -a -- "$destination" "$backup_dir/system/zshenv"
        printf 'System zshenv backup: %s/system/zshenv\n' "$backup_dir"
    fi
    # Fixed shell code receives filenames as positional parameters; no user input is eval-ed.
    # Appending preserves an existing file's owner/mode and follows its normal symlink target.
    privileged bash -c 'set -e; umask 022; printf "\n" >> "$2"; cat -- "$1" >> "$2"' dotfiles-zshenv "$fragment" "$destination"
}
