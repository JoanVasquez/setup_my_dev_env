# Display/navigation shortcuts adapted from your Fish config.
alias c='clear' cls='clear' l='ls'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias home='cd ~'
alias -- -='cd -'
if (( $+commands[eza] )); then
    alias ls='eza --icons=auto'
    alias ll='eza -lh --icons=auto --git'
    alias la='eza -lah --icons=auto --git'
    alias tree='eza --tree --icons=auto'
    compdef eza=ls
else
    alias ll='ls -lah' la='ls -A'
fi
if (( $+commands[bat] )); then
    alias cat='bat'
elif (( $+commands[batcat] )); then
    alias bat='batcat' cat='batcat'
fi
if (( ! $+commands[fd] && $+commands[fdfind] )); then alias fd='fdfind'; fi
alias grep='grep --color=auto'
alias diff='diff --color=auto' df='df -h' vim='nvim'
# Keep cd's native semantics (including cd -); use z explicitly for ranked jumps.
alias cfish='nvim "${XDG_CONFIG_HOME}/fish/config.fish"'
alias czsh='nvim "$ZDOTDIR/.zshrc"' cnvim='nvim "${XDG_CONFIG_HOME}/nvim"'
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-copy] )); then alias xcopy='wl-copy'
elif (( $+commands[xclip] )); then alias xcopy='xclip -selection clipboard'
elif (( $+commands[wl-copy] )); then alias xcopy='wl-copy'; fi
alias sen='sudo systemctl enable --now' sstatus='sudo systemctl status' sstop='sudo systemctl stop'

# Shared mappings keep Bash, Zsh and Fish package shortcuts consistent.
source "$DOTFILES_HOME/shell/common/platform.sh"

# Git aliases retain your Fish names; pager overrides affect only these commands.
alias g='git' gs='git status' ga='git add' gaa='git add .' gc='git commit'
alias gcm='git commit -m' gp='git push' gl='git pull' gd='git diff' gb='git branch'
alias gco='git checkout' gsw='git switch'
alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
# This project is a regular checkout; do not assume a separate bare ~/.dotfiles repository.
alias dotfiles='"$DOTFILES_HOME/bin/dotfiles"'

# Docker/Compose helpers. dcud fixes the Fish typo by including the up subcommand.
alias d='docker' dc='docker compose' dps='docker ps' dpa='docker ps -a'
alias dr='docker run' drit='docker run -it' dpi='docker push' di='docker images'
alias dsp='docker system prune' dv='docker volume' dvls='docker volume ls'
alias dpl='docker pull' dmpl='docker model pull'
alias dcr='docker compose run' dcb='docker compose build' dcub='docker compose up --build'
alias dcu='docker compose up' dcud='docker compose up -d'
alias dcuro='docker compose up --remove-orphans' dcudro='docker compose up -d --remove-orphans'
alias dcdro='docker compose down --remove-orphans' dcd='docker compose down'
alias dcdv='docker compose down -v' dcuw='docker compose up --watch'
# npm scripts need `run`; npm build alone is not the usual package build command.
alias ni='npm install' nt='npm test' nrd='npm run dev' nb='npm run build'
alias n='nvim'

# tmux() in functions.zsh implements your attach/create behavior.
alias t='tmux' ta='tmux attach' tan='tmux attach -t' tls='tmux ls' tn='tmux new -s'
alias rs='tmux rename-session' trs='tmux rename-session -t' tk='tmux kill-session -t'
# run-shell parses its argument again; retain quotes for that second shell.
alias trestore='tmux run-shell '\''"$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"'\'''
alias tsave='tmux run-shell '\''"$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"'\'''
