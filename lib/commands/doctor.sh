#!/usr/bin/env bash
# Inspect the current setup without linking files, downloading tools, or installing packages.
doctor() {
    ui_section 'System'
    printf 'Detected OS family: %s | distro: %s | desktop: %s | shell: %s | terminal: %s\n' \
        "$family" "$(os_field ID)" "$(detect_desktop)" "$(detect_shell)" "$(detect_terminal)"
    ui_section 'Managed configuration'
    local name dst src app linked=0 external=0 missing=0
    # Linked means owned by this checkout; external means another file/link occupies the target.
    for name in "${components[@]}" tmux-startup "${zsh_support_links[@]}" "${konsole_support_links[@]}"; do
        dst="$(target_path "$name")"; src="$(source_path "$name")"
        if [[ "$name" == fish && -L "$dst/config.fish" && "$(readlink "$dst/config.fish")" == "$ROOT/config/fish/config.fish" ]]; then
            printf '[linked] %s (individual files; user-owned state)\n' "$name"; linked=$((linked + 1))
        elif [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            printf '[linked] %s\n' "$name"; linked=$((linked + 1))
        elif [[ -e "$dst" || -L "$dst" ]]; then
            printf '[external] %s\n' "$name"; external=$((external + 1))
        else
            printf '[missing] %s\n' "$name"; missing=$((missing + 1))
        fi
    done
    printf 'Configuration summary: %d linked | %d external | %d not configured\n' "$linked" "$external" "$missing"
    export PATH="$HOME/.local/bin:$PATH"
    # Executable checks show what this process can launch; they do not imply config ownership.
    ui_section 'Executables'
    for app in git fish zsh bash tmux nvim starship fzf zoxide bat kitty alacritty konsole ghostty plasmashell kwin_wayland dolphin java docker node npm codex aws eza lf python3 go javac cc make tree-sitter rg fd fdfind batcat xclip wl-copy dnf; do
        if command -v "$app" >/dev/null 2>&1; then printf '[installed] %s\n' "$app"; else printf '[absent] %s\n' "$app"; fi
    done
    # nvm is not an executable: source it in a child Bash shell to show Node/npm/Codex.
    if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
        printf '[installed] nvm\n'
        NVM_DIR="${NVM_DIR:-$HOME/.nvm}" bash -c 'source "$NVM_DIR/nvm.sh"; nvm use default >/dev/null && node --version && npm --version; command -v codex || true' || printf '[broken] nvm default environment\n'
    elif fish_bin="$(fish_lts_bin)"; then
        printf '[installed] nvm.fish + Node LTS\n'
        "$fish_bin/node" --version
    else printf '[absent] nvm\n'; fi
    local unhealthy=0
    ui_section 'Runtime health (does not contact daemons)'
    for app in "${tools_available[@]}"; do
        if tool_installed "$app"; then printf '[healthy] %s\n' "$app"
        else printf '[missing/broken] %s\n' "$app"; unhealthy=$((unhealthy + 1)); fi
    done
    printf 'Unavailable or unhealthy optional tools: %s\n' "$unhealthy"
    if command -v docker >/dev/null 2>&1; then docker compose version || printf '[absent] Docker Compose plugin\n'; fi
}
