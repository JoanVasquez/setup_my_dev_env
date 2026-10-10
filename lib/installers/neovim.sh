#!/usr/bin/env bash
# Preserve system packages while supplying the version required by this config.
# The archive includes Neovim's runtime files, not just the executable.
install_neovim_runtime() {
    if command_exists nvim && neovim_compatible; then return 0; fi
    local architecture directory archive runtime launcher saved_launcher
    case "$(uname -m)" in
        x86_64) architecture=x86_64 ;;
        aarch64|arm64) architecture=arm64 ;;
        *) die 'Neovim runtime fallback supports Linux x86_64 and aarch64 only. Install Neovim 0.11.3+ separately.' ;;
    esac
    archive="nvim-linux-$architecture"
    directory="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/neovim/v0.11.5"
    runtime="$directory/$archive"
    launcher="$HOME/.local/bin/nvim"
    printf 'Ensure Neovim v0.11.5 user runtime in %s (requires 0.11.3+)\n' "$runtime"
    if ((dry)); then return; fi
    if ! neovim_compatible "$runtime/bin/nvim"; then
        fetch_script "https://github.com/neovim/neovim/releases/download/v0.11.5/$archive.tar.gz" "$work_dir/neovim.tar.gz"
        mkdir -p "$work_dir/neovim-release"
        tar -xzf "$work_dir/neovim.tar.gz" -C "$work_dir/neovim-release"
        neovim_compatible "$work_dir/neovim-release/$archive/bin/nvim" || die 'Downloaded Neovim cannot run or does not meet the required version.'
        mkdir -p "$directory"
        if [[ -e "$runtime" || -L "$runtime" ]]; then
            mkdir -p "$backup_dir/neovim"
            mv -- "$runtime" "$backup_dir/neovim/$archive"
        fi
        mv -- "$work_dir/neovim-release/$archive" "$runtime"
    fi
    neovim_compatible "$runtime/bin/nvim" || die "Incomplete Neovim runtime: $runtime; repair or move it before rerunning."
    mkdir -p "$HOME/.local/bin"
    if [[ -L "$launcher" && "$(readlink "$launcher")" == "$runtime/bin/nvim" ]]; then return 0; fi
    if [[ -e "$launcher" || -L "$launcher" ]]; then
        saved_launcher="$backup_dir/.local/bin/nvim"
        mkdir -p "$(dirname "$saved_launcher")"
        mv -- "$launcher" "$saved_launcher"
        printf 'Backed up previous Neovim launcher to %s\n' "$saved_launcher"
    fi
    ln -s -- "$runtime/bin/nvim" "$launcher"
    hash -r
    run nvim --version
}

# Provision the configuration only after its files are linked. Missing plugins,
# language servers, formatters and parsers are installed; ordinary startup stays
# free of automatic tool updates. Config-only runs never enter this step.
bootstrap_neovim() {
    [[ " ${chosen[*]} " == *' nvim '* ]] || return 0
    printf 'Ensure Neovim plugins, language tools and Treesitter parsers\n'
    run nvim --headless -i NONE -S "$ROOT/config/nvim/bootstrap.lua"
}
