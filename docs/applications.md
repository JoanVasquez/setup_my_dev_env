# Applications

[Project home](../README.md)

## Neovim

The project includes your full system Lua setup rather than a minimal starter:

- `init.lua` and `lua/config` modules for options, keybindings, filetypes, Python selection, LSP helpers, and buffer handling.
- `lua/plugins` specifications for Lazy-managed plugins.
- `lazy-lock.json`, StyLua settings, and the YAML ftplugin.
- Tokyo Night theme, lualine, bufferline, Neo-tree, Telescope, completion, formatting, linting, Treesitter, Mason, and local Minuet/Ollama completion.

The configuration requires **Neovim 0.11.3+**. Setup checks the actual version. A missing editor is first requested through the distro package manager. If that package or an existing executable is too old, setup installs the [upstream v0.11.5 runtime](https://github.com/neovim/neovim/releases/tag/v0.11.5) under `$XDG_DATA_HOME/dotfiles/neovim/v0.11.5` and links `~/.local/bin/nvim`. The distro package remains installed. Any previous user launcher is backed up; compatible editors are skipped. The fallback covers Linux x86_64/aarch64 and verifies the downloaded binary can run before activating it.

Automatic dependency resolution supplies system runtimes, build tools, search tools, clipboard helpers and archive utilities. Normal setup then provisions missing editor plugins, Mason tools and parsers. For a config-only installation, provision these explicitly:

```vim
:Lazy restore
:MasonToolsInstallSync
:TreesitterInstall!
```

Use `:checkhealth`, `:Mason`, `:ConformInfo`, and `:checkhealth vim.lsp` to inspect the setup. Node/npm, Python with venv support, Go, a C compiler, tree-sitter CLI, and an appropriate JDK are required by particular language/build workflows. Selecting Neovim installs these requirements even when Neovim itself is already present. Arch/Fedora use their Tree-sitter CLI packages; Debian/Ubuntu uses the upstream v0.26.11 binary in `~/.local/bin` (x86_64/aarch64).

The configuration covers Python, JavaScript/TypeScript/React, web files, Django templates, Bash, Docker/Compose, SQL, Java, XML, JSON, and YAML. It recognizes active Python environments or project `.venv`/`venv`; `:PythonInterpreter /path/to/bin/python` changes the running session's interpreter. Project dependencies/configurations still supply type information, ESLint/Tailwind rules, SQL connections, and formatter settings.

The local Minuet setup uses Ollama at `127.0.0.1:11434` with `qwen2.5-coder:7b`. The installer does not install/start Ollama or download that model. Java uses a separate JDTLS workspace per project; dedicated Java debugging/test and Spring property extensions are not bundled. A Jupyter notebook UI is not part of this setup.

Leader is Space. Common keys:

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle file explorer |
| `<leader>ff`, `<leader>fg`, `<leader>fb`, `<leader>fr` | Files, text search, buffers, recent files |
| Tab / Shift-Tab | Next/previous buffer |
| `<leader>x` / `<leader>a` | Close current/all saved editing buffers |
| `<leader>wv`, `<leader>ws`, `<leader>wd`, `<leader>w=` | Split, close, equalize windows |
| `<leader>cf` | Format |
| `<leader>sn` | Save once without formatting |
| `<leader>at` | Toggle inline AI suggestions |

Generated/special/large buffers are excluded from several automatic operations. Persistent undo, swap recovery, and temporary write backups use Neovim's normal state directories. The detailed application README explains formatting, completion, diagnostics, environment selection, and all shortcuts.

There is no separate `dotfiles/nvim.lua` override hook in this imported entrypoint; customize its existing modules.

## Tmux

[config/tmux/tmux.conf](../config/tmux/tmux.conf) and the session picker preserve your imported system settings. Setup links both `$XDG_CONFIG_HOME/tmux` and `~/.tmux.conf`, since your reload binding uses the latter.

- Prefix: **Ctrl-Space**.
- Prefix + `R`: reload `~/.tmux.conf`.
- Prefix + `r`: popup fuzzy session picker; built-in tree fallback when fzf is missing.
- Splits/windows open in the active pane's directory.
- Vim-style pane navigation, mouse support, vi copy mode, true-color handling, and Catppuccin Mocha styling are retained.
- Desktop clipboard commands use available X11/Wayland utilities, alongside the configured terminal clipboard behavior.
- Resurrect capture and 15-minute continuum save/restore settings are retained.

Selecting tmux automatically brings in fzf, Git, and the plugin bundle listed in [packages/tmux-plugins.tsv](../packages/tmux-plugins.tsv):

```text
tmux-plugins/tpm
tmux-plugins/tmux-resurrect
tmux-plugins/tmux-continuum
```

Missing checkouts are cloned into `~/.tmux/plugins`; valid existing checkouts are preserved. Prefix + `I` remains available for TPM maintenance. Setup does not replace/start your running tmux server; open/reload it to activate the configuration.

The popup and theme helpers honor `$XDG_CONFIG_HOME` (default `~/.config`), including paths with spaces. Reload still uses the managed `~/.tmux.conf` startup link.

The status bar follows your Mocha reference: centered icon-numbered windows, mode/session/directory indicators, session dots, uptime, clock/date, and pane labels. It uses native tmux settings and local scripts; FZF, Resurrect, Continuum and existing shortcuts remain enabled. See [config/tmux/README.md](../config/tmux/README.md).

## Starship and terminals

Starship's shared template is [config/starship/starship.toml](../config/starship/starship.toml), imported from your system. The Dracula palette, powerline separators, OS/user/directory/Git/runtime/job/time segments, command duration, and input symbols are retained.

The global configuration links to `$XDG_CONFIG_HOME/starship.toml`; Zsh also receives `$ZDOTDIR/starship.toml` pointing to the same repository file. Editing that template affects both. Starship does not require installing every language displayed in its module definitions.

| Terminal | Managed configuration |
| --- | --- |
| Kitty | Catppuccin Mocha, Maple Mono NF, cursor trails, margins, transparency, selection/copy and font-size shortcuts |
| Alacritty | TOML font, padding, opacity, and color configuration |
| Ghostty | Font, padding, transparency, and Tokyonight Moon colors |
| Konsole | `Moon.colorscheme` only, under the XDG data directory |

Terminal selection installs/configures the chosen terminal; it does not change desktop default-terminal associations. Konsole needs you to select Moon in its profile settings. Its whole preferences directory is not replaced.

Kitty uses your Maple Mono NF 12 pt profile and includes its local Mocha theme. Install that font separately and restart Kitty to apply the complete profile; see [config/kitty/README.md](../config/kitty/README.md). Other terminals also need an installed Nerd Font for icon glyphs. Font installation is not performed by this script.
