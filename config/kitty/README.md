# Kitty configuration

`kitty.conf` includes the local `Catppuccin-Mocha.conf` theme with your darker
`#11111B` background, the complete ANSI palette, and matching cursor, borders,
tabs, selection and marks. The setup installer links this whole directory under
`$XDG_CONFIG_HOME/kitty` (default `~/.config/kitty`).

The profile uses Maple Mono NF at 12 pt, automatic bold/italic faces, cursor
trails, 14 px window padding, and subtle 96% background opacity. Install
**Maple Mono NF** separately; Kitty falls back to another font if it is absent.
Use a recent Kitty version supporting the font specification and cursor trails.
Transparency requires desktop compositor support.

When available, `kitty.conf` also loads
`$XDG_CONFIG_HOME/quickshell/theme/kitty-current.conf` through a relative
`globinclude` so a desktop palette can override colors. The file is optional,
and the XDG-relative path keeps this repository portable between users and machines.

Selection copies automatically and trims trailing spaces smartly. Ctrl-C copies
when text is selected and otherwise sends an interrupt. Ctrl-Equal/Minus adjust
the font size in all windows; Ctrl-0 resets it.

Restart Kitty to apply the whole profile, especially the initial transparency
setting. Ctrl-Shift-F5 reloads settings that can change while Kitty is running.
See the [Kitty configuration reference](https://sw.kovidgoyal.net/kitty/conf/).
