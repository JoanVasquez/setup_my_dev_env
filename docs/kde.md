# KDE Plasma

[Project home](../README.md)

## Compatibility

The managed Zsh, Starship, Neovim, tmux, and Kitty configurations work in a KDE
Plasma Wayland session without desktop-specific environment overrides. Clipboard
helpers prefer `wl-copy` whenever `WAYLAND_DISPLAY` is present, and tmux uses the
same Wayland clipboard path. Plasma controls Qt scaling, cursor, theme, and portal
selection; this project deliberately does not force `QT_QPA_PLATFORM`, scaling
variables, or `GTK_USE_PORTAL` globally.

Kitty's Quickshell palette file is optional. If the file remains available after
switching desktops, Kitty and Neovim retain that palette; if it is absent, their
built-in themes remain usable. No Hyprland process or environment variable is
required by the shell, prompt, editor, or tmux configuration.

## Install or preview

On CachyOS/Arch, the KDE tool resolves to `plasma-meta`, `konsole`, `dolphin`, and
`ark`. The Plasma meta-package supplies the KDE Wayland session and KDE desktop
portal. Debian-family and Fedora-family mappings use their native Plasma packages.

```bash
# Review only the Plasma packages and KDE integration.
./bin/dotfiles setup --shell none --terminal none --tools kde --dry-run

# Install Plasma and link the Konsole profile. Existing managed configs remain linked.
./bin/dotfiles setup --shell none --terminal none --tools kde --yes

# Apply only the Konsole profile when Plasma is installed separately.
./bin/dotfiles setup --shell none --terminal konsole --tools none \
  --no-packages --yes
```

The interactive wizard also offers **KDE Plasma desktop + core applications** in
its optional-tools checklist.

## Session and portal behavior

The installer does not enable, disable, or replace a display manager. This keeps
an existing Hyprland login path intact and avoids choosing a system-wide login
policy on your behalf. After installing Plasma, use your existing login manager's
session chooser to select **Plasma (Wayland)**. If no graphical login manager is
configured, enable the one you intentionally choose outside this project.

Hyprland's and KDE's portal backends may be installed together. The portal service
selects the desktop backend from the active session, so do not export a global
`XDG_CURRENT_DESKTOP` override. Log out of Hyprland before starting a full Plasma
session; do not nest one desktop inside the other.

The managed Konsole assets live in `$XDG_DATA_HOME/konsole`. Choose **Dev
Environment** from Konsole's profile menu. The project leaves `konsolerc` and KDE's
other mutable configuration files user-owned.

## First-login checklist

1. Select **Plasma (Wayland)** at login.
2. Open System Settings and confirm display scaling, keyboard layout, audio, and
   default applications.
3. Open Konsole and select the **Dev Environment** profile.
4. Run `./bin/dotfiles doctor`; it should report desktop `kde`, healthy KDE tools,
   and linked Konsole assets.
5. Open Kitty, tmux, and Neovim to confirm font glyphs and clipboard access.

KDE shortcut assignments, panels/widgets, wallpaper, KWallet policy, monitor
layout, and display-manager configuration remain intentionally local. These files
change frequently and often contain machine-specific identifiers.
