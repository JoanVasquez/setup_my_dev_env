# Portable environment for the imported Fish profile. Keep explicit XDG overrides.
if not set -q XDG_CONFIG_HOME; or test -z "$XDG_CONFIG_HOME"
    set -gx XDG_CONFIG_HOME $HOME/.config
end
if not set -q XDG_DATA_HOME; or test -z "$XDG_DATA_HOME"
    set -gx XDG_DATA_HOME $HOME/.local/share
end
fish_add_path --path --prepend $HOME/.local/bin

# Read the same distro detector as the installer; do not duplicate ID_LIKE parsing.
set -l dotfiles_root (path resolve (status filename))
set dotfiles_root (path dirname (path dirname (path dirname (path dirname "$dotfiles_root"))))
set -g DOTFILES_HOME "$dotfiles_root"
set -l distro (bash -c 'source "$1/lib/platform.sh"; os_family; os_field ID' dotfiles "$dotfiles_root")
set -g DOTFILES_OS_FAMILY $distro[1]
if set -q distro[2]
    set -g DOTFILES_OS_ID $distro[2]
else
    set -g DOTFILES_OS_ID unknown
end

# Debian exposes alternate executable names. These aliases also work inside
# previews launched in Fish, while keeping your original preview configuration.
if not type -q bat; and type -q batcat
    alias bat=batcat
end
if not type -q fd; and type -q fdfind
    alias fd=fdfind
end
if command -q bat
    set -gx MANPAGER 'bat -l man -p'
else if command -q batcat
    set -gx MANPAGER 'batcat -l man -p'
end

# nvm-sh and nvm.fish binaries work in either shell. Native nvm activation
# may select a different version later in interactive config.fish.
set -l node_bin (bash "$DOTFILES_HOME/shell/common/node-bin")
if test -n "$node_bin"
    fish_add_path --path --prepend (string split : -- "$node_bin")
end
