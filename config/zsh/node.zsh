# Zsh uses upstream nvm-sh; Fish keeps its native nvm.fish implementation.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ ! -s "$NVM_DIR/nvm.sh" ]] || source "$NVM_DIR/nvm.sh"
