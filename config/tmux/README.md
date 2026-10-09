# Tmux configuration

The status bar uses Catppuccin Mocha colors on the terminal's background, with
centered window tabs, Nerd Font number icons, a peach active window, pane labels,
and PREFIX/COPY/NORMAL indicators. The left side shows the session and current
directory; the right shows session dots, Linux uptime, time, and date. The active
session is a ghost; other sessions are dots. Window indices above nine use digits.
Use a Nerd Font in your terminal to display the icons.

Styling is native tmux plus local scripts, so it works before plugins are installed.
The installer links the support directory and `~/.tmux.conf`, backing up existing
targets. Script paths honor `$XDG_CONFIG_HOME` (default `~/.config`) and spaces.

Your prefix remains **Ctrl-Space**:

- Prefix + `r`: FZF session picker; falls back to tmux's session tree without fzf.
- Prefix + `R`: reload configuration.
- Prefix + `h/j/k/l`: navigate panes; `v/s` and `|/-` split panes.
- Prefix + `I`: TPM plugin maintenance.
- Prefix + `Ctrl-s` / `Ctrl-r`: Resurrect save / restore when installed.

TPM, tmux-resurrect and tmux-continuum keep their existing install locations and
settings. Continuum saves every 15 minutes and restores on startup; Resurrect
captures scrollback and restores Neovim sessions. Theme settings load before TPM,
so Continuum can append its save hook without being overwritten by the theme.
Selecting tmux automatically includes fzf, Git, and the three declared plugins.
