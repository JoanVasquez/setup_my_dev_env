# Imported tmux configuration

`tmux.conf` adapts your system's `~/.tmux.conf`; `session-picker.sh`
is copied from `$XDG_CONFIG_HOME/tmux/session-picker.sh` (defaulting to `~/.config`). The installer links both the
support directory and the `~/.tmux.conf` startup file, backing up existing targets.
The popup resolves that XDG path at runtime, including paths with spaces.
Your reload binding (`Ctrl-Space`, then `R`) sources `~/.tmux.conf`.

The prefix is `Ctrl-Space`; prefix + `r` opens your session picker. TPM,
tmux-resurrect and tmux-continuum retain your system settings. Selecting tmux automatically includes fzf, Git, the manager and both persistence
plugins. Missing checkouts are cloned during setup; existing ones are skipped.
Prefix + `I` remains available for plugin maintenance.
