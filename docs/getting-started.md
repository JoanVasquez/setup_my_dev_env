# Getting Started

[Project home](../README.md)

## Requirements and supported systems

The entrypoint requires Bash 4.4 or newer and uses arrays, `mapfile`, and namerefs. Use standard Linux utilities such as `readlink`, `mkdir`, `mv`, `ln`, `date`, and `mktemp`. System installation also needs working distro repositories, network access for downloads, and permission to use `sudo`.

| Family | Recognized metadata | Package manager |
| --- | --- | --- |
| Arch | `arch`, `manjaro`, `cachyos`, `endeavouros`, or an exact matching `ID_LIKE` token | `pacman` |
| Debian | `debian`, `ubuntu`, `linuxmint`, `pop`, or an exact matching `ID_LIKE` token | `apt-get` |
| Fedora | `fedora`, `nobara`, `ultramarine`, or an exact matching `ID_LIKE` token | `dnf` (DNF4/DNF5) |
| Other | No supported ID/ancestry match | Config linking only |

Detection reads `/etc/os-release`, checks `ID` first, then the ancestry tokens in `ID_LIKE`. It does not classify a distro merely because its name contains the letters `arch`, `debian`, or `fedora`.

Fedora Atomic/OSTree desktops (such as Silverblue and Kinoite) support config-only linking. Host package installation needs their image-based workflow; this installer stops before attempting DNF host changes. Traditional Fedora Workstation/Server and DNF-based containers use the Fedora backend.

On another distribution, these remain available:

```bash
./bin/dotfiles install --components bash,tmux,starship --yes
./bin/dotfiles setup --shell zsh --terminal none --tools none --no-packages --yes
```

The Zsh fzf module recognizes some Homebrew file locations, but the package installer supports the Linux families above. That module does not make this a macOS installation framework.

## Interactive setup

The wizard proceeds through:

1. Platform, shell, and terminal detection.
2. Shell choice: `bash`, `fish`, `zsh`, or `none`.
3. Terminal choice: `kitty`, `konsole`, `alacritty`, `ghostty`, or `none`.
4. One checklist for independent optional tools.
5. Whether to install the selected tools and required dependencies.
6. Docker service/group questions if Docker was selected and installation is enabled.
7. A resolved plan and final confirmation.

Use **Up/Down** (or `j`/`k`) to highlight an option and **Enter** to select it. Number keys also highlight an option; `q` cancels setup. Shell/terminal menus start on the detected default. In the tool checklist, **Space** toggles the focused tool, **a** selects all, **n** clears all, and **Enter** accepts the selection. All optional tools start unchecked; the focus line shows the current checkbox and selection count. Yes/no menus, including the final confirmation, default to **no**; `y`/`n` followed by Enter also works. These menus need no extra package.

Dependencies already implied by the chosen shell are omitted from the tool checklist. Checklist rows stay stable while selecting optional tools; their additional dependencies are resolved in the final plan. For example, choosing Zsh does not ask you separately to select Starship, fzf, nvm, eza, or its plugins. Choosing tmux automatically includes its fzf/plugin requirements. Plugin-manager internals are not standalone wizard questions.

Selecting an already-installed application can still apply its bundled configuration. An installed shell does not bypass checking the rest of that shell's required profile tools.

The plan distinguishes:

- **Configs:** repository templates that will be linked.
- **Optional tools:** your additional selections.
- **Automatic requirements:** tools implied by those selections.
- **Missing tools / distro packages:** the work remaining after installed-tool probes.
- **System changes:** login-shell activation, optional global Zsh bootstrap, and Docker service/group settings.

In `--yes` or `--dry-run` mode the wizard does not ask questions. Explicit selections are useful for reproducible automation.

## Common installation recipes

```bash
# Complete Zsh profile, no additional apps; set Zsh default.
./bin/dotfiles setup --shell zsh --terminal none --tools none --yes

# Same profile, retaining your account's current default shell.
./bin/dotfiles setup --shell zsh --terminal none --tools none --keep-shell --yes

# Zsh profile + Kitty + AWS + Codex.
./bin/dotfiles setup --shell zsh --terminal kitty --tools aws,codex --yes

# Complete Fish profile + Java + tmux.
./bin/dotfiles setup --shell fish --terminal konsole --tools java,tmux --yes

# Bash profile + Docker, explicitly starting the daemon.
./bin/dotfiles setup --shell bash --terminal none --tools docker --enable-docker --yes

# Add the requested system-level Zsh XDG bootstrap.
./bin/dotfiles setup --shell zsh --terminal none --tools none --system-zshenv --yes

# Tools only: no shell profile, terminal selection, config links, or chsh.
./bin/dotfiles packages --tools java --yes
./bin/dotfiles packages --tools nvm --yes
./bin/dotfiles packages --tools docker,aws,codex --yes

# Install a shell's packages/requirements without linking its configs.
./bin/dotfiles packages --shell fish --tools none --yes

# Apply configuration only.
./bin/dotfiles install --components zsh,tmux,starship --yes
./bin/dotfiles setup --shell fish --terminal none --tools none --no-packages --yes

# Explicitly activate an already-installed shell in config-only mode.
./bin/dotfiles setup --shell zsh --terminal none --tools none \
  --no-packages --login-shell --yes

# Preview before broad linking/removal.
./bin/dotfiles install --all --dry-run
./bin/dotfiles unlink --components zsh,tmux --dry-run
```

To preview an installation recipe, replace `--yes` with `--dry-run`.
