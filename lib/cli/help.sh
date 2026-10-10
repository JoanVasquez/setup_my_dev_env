#!/usr/bin/env bash
# Print the public commands and flags using the catalog for selection lists.
usage() {
    local tools_csv components_csv help_text
    tools_csv="$(IFS=,; printf '%s' "${tools_available[*]}")"
    components_csv="$(IFS=,; printf '%s' "${components[*]}")"
    help_text="$(cat <<'HELP'
Usage: ./bin/dotfiles [setup|install|packages|doctor|aliases|unlink] [options]
No command starts the interactive setup wizard.

setup     Choose shell, terminal, tools; install packages and link configs.
  --shell auto|bash|fish|zsh|none
          Setup installs the selected shell and makes it your default login shell.
  --terminal auto|kitty|konsole|alacritty|ghostty|none
  --tools @TOOLS@
          Use --tools none for no optional tools; shell/profile requirements still install.
          The wizard offers a tool checklist; required dependencies install automatically.
  --no-packages      Only link selected configs.
  --keep-shell      Configure the chosen shell without changing your login shell.
  --system-zshenv   Append the XDG bootstrap to the distro global zshenv (Zsh setup only).
  --login-shell     Also change the login shell in a --no-packages setup.
  --enable-docker   Enable and start Docker's service.
  --docker-group    Join the Docker group (root-level access).

install / unlink
  --components @COMPONENTS@
  --all             Select every configuration.
  Default: configs for installed programs and the login shell.

packages            Install tools and selected shell/terminal, without linking.
  Uses --shell, --terminal, --tools and Docker options; no shell/terminal by default.
  --extra           Include all terminal packages and clipboard tools.

doctor              Show platform, configs and installed tools.
aliases             List this checkout's configured aliases for all installed shells.
  --shell all|auto|bash|fish|zsh  Limit alias listing (default: all).
                      In a loaded shell, `aliases` lists live/session aliases.

Shared options: --dry-run (preview without changes), --yes (unattended).
Existing configs are moved into timestamped backups before symlinking.
Run as your normal user: privilege escalation is only used for system changes.
HELP
)"
    help_text="${help_text//@TOOLS@/$tools_csv}"
    printf '%s\n' "${help_text//@COMPONENTS@/$components_csv}"
}
