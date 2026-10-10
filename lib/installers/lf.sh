#!/usr/bin/env bash
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

