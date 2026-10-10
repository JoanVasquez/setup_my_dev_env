#!/usr/bin/env bash
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
