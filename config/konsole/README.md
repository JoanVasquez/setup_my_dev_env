Konsole schemes and profiles are installed under `$XDG_DATA_HOME/konsole`
(normally `~/.local/share/konsole`), not `~/.config/konsole`.

The installer links `Moon.colorscheme` and `Dev Environment.profile`. The profile
uses Maple Mono NF 12 pt, the Moon palette, the account login shell, and unlimited
scrollback. Select **Dev Environment** in Konsole's profile menu or make it the
default from Konsole settings.

The project deliberately does not symlink the whole `~/.config/konsole` directory
or manage `konsolerc`: KDE stores unrelated dynamic preferences there.
