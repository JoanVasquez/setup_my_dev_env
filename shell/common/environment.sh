# Environment shared by Bash and Zsh.
# Surround PATH with colons to match a full directory entry, avoiding duplicate insertion.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# Keep user-provided editor choices; otherwise tools such as Git default to Neovim.
export EDITOR="${EDITOR:-nvim}" VISUAL="${VISUAL:-nvim}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Sourcing nvm defines its shell function and activates its configured default Node.
# Missing nvm is normal on a setup that did not select it.
if [ -s "$NVM_DIR/nvm.sh" ]; then . "$NVM_DIR/nvm.sh"; fi
