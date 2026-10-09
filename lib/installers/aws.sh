#!/usr/bin/env bash
# Install AWS CLI v2 for the current user using AWS's official installer.
# The installer handles the archive/signature steps; this wrapper supplies its bin location.
install_aws() {
    # Preserve any existing aws executable, including CLI v1; this is not an upgrade command.
    if tool_installed aws; then printf 'skip: aws already installed\n'; return; fi
    # The upstream Linux binaries cover these two 64-bit CPU architectures.
    case "$(uname -m)" in
        x86_64|aarch64) : ;;
        *) die 'The AWS CLI installer supports Linux x86_64 and aarch64.' ;;
    esac
    printf 'Install AWS CLI v2 for your user into ~/.local/bin\n'
    # Exit before fetching or executing anything during a preview.
    if ((dry)); then return; fi
    fetch_script https://awscli.amazonaws.com/v2/install.sh "$work_dir/aws-install.sh"
    XDG_BIN_HOME="$HOME/.local/bin" bash "$work_dir/aws-install.sh"
    # Verify the newly installed executable directly, regardless of the caller's PATH.
    "$HOME/.local/bin/aws" --version
}
