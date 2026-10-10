#!/usr/bin/env bash
# Component paths and backed-up, repeatable symlink operations.
# Argument: config component. Return the template inside the permanent checkout.
# Some components own a whole directory; Starship/Konsole own a single file.
source_path() { case "$1" in
    ssh-agent) echo "$ROOT/config/systemd/user/ssh-agent.socket" ;;
    ssh-agent-service) echo "$ROOT/config/systemd/user/ssh-agent.service" ;;
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
    ssh-agent) echo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/ssh-agent.socket" ;;
    ssh-agent-service) echo "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/ssh-agent.service" ;;
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
