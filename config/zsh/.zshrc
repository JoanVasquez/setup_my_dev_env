# Modular Zsh profile adapted from Radley E. Sidwell-Lewis's example and your Fish config.
# User overrides belong in $ZDOTDIR/local.zsh and load last.
[[ -o interactive ]] || return
DOTFILES_HOME="${${(%):-%x}:A:h:h:h}"
source "$DOTFILES_HOME/lib/platform.sh"

# Shared SSH agent for local terminal sessions; preserve forwarded remote agents.
if [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_TTY:-}" && -n "${XDG_RUNTIME_DIR:-}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# History/cache belong in writable user directories, never the linked checkout.
mkdir -p -- "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS AUTOCD NOBEEP NUMERIC_GLOB_SORT

# Completion initializes before plugins and compdef declarations.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Optional lf icons and directory jumping; plain cd still works without zoxide.
if [[ -r "$XDG_CONFIG_HOME/lf/icons" ]]; then
    export LF_ICONS="$(command tr '\n' ':' < "$XDG_CONFIG_HOME/lf/icons")"
fi
if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; fi

# Define widgets/configuration before loading plugins that use their hooks.
for dotfiles_module in node fzf aliases functions bindings plugins prompt; do
    source "$ZDOTDIR/$dotfiles_module.zsh"
done
unset dotfiles_module
[[ ! -f "$ZDOTDIR/local.zsh" ]] || source "$ZDOTDIR/local.zsh"
