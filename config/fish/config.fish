# Keep CachyOS defaults on CachyOS; other distros use the portable conf.d layer.
if test "$DOTFILES_OS_ID" = cachyos; and test -r /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

set -gx EDITOR vim
set -gx VISUAL vim

#=====================
# useful aliases
#=====================
alias c="clear"
alias cls="clear"

alias ll="ls -lah"
alias la="ls -A"
alias l="ls"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias grep="grep --color=auto"

alias home="cd ~"

# Inspection includes interactive aliases without starting shell integrations.
if status is-interactive; or set -q DOTFILES_ALIAS_LISTING
    if type -q zoxide
        alias cd="z"
    end
end

alias cfish='nvim "$XDG_CONFIG_HOME/fish/config.fish"'

alias cnvim='nvim "$XDG_CONFIG_HOME/nvim"'

if command -q xclip
    alias xcopy="xclip -selection clipboard"
else if command -q wl-copy
    alias xcopy="wl-copy"
end

alias sen="sudo systemctl enable --now"
alias sstatus="sudo systemctl status"
alias sstop="sudo systemctl stop"

# Fuzzy kill process
function killfzf
    set pid (ps -eo pid,comm,args | fzf --prompt='Kill process > ' | awk '{print $1}')

    if test -n "$pid"
        kill -9 $pid
    end
end

#=====================
# git
#=====================

alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gsw="git switch"

# Fuzzy branch checkout
function gcofzf
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "󰊢 Not inside a Git repository."
        return 1
    end

    set branches (
        git for-each-ref \
            --format='%(refname:short)' \
            refs/heads/ refs/remotes/ |
        string replace -r '^origin/' '' |
        string match -v 'HEAD' |
        sort -u
    )

    if test (count $branches) -eq 0
        set current_branch (git branch --show-current)

        if test -n "$current_branch"
            echo "󰊢 Current branch: $current_branch"
            echo "No committed branches available yet."
            echo "Create your first commit first."
        else
            echo "No branches found."
        end

        return 1
    end

    set branch (
        printf '%s\n' $branches |
        fzf \
            --prompt=' Branch > ' \
            --header='ENTER: switch branch  •  ESC: cancel' \
            --height=60% \
            --border=rounded
    )

    if test -n "$branch"
        git switch $branch
    end
end

#=====================
# Package management (Arch, Debian and Fedora families)
#=====================
if contains -- "$DOTFILES_OS_FAMILY" arch debian fedora
    for package_alias in (command cat "$DOTFILES_HOME/shell/common/package-aliases.tsv")
        set -l fields (string split \t -- "$package_alias")
        if string match -q '#*' -- "$fields[1]"
            continue
        end
        if test "$DOTFILES_OS_FAMILY" = arch
            alias "$fields[1]" "$fields[2]"
        else if test "$DOTFILES_OS_FAMILY" = debian
            alias "$fields[1]" "$fields[3]"
        else
            alias "$fields[1]" "$fields[4]"
        end
    end
end

#=====================
# Docker
#=====================
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dr="docker run"
alias drit="docker run -it"
alias dpi="docker push"
alias di="docker images"
alias dsp="docker system prune"
alias dv="docker volume"
alias dvls="docker volume ls"
alias dpl="docker pull"
alias dmpl="docker model pull"

function dbf
    set -l filename (test -n "$argv[1]"; and echo $argv[1]; or echo "Dockerfile")
    set -l tagname  (test -n "$argv[2]"; and echo $argv[2]; or echo "latest-app")
    set -l targetdir (test -n "$argv[3]"; and echo $argv[3]; or echo ".")

    docker build -f $filename -t $tagname $targetdir
end

#=======================
# Docker compose
#=======================
alias dcr="docker compose run"
alias dcb="docker compose build"
alias dcub="docker compose up --build"
alias dcu="docker compose up"
alias dcud="docker compose up -d"
alias dcuro="docker compose up --remove-orphans"
alias dcudro="docker compose up -d --remove-orphans"
alias dcdro="docker compose down --remove-orphans"
alias dcd="docker compose down"
alias dcdv="docker compose down -v"
alias dcuw="docker compose up --watch"

#=====================
# Node
#=====================
# Automatically activate the LTS Node version
if status is-interactive
    if type -q nvm; and test -r "$nvm_data/.index"
        nvm use lts --silent
    end
end

alias ni="npm install"
alias nt="npm test"
alias nrd="npm run dev"
alias nb="npm run build"

#=====================
# Tmux
#=====================

# Smart tmux: attach to existing session or create one
function tmux --description "Attach or create tmux session"
    # Preserve native tmux commands with arguments
    if test (count $argv) -gt 0
        command tmux $argv
        return $status
    end

    # Already inside tmux
    if set -q TMUX
        echo "󰆍 Already inside tmux."
        return 0
    end

    # Attach to existing session or create 'main'
    command tmux new-session -A -s main
end

# Session management
alias t="tmux"
alias ta="tmux attach"
alias tan="tmux attach -t"
alias tls="tmux ls"
alias tn="tmux new -s"

# Rename sessions
alias rs="tmux rename-session"
alias trs="tmux rename-session -t"

# Kill session
alias tk="tmux kill-session -t"

# Restore last saved sessions
alias trestore="tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

# Save current sessions
alias tsave="tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh"
# Utils config

# ==============================
# FZF
# ==============================

set -gx FZF_DEFAULT_OPTS "\
--height=70% \
--layout=reverse \
--border=rounded \
--margin=1 \
--padding=1 \
--info=inline-right \
--separator='─' \
--scrollbar='│' \
--pointer='▶' \
--marker='✓' \
--prompt='  ' \
--color=fg:#cdd6f4,bg:#1e1e2e,hl:#a6e3a1 \
--color=fg+:#ffffff,bg+:#313244,hl+:#a6e3a1 \
--color=info:#89b4fa,prompt:#a6e3a1,pointer:#f5c2e7 \
--color=marker:#f9e2af,spinner:#89dceb,header:#89b4fa"

# Ctrl + T
set -gx FZF_CTRL_T_OPTS "\
--walker-skip=.git,node_modules,target,dist,build,.next \
--preview='bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null; or tree -C {} | head -200' \
--preview-window='right:55%:border-rounded' \
--bind='ctrl-/:toggle-preview'"

# Alt + C
set -gx FZF_ALT_C_OPTS "\
--walker-skip=.git,node_modules,target,dist,build,.next \
--preview='tree -C {} | head -200' \
--preview-window='right:55%:border-rounded'"

# Ctrl + R
set -gx FZF_CTRL_R_OPTS "\
--with-nth=3.. \
--preview-window=hidden \
--header='CTRL-R: ordenar  •  SHIFT-DEL: borrar  •  ESC: salir'"

# Setup installs these profile requirements automatically. Guards also allow
# config-only installs and noninteractive scripts to start without noisy errors.
if status is-interactive
    if type -q fzf
        if fzf --fish >/dev/null 2>&1
            fzf --fish 2>/dev/null | source
        else
            for fzf_directory in $HOME/.fzf/shell /usr/share/fzf /usr/share/fzf/shell /usr/share/doc/fzf/examples
                if test -r "$fzf_directory/key-bindings.fish"
                    source "$fzf_directory/key-bindings.fish"
                    break
                end
            end
        end
    end
    if type -q zoxide
        zoxide init fish | source
    end
    if type -q starship
        starship init fish | source
    end
end
