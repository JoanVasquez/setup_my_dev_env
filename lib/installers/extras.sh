#!/usr/bin/env bash
# Arch installs Starship through pacman; Debian/Fedora use the upstream script
# only when no executable is present. A writable user bin directory avoids sudo.
install_starship() {
    if [[ "$family" == arch ]] || command -v starship >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/starship" ]]; then return; fi
    printf 'Install Starship into ~/.local/bin using its upstream installer\n'
    if ((dry)); then return; fi
    mkdir -p "$HOME/.local/bin"
    fetch_script https://starship.rs/install.sh "$work_dir/starship-install.sh"
    sh "$work_dir/starship-install.sh" --yes --bin-dir "$HOME/.local/bin"
}
# A configured tmux needs the manager plus the persistence plugins it loads.
# Probe and clone each checkout separately, preserving existing plugin versions.
tmux_plugins_ready() {
    local repository entry
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        [[ -x "$HOME/.tmux/plugins/${repository##*/}/$entry" ]] || return 1
    done < "$ROOT/packages/tmux-plugins.tsv"
}
install_tpm() {
    local repository entry destination
    while read -r repository entry; do
        [[ -n "$repository" && "$repository" != \#* ]] || continue
        destination="$HOME/.tmux/plugins/${repository##*/}"
        if [[ -x "$destination/$entry" ]]; then
            printf 'skip: %s already installed\n' "${repository##*/}"
            continue
        fi
        [[ ! -e "$destination" ]] || die "Incomplete tmux plugin directory: $destination; repair or move it before installing."
        if ((!dry)); then mkdir -p "$(dirname "$destination")"; fi
        run git clone --depth 1 "https://github.com/$repository" "$destination"
        if ((!dry)); then [[ -x "$destination/$entry" ]] || die "Missing tmux plugin entrypoint: $destination/$entry"; fi
    done < "$ROOT/packages/tmux-plugins.tsv"
}

# Stable Debian/Ubuntu releases do not consistently package the CLI. Use the
# upstream standalone binary there; Arch and Fedora have native packages.
install_tree_sitter() {
    [[ "$family" != arch && "$family" != fedora ]] || return 0
    local architecture
    case "$(uname -m)" in
        x86_64) architecture=x64 ;;
        aarch64|arm64) architecture=arm64 ;;
        *) die 'Tree-sitter CLI binary installation supports x86_64 and aarch64 only.' ;;
    esac
    printf 'Install Tree-sitter CLI v0.26.11 into ~/.local/bin\n'
    if ((dry)); then return; fi
    fetch_script "https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.11/tree-sitter-linux-$architecture.gz" "$work_dir/tree-sitter.gz"
    gzip -dc "$work_dir/tree-sitter.gz" > "$work_dir/tree-sitter"
    run install -Dm755 "$work_dir/tree-sitter" "$HOME/.local/bin/tree-sitter"
    run tree-sitter --version
}

# Fedora does not ship lf in its standard repositories. Use the project's
# standalone release so the Zsh profile works without enabling a COPR.
install_lf() {
    [[ "$family" == fedora ]] || return 0
    local architecture
    case "$(uname -m)" in
        x86_64) architecture=amd64 ;;
        aarch64|arm64) architecture=arm64 ;;
        *) die 'lf binary installation on Fedora supports x86_64 and aarch64 only.' ;;
    esac
    printf 'Install lf r42 into ~/.local/bin\n'
    if ((dry)); then return; fi
    fetch_script "https://github.com/gokcehan/lf/releases/download/r42/lf-linux-$architecture.tar.gz" "$work_dir/lf.tar.gz"
    mkdir -p "$work_dir/lf-release"
    tar -xzf "$work_dir/lf.tar.gz" -C "$work_dir/lf-release" lf
    run install -Dm755 "$work_dir/lf-release/lf" "$HOME/.local/bin/lf"
    run lf -version
}

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
    if [[ ! -e "$runtime" ]]; then
        fetch_script "https://github.com/neovim/neovim/releases/download/v0.11.5/$archive.tar.gz" "$work_dir/neovim.tar.gz"
        mkdir -p "$work_dir/neovim-release"
        tar -xzf "$work_dir/neovim.tar.gz" -C "$work_dir/neovim-release"
        neovim_compatible "$work_dir/neovim-release/$archive/bin/nvim" || die 'Downloaded Neovim cannot run or does not meet the required version.'
        mkdir -p "$directory"
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
