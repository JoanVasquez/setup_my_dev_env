# Zsh uses upstream nvm-sh; Fish keeps its native nvm.fish implementation.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ ! -s "$NVM_DIR/nvm.sh" ]] || source "$NVM_DIR/nvm.sh"

# Expose an existing Node installation after switching shells, including nvm.fish.
if dotfiles_node_bin="$(bash "$DOTFILES_HOME/shell/common/node-bin")"; then
    export PATH="$dotfiles_node_bin:$PATH"
fi
unset dotfiles_node_bin
