#!/usr/bin/env bash
# Component paths and backed-up, repeatable symlink operations.
# Argument: config component. Return the template inside the permanent checkout.
# Some components own a whole directory; Starship/Konsole own a single file.
source_path() { case "$1" in
    fish-file:*) echo "$ROOT/config/fish/${1#fish-file:}" ;;
    bash) echo "$ROOT/shell/bash/bashrc" ;;
    zsh) echo "$ROOT/config/zsh/.zshrc" ;;
    zsh-env) echo "$ROOT/config/zsh/.zshenv" ;;
    zsh-bootstrap) echo "$ROOT/shell/zsh/zshenv" ;;
    zsh-legacy) echo "$ROOT/shell/zsh/zshrc" ;;
    zsh-starship) echo "$ROOT/config/starship/starship.toml" ;;
    zsh-plugin-list) echo "$ROOT/config/zsh/plugins.list" ;;
    zsh-node|zsh-fzf|zsh-aliases|zsh-functions|zsh-bindings|zsh-plugins|zsh-prompt)
        echo "$ROOT/config/zsh/${1#zsh-}.zsh" ;;
    fish) echo "$ROOT/config/fish" ;;
    ghostty) echo "$ROOT/config/ghostty" ;;
    tmux) echo "$ROOT/config/tmux" ;;
    tmux-startup) echo "$ROOT/config/tmux/tmux.conf" ;;
    nvim) echo "$ROOT/config/nvim" ;;
    starship) echo "$ROOT/config/starship/starship.toml" ;;
    kitty | alacritty) echo "$ROOT/config/$1" ;;
    konsole) echo "$ROOT/config/konsole/Moon.colorscheme" ;;
    esac }
# Map each component to the location its application reads.
# ${XDG_CONFIG_HOME:-$HOME/.config} uses the XDG override when set, otherwise the default.
target_path() { case "$1" in
    fish-file:*) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish/${1#fish-file:}" ;;
    bash) echo "$HOME/.bashrc" ;;
    zsh) echo "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc" ;;
    zsh-env) echo "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshenv" ;;
    zsh-bootstrap) echo "$HOME/.zshenv" ;;
    zsh-legacy) echo "$HOME/.zshrc" ;;
    zsh-starship) echo "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/starship.toml" ;;
    zsh-plugin-list) echo "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.list" ;;
    zsh-node|zsh-fzf|zsh-aliases|zsh-functions|zsh-bindings|zsh-plugins|zsh-prompt)
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/${1#zsh-}.zsh" ;;
    fish) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish" ;;
    ghostty) echo "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty" ;;
    tmux) echo "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" ;;
    tmux-startup) echo "$HOME/.tmux.conf" ;;
    nvim) echo "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ;;
    starship) echo "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ;;
    kitty | alacritty) echo "${XDG_CONFIG_HOME:-$HOME/.config}/$1" ;;
    konsole) echo "${XDG_DATA_HOME:-$HOME/.local/share}/konsole/Moon.colorscheme" ;;
    esac }
# Selection priority: explicit --components, then --all, then detected installed apps.
# Used by install/unlink; setup builds its own chosen array from the wizard.
wanted() {
    local name="$1"
    if [[ -n "$selected" ]]; then
        [[ ",$selected," == *",$name,"* ]]
        return
    fi
    if ((all)); then return 0; fi
    case "$name" in
    bash | zsh | fish) [[ "$(detect_shell)" == "$name" ]] || command -v "$name" >/dev/null ;;
    *) command -v "$name" >/dev/null 2>&1 ;;
    esac
}
# Preview mode cannot change anything; --yes is an explicit unattended acceptance.
# Otherwise require a terminal and an affirmative answer before applying changes.
confirm() {
    ((dry || yes)) && return 0
    [[ -t 0 ]] || die "Use --yes for unattended changes, or --dry-run to preview."
    local proceed=0
    prompt_boolean proceed 'Proceed?'
    ((proceed))
}
# Argument: component. Verify its template, move an existing destination to a backup,
# then create an absolute symlink to the checkout. Matching links are left alone.
install_link() {
    local name="$1" src dst archive
    src="$(source_path "$name")"
    dst="$(target_path "$name")"
    [[ -e "$src" ]] || {
        echo "Missing template: $src" >&2
        return 1
    }
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "ok: $name already linked"
        return
    fi
    echo "link: $dst -> $src"
    ((dry)) && return 0
    mkdir -p "$(dirname "$dst")"
    # -e misses dangling symlinks; -L includes them so they are backed up too.
    if [[ -e "$dst" || -L "$dst" ]]; then
        # Preserve the target's relative path under HOME inside this run's backup folder.
        archive="$backup_dir/${dst#"$HOME"/}"
        mkdir -p "$(dirname "$archive")"
        mv -- "$dst" "$archive"
        echo "backup: $archive"
    fi
    ln -s -- "$src" "$dst"
}
# Remove only a symlink whose stored target matches this checkout's template.
# External files/links and archived backups are deliberately left in place.
unlink_link() {
    local src dst
    src="$(source_path "$1")"
    dst="$(target_path "$1")"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "unlink: $dst"
        ((dry)) || rm -- "$dst"
    else echo "skip: $dst not managed by this repo"; fi
}

