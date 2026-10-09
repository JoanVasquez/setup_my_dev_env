# dotfiles-pro: XDG Zsh startup
# Optional distro global zshenv fragment. Keep global startup fast and quiet.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -o rcs && -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
