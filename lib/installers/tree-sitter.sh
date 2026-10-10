#!/usr/bin/env bash
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

