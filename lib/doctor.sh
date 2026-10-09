#!/usr/bin/env bash
# Inspect the current setup without linking files, downloading tools, or installing packages.
doctor() {
    printf 'Detected OS family: %s | distro: %s | shell: %s | terminal: %s\n' "$family" "$(os_field ID)" "$(detect_shell)" "$(detect_terminal)"
    local name dst src app
    # Linked means owned by this checkout; external means another file/link occupies the target.
    for name in "${components[@]}" tmux-startup "${zsh_support_links[@]}"; do
        dst="$(target_path "$name")"; src="$(source_path "$name")"
        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then printf '[linked] %s\n' "$name"
        elif [[ -e "$dst" || -L "$dst" ]]; then printf '[external] %s\n' "$name"
        else printf '[missing] %s\n' "$name"; fi
    done
    export PATH="$HOME/.local/bin:$PATH"
    # Executable checks show what this process can launch; they do not imply config ownership.
    for app in git fish zsh bash tmux nvim starship fzf zoxide bat kitty alacritty konsole ghostty java docker node npm codex aws eza lf python3 go javac cc make tree-sitter rg fd fdfind batcat xclip wl-copy dnf; do
        if command -v "$app" >/dev/null 2>&1; then printf '[installed] %s\n' "$app"; else printf '[absent] %s\n' "$app"; fi
    done
    # nvm is not an executable: source it in a child Bash shell to show Node/npm/Codex.
    if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
        printf '[installed] nvm\n'
        NVM_DIR="${NVM_DIR:-$HOME/.nvm}" bash -c 'source "$NVM_DIR/nvm.sh"; nvm use default >/dev/null && node --version && npm --version; command -v codex || true'
    elif fish_bin="$(fish_lts_bin)"; then
        printf '[installed] nvm.fish + Node LTS\n'
        "$fish_bin/node" --version
    else printf '[absent] nvm\n'; fi
    if command -v docker >/dev/null 2>&1; then docker compose version || printf '[absent] Docker Compose plugin\n'; fi
}
