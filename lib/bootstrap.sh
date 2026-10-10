#!/usr/bin/env bash
# Explicit loading order: common helpers, registries, planning, installers, UI,
# and command handlers. Sourcing defines functions; execution starts in the CLI.
# ROOT is supplied by the executable so calls work from any working directory.
for module in \
    core platform cli/catalog cli/help \
    cli/arguments cli/runtime packages/detection packages/dependencies \
    config/paths config/selection config/links config/profiles \
    config/fish packages/plan packages/manager packages/vendors \
    installers/node installers/starship installers/tmux installers/tree-sitter \
    installers/lf installers/neovim installers/docker installers/aws \
    installers/zsh ui/menu setup/wizard setup/plan \
    setup/login-shell setup/execute commands/packages commands/doctor \
    commands/aliases cli/dispatch; do
    source "$ROOT/lib/$module.sh"
done
unset module
