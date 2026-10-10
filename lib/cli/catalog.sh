#!/usr/bin/env bash
# Tools can be installed; components are the subset with repository configs to link.
# The tools string below is the unattended default; the wizard builds its own selection.
tools_available=(git nvim tmux starship zoxide nvm docker java codex fzf bat ripgrep fd clipboard tpm aws eza lf zsh-plugins vim tree fastfetch)
default_tools=git,nvim,tmux,starship,zoxide,nvm,docker,java,codex,fzf,bat,ripgrep,fd,tpm,aws
components=(bash zsh fish tmux nvim starship kitty alacritty konsole ghostty ssh-agent)

shells_available=(bash fish zsh)
terminals_available=(kitty konsole alacritty ghostty)
