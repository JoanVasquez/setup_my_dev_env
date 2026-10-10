#!/usr/bin/env bash
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

