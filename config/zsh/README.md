# Modular XDG Zsh profile

This adapts your example and Fish aliases/functions into a Zsh-native profile.
It preserves the imported Neovim, Fish, tmux and Starship settings.

## Install

Preview the default tool set and profile:

```bash
./bin/dotfiles setup --shell zsh --terminal none --dry-run
./bin/dotfiles setup --shell zsh --terminal none --yes
```

Normal setup installs missing tools and makes Zsh your default login shell.
Zsh automatically brings in Git, Neovim, Starship, zoxide, fzf, fd, bat,
ripgrep, eza, lf, nvm/Node LTS, clipboard helpers and the four Zsh plugins.
These requirements are not individual wizard questions. `--tools` controls
additional optional applications; `--tools none` still installs the complete
profile. `--no-packages` or `install --components zsh` provides config-only
linking. Already-installed tools and plugins are skipped.

For the complete profile without additional apps:

```bash
./bin/dotfiles setup --shell zsh --terminal none \
  --tools none --yes
```

Add `--keep-shell` to retain your current login shell. Log out/back in after
changing the default. Use `install --components zsh --yes` for config linking
without package installation or a default-shell change.

## Startup and directories

Zsh first reads its global zshenv, then the user `.zshenv`, then the interactive
`.zshrc`. The global path depends on the Zsh build. This follows the
[Zsh startup-file documentation](https://zsh.sourceforge.io/Doc/Release/Files.html).

The installer links `~/.zshenv` to a small user-level bridge that sets
`ZDOTDIR=${XDG_CONFIG_HOME:-$HOME/.config}/zsh` and loads that directory's `.zshenv`.
This makes XDG startup work without editing system files. A compatibility
`~/.zshrc` bridge supports existing links/manual sourcing.

Your requested system-level bootstrap is available explicitly:

```bash
./bin/dotfiles setup --shell zsh --system-zshenv --dry-run
./bin/dotfiles setup --shell zsh --system-zshenv --yes
```

This appends `system-zshenv.zsh` to `/etc/zsh/zshenv`, preserving distro content
and backing up the original to the run's `backups/.../system/zshenv`. A marker
prevents duplicate appends. For a build using another global location, set
`ZSH_GLOBAL_ENV_FILE=/etc/zshenv`. The bootstrap enables the XDG directory only
when it exists and startup-file reading is enabled.

`unlink` removes managed user links, not the optional global fragment, your
history, plugins or backups. Remove that marked system fragment or restore its
backup separately if you want to reverse the system-level setup.

| Location | Purpose |
| --- | --- |
| `$XDG_CONFIG_HOME/zsh/` | Linked profile files and your optional `local.zsh` |
| `$XDG_STATE_HOME/zsh/history` | Persistent shared shell history |
| `$XDG_CACHE_HOME/zsh/zcompdump` | Completion metadata cache |
| `$XDG_DATA_HOME/zsh/plugins/` | Downloaded plugin checkouts |
| `~/.nvm/` | nvm-sh and Node versions for Bash/Zsh |

Unset XDG variables receive the standard defaults; existing overrides are
respected. The installer creates state/cache directories with `mkdir -p`.
Files are linked individually, so your existing `local.zsh` and unrelated
files in the Zsh directory are preserved. Replaced files get normal backups.

## Modules

- `.zshenv`: XDG directories, Neovim editor defaults, personal PATH, bat/batcat
  man pager, terminal-aware `GPG_TTY`, and the shared Starship config path.
- `.zshrc`: history options, completion cache/styles, optional lf icons and
  zoxide integration, then module loading in order.
- `node.zsh`: loads nvm-sh if installed; Fish keeps its separate native nvm.
- `fzf.zsh`: file discovery with fd/fdfind/find, previews with bat/batcat/head,
  portable fzf initialization (including readonly ZLE option compatibility) and a Ctrl-F widget that quotes filenames.
- `aliases.zsh`: eza listings, Git, Docker/Compose, npm, tmux, editor and distro
  package aliases adapted from your Fish names.
- `functions.zsh`: smart tmux attachment, `dbf`, Git branch selection, process
  selection, Git-root navigation, and lf working-directory integration.
- `bindings.zsh`: vi cursor configuration and custom keys reapplied after
  zsh-vi-mode initializes. Native vi bindings work without the plugin.
- `plugins.zsh` / `plugins.list`: loads already-installed plugin entrypoints
  and provides an explicit `zplugin-update` function.
- `prompt.zsh`: Starship, virtualenv prompt suppression and function nesting limit.
- `starship.toml`: linked to the same project config used by Fish.
- `local.zsh`: optional user-owned overrides, loaded last; never replaced by setup.

## Aliases and keys

The Fish names are retained where practical: `g`, `gs`, `gaa`, `gco`, `gsw`,
`d`, `dc`, `dps`, `dcr`, `dcuro`, `dcdv`, `ni`, `nt`, `nrd`, `t`, `ta`, `trs`,
`tsave`, `trestore`, `cfish`, `cnvim`, and the systemctl helpers.
`czsh` opens the XDG rc file. `dotfiles` runs this checkout's installer.

Two corrected aliases are `dcud='docker compose up -d'` and
`nb='npm run build'`. `ls`/`ll`/`la`/`tree` use eza when present. `cat` uses
bat/batcat, but functions needing machine-readable content invoke `command cat`.
Distro aliases call APT on Debian derivatives and pacman on Arch derivatives.
`cd` keeps its native behavior; use `z` for zoxide ranking.

Ctrl-F inserts a non-hidden file selection, quoting spaces/metacharacters.
Ctrl-Left/Right move by word. Up/Down use substring history when its plugin is
available and regular history otherwise. Ctrl-Backslash toggles autosuggestions
when that widget is installed. fzf's usual Ctrl-T/Alt-C/Ctrl-R keys are restored
after vi-mode initialization resets the keymap.

## Plugin lifecycle

The `zsh-plugins` tool clones:

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)

```bash
./bin/dotfiles packages --shell none --terminal none --tools zsh-plugins --yes
```

Cloning occurs in the install phase, never at shell startup. Valid existing
plugin entrypoints are skipped. An incomplete directory is reported for repair
rather than overwritten. `ZPLUGINDIR` can override the plugin directory if you
use the same setting for installation and shell startup.

Run `zplugin-update` explicitly to pull fast-forward updates, then open a new
shell. Syntax highlighting loads last, and vi cursor constants are applied
through the plugin's `zvm_config` hook. The post-init hook follows the
[vi-mode integration guidance](https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands).
