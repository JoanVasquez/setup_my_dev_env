#!/usr/bin/env bash
# Inspect this checkout's effective aliases without loading prompts, plugins,
# local overrides, or installation hooks. Live-shell `aliases` includes those
# personal/session additions; an external process cannot inspect its parent.
list_configured_aliases() {
    local requested="${1:-all}" alias_shell
    local -a alias_shells=()
    [[ "$requested" != auto ]] || requested="$(detect_shell)"
    case "$requested" in
        all) alias_shells=(bash fish zsh) ;;
        bash|fish|zsh) alias_shells=("$requested") ;;
        *) die 'Alias shell must be bash, fish, zsh, auto, or all.' ;;
    esac
    for alias_shell in "${alias_shells[@]}"; do
        if ! command_exists "$alias_shell"; then
            if [[ "$requested" != all ]]; then die "Cannot list $alias_shell aliases: shell is not installed."; fi
            printf '\n[%s] skipped: shell is not installed\n' "$alias_shell"
            continue
        fi
        printf '\n[%s aliases]\n' "$alias_shell"
        case "$alias_shell" in
            bash)
                BASH_ENV=/dev/null bash --noprofile --norc -c '
                    DOTFILES_HOME=$1
                    source "$DOTFILES_HOME/lib/platform.sh"
                    source "$DOTFILES_HOME/shell/common/aliases.sh"
                    source "$DOTFILES_HOME/shell/common/platform.sh"
                    builtin alias
                ' dotfiles-aliases "$ROOT" ;;
            zsh)
                zsh -dfc '
                    DOTFILES_HOME=$1
                    source "$DOTFILES_HOME/lib/platform.sh"
                    # Completion registration is unnecessary for inspection.
                    compdef() { :; }
                    source "$DOTFILES_HOME/config/zsh/aliases.zsh"
                    builtin alias -L
                ' dotfiles-aliases "$ROOT" ;;
            fish)
                # Fish creates its state directories even with --no-config.
                # Keep inspection state disposable and the user's files untouched.
                (
                    alias_scratch="$(mktemp -d)"
                    trap 'rm -rf -- "$alias_scratch"' EXIT
                    XDG_CONFIG_HOME="$alias_scratch/config" XDG_DATA_HOME="$alias_scratch/data" \
                    XDG_STATE_HOME="$alias_scratch/state" XDG_CACHE_HOME="$alias_scratch/cache" \
                    fish --no-config -c '
                        set -g DOTFILES_ALIAS_LISTING 1
                        source "$argv[1]/config/fish/conf.d/dotfiles-environment.fish"
                        source "$argv[1]/config/fish/config.fish"
                        alias
                    ' "$ROOT"
                ) ;;
        esac
    done
}