# The imported tmux config reloads ~/.tmux.conf. Manage that startup link as well
# as the support directory, including when the directory link already exists.
# Link individual Zsh files rather than replacing the entire directory, preserving
# local.zsh and any unrelated user configuration. Runtime plugins/history live elsewhere.
zsh_support_links=(zsh-env zsh-node zsh-fzf zsh-aliases zsh-functions zsh-bindings zsh-plugins zsh-prompt zsh-plugin-list zsh-starship zsh-bootstrap zsh-legacy)
install_one() {
    local support
    if [[ "$1" == fish ]]; then install_fish_config; return; fi
    install_link "$1"
    if [[ "$1" == zsh ]]; then
        for support in "${zsh_support_links[@]}"; do install_link "$support"; done
        if ((!dry)); then mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"; fi
    fi
    if [[ "$1" == tmux ]]; then install_link tmux-startup; fi
}
unlink_one() {
    local support
    if [[ "$1" == fish ]]; then unlink_fish_config; return; fi
    unlink_link "$1"
    if [[ "$1" == zsh ]]; then
        for support in "${zsh_support_links[@]}"; do unlink_link "$support"; done
    fi
    if [[ "$1" == tmux ]]; then unlink_link tmux-startup; fi
}

# Validate explicit names before collecting config components into chosen.
select_components() {
    chosen=()
    if [[ -n "$selected" ]]; then validate_list "$selected" "${components[@]}"; fi
    for name in "${components[@]}"; do
        if wanted "$name"; then chosen+=("$name"); fi
    done
}
# cmd is install or unlink; select the corresponding helper for every chosen config.
link_components() {
    local name
    for name in "${chosen[@]}"; do "${cmd}_one" "$name"; done
}

# Fish rewrites universal settings and Fisher inventory. Keep these user-owned;
# link source files individually so local overrides and runtime state stay local.
install_fish_config() {
    local destination file relative seed archive previous
    destination="$(target_path fish)"
    if [[ -L "$destination" || ( -e "$destination" && ! -d "$destination" ) ]]; then
        printf 'Migrate Fish configuration to a writable directory: %s\n' "$destination"
        if ((!dry)); then
            previous="$(readlink -f -- "$destination" || true)"
            archive="$backup_dir/${destination#"$HOME"/}"
            mkdir -p -- "$(dirname "$archive")"
            mv -- "$destination" "$archive"
            mkdir -p -- "$destination"
            # Preserve runtime preferences from the former config, including a
            # managed directory link left by earlier installer versions.
            if [[ -d "$previous" ]]; then
                if [[ "$previous" != "$ROOT/config/fish" ]]; then
                    cp -a -- "$previous/." "$destination/"
                fi
                for seed in fish_variables fish_plugins local.fish; do
                    [[ ! -f "$previous/$seed" ]] || cp -- "$previous/$seed" "$destination/$seed"
                done
            fi
        fi
    fi
    if ((!dry)); then mkdir -p -- "$destination"; fi
    for seed in fish_variables fish_plugins; do
        if [[ ! -e "$destination/$seed" ]]; then
            run cp -- "$ROOT/config/fish/$seed" "$destination/$seed"
        fi
    done
    while IFS= read -r -d '' file; do
        relative="${file#"$ROOT/config/fish/"}"
        install_link "fish-file:$relative"
    done < <(find "$ROOT/config/fish" -type f -name '*.fish' -print0)
}
unlink_fish_config() {
    local file
    # Support both the former whole-directory link and the current file links.
    if [[ -L "$(target_path fish)" ]]; then unlink_link fish; return; fi
    while IFS= read -r -d '' file; do
        unlink_link "fish-file:${file#"$ROOT/config/fish/"}"
    done < <(find "$ROOT/config/fish" -type f -name '*.fish' -print0)
}
