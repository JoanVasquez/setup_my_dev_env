#!/usr/bin/env bash
# Manage nvm and its default Node as one selection; keep an existing LTS default.
install_nvm() {
    if nvm_ready; then printf 'skip: nvm and Node LTS already installed\n'; return; fi
    if uses_native_fish_nvm; then
        install_fish_nvm
        return
    fi
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # An installed manager with missing/non-LTS Node needs only the Node steps below.
    # A nonempty entrypoint can still be truncated or fail to define nvm.
    if ! NVM_DIR="$NVM_DIR" bash -c 'source "$NVM_DIR/nvm.sh" --no-use >/dev/null 2>&1 && declare -F nvm >/dev/null' 2>/dev/null; then
        local version="${NVM_VERSION:-v0.40.8}"
        [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'NVM_VERSION must be a release tag like v0.40.8'
        printf 'Install nvm %s into %s (without modifying shell profiles)\n' "$version" "$NVM_DIR"
        if ((!dry)); then
            mkdir -p -- "$NVM_DIR"
            fetch_script "https://raw.githubusercontent.com/nvm-sh/nvm/$version/install.sh" "$work_dir/nvm-install.sh"
            if [[ -e "$NVM_DIR/nvm.sh" || -L "$NVM_DIR/nvm.sh" ]]; then
                mkdir -p "$backup_dir/node/nvm-sh"
                mv -- "$NVM_DIR/nvm.sh" "$backup_dir/node/nvm-sh/nvm.sh"
            fi
            # Our shell templates already load nvm; prevent upstream from editing rc files.
            PROFILE=/dev/null METHOD=script bash "$work_dir/nvm-install.sh"
        fi
    fi
    printf 'Install Node LTS and set the nvm default alias\n'
    if ((dry)); then return; fi
    backup_broken_node_versions "$NVM_DIR/versions/node" nvm-sh
    # nvm must be sourced to define its function. A child shell isolates Node/PATH changes.
    # The quoted lts/* alias is literal; nvm resolves it when choosing the default.
    bash -c 'set -e; source "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default "lts/*"; nvm use default'
}
# Use the already-bundled nvm.fish functions without loading the user's prompt,
# distro setup or aliases. Installing LTS creates nvm.fish's local index and data.
install_fish_nvm() {
    printf 'Install Node LTS using the imported native nvm.fish plugin\n'
    if ((dry)); then return; fi
    backup_broken_node_versions "$(fish_nvm_data)" nvm-fish
    run fish --no-config -c '
        set -g fish_function_path "$argv[1]/config/fish/functions" $fish_function_path
        set -g nvm_data "$argv[2]"
        source "$argv[1]/config/fish/conf.d/nvm.fish"
        nvm install lts
    ' -- "$ROOT" "$(fish_nvm_data)"
}

# Native managers often skip a version when its directory exists. Preserve
# incomplete distributions before asking the manager to download them again.
backup_broken_node_versions() {
    local directory="$1" manager="$2" version archive
    for version in "$directory"/v*; do
        [[ -d "$version" ]] || continue
        if [[ -x "$version/bin/node" ]] && "$version/bin/node" --version >/dev/null 2>&1; then continue; fi
        archive="$backup_dir/node/$manager/${version##*/}"
        mkdir -p -- "$(dirname "$archive")"
        mv -- "$version" "$archive"
        printf 'backup: %s\n' "$archive"
    done
}
# Install Codex into nvm's default Node prefix with npm, without sudo.
# The orchestrator ensures the Node selection is handled first.
install_codex() {
    if codex_present; then printf 'skip: codex already installed\n'; return; fi
    if uses_native_fish_nvm; then
        printf 'Install Codex CLI in the native nvm.fish LTS environment\n'
        if ((dry)); then return; fi
        local node_bin
        node_bin="$(fish_lts_bin)" || die 'Codex requires Node LTS; include nvm in --tools.'
        PATH="$node_bin:$PATH" run npm install -g @openai/codex
        PATH="$node_bin:$PATH" run codex --version
        return
    fi
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    printf 'Install Codex CLI in the nvm default Node environment\n'
    if ((dry)); then return; fi
    [[ -s "$NVM_DIR/nvm.sh" ]] || die 'Codex requires nvm; include nvm in --tools.'
    bash -c 'set -e; source "$NVM_DIR/nvm.sh"; nvm use default; npm install -g @openai/codex; codex --version'
}
