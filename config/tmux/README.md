# Imported tmux configuration

`tmux.conf` is an exact copy of your system's `~/.tmux.conf`; `session-picker.sh`
is copied from `~/.config/tmux/session-picker.sh`. The installer links both the
support directory and the `~/.tmux.conf` startup file, backing up existing targets.
Your reload binding (`Ctrl-Space`, then `R`) sources `~/.tmux.conf`.

The prefix is `Ctrl-Space`; prefix + `r` opens your session picker. TPM,
tmux-resurrect and tmux-continuum retain your system settings. Selecting tmux automatically includes fzf, Git, the manager and both persistence
plugins. Missing checkouts are cloned during setup; existing ones are skipped.
Prefix + `I` remains available for plugin maintenance.
