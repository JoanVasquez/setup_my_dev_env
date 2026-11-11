# Dev Environment

A production-minded Linux workstation setup for shells, editors, terminals, prompts, and development tooling. It detects Debian/Ubuntu, Arch-family, and Fedora-family distributions, resolves dependencies, backs up existing configuration, and links this checkout into the locations applications use.

The default experience mirrors the maintained workstation profile: **Zsh + Starship + Kitty + tmux + Neovim**, with a consistent Catppuccin-inspired terminal experience and portable XDG paths. Bash, Fish, Alacritty, Ghostty, and Konsole remain supported alternatives. An optional KDE Plasma profile installs a practical desktop baseline without replacing or reconfiguring an existing desktop session.

## Why this project

- Safe by default: dry runs, explicit confirmation, timestamped backups, and ownership-aware unlinking.
- Repeatable: healthy tools and valid plugin checkouts are skipped; incomplete installations are repaired.
- Portable: CachyOS/Arch, Debian/Ubuntu, and Fedora use one dependency graph with distro-specific packages.
- Testable: syntax validation and 100+ offline behavior tests cover planning, linking, shells, plugins, and menus.
- Polished: the interactive wizard provides keyboard navigation, live selection state, and a concrete review plan before any change.

**Choosing a shell selects its complete configuration profile.** Its required tools and plugins are automatic; the wizard asks only about additional applications. Failed runtime probes trigger repair even when the package database says a tool is installed.

## Quick start

Keep the checkout in a permanent location and run commands as your normal user. The installer invokes `sudo` for system changes; do not launch the entire installer with `sudo`, which would target root's home/configuration.

```bash
# Inspect the current platform, managed files, and installed tools.
./bin/dotfiles doctor

# Start the interactive wizard.
./bin/dotfiles
# Equivalent:
./bin/dotfiles setup
```

Preview a complete Zsh profile with no extra applications:

```bash
./bin/dotfiles setup --shell zsh --terminal none --tools none --dry-run
```

Apply the same selection:

```bash
./bin/dotfiles setup --shell zsh --terminal none --tools none --yes
```

This installs Zsh's missing requirements, applies the profile, and makes Zsh your default login shell. Log out and back in afterward. Your existing terminal process continues running its current shell.

For Fish instead:

```bash
./bin/dotfiles setup --shell fish --terminal none --tools none --yes
```

For a standalone tool, use `packages`:

```bash
# Only the JDK and the package manager's own system-library requirements.
./bin/dotfiles packages --tools java --yes
```

**`--tools none` and `--no-packages` are different:** the first excludes additional applications while retaining automatic profile requirements; the second disables package/vendor installation. The `install` command also provides config-only linking.

## Guides

- [Getting started](docs/getting-started.md): supported systems, interactive checklist, and installation recipes.
- [Command reference](docs/cli.md): commands, flags, components, and unattended defaults.
- [Packages and dependencies](docs/packages.md): profile requirements, detection, and distro mappings.
- [Shells and development tools](docs/shells.md): Bash/Fish/Zsh, aliases, Node, Docker, Java, and AWS.
- [Editors and terminals](docs/applications.md): Neovim, tmux, prompts, and terminal profiles.
- [KDE Plasma](docs/kde.md): installation profile, Wayland portals, Konsole, coexistence, and first login.
- [Maintenance](docs/maintenance.md): managed paths, backups, removal, repair, and troubleshooting.
- [Contributing](docs/contributing.md): architecture, extension points, and offline tests.
- [Upstream references](docs/references.md).

## Development

Run `./bin/check` for Bash/Zsh/Fish/Lua syntax checks and the offline regression
suite. Tests use temporary homes and mocked package/download commands.

The installer is organized by responsibility under `lib/`; application templates
live in `config/`, shell startup/shared helpers in `shell/`, and package manifests
in `packages/`. Existing config paths are preserved for installed symlinks.
