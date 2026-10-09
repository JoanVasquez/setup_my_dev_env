# Modular Linux dotfiles

A modular installer for your Linux shell, editor, terminal, prompt, and development tools. It detects Debian/Ubuntu or Arch-family distributions, lets you choose Bash, Fish, or Zsh, installs missing requirements, backs up existing configuration, and links this checkout into the locations applications use.

**Choosing a shell selects its complete configuration profile.** Its required tools and plugins are automatic; the wizard asks only about additional applications. Already-installed programs and valid plugin checkouts are skipped.

## Contents

- [Quick start](#quick-start)
- [Requirements and supported systems](#requirements-and-supported-systems)
- [Interactive setup](#interactive-setup)
- [Command reference](#command-reference)
- [Automatic dependencies](#automatic-dependencies)
- [Common installation recipes](#common-installation-recipes)
- [Detection and repeat runs](#detection-and-repeat-runs)
- [Distribution packages](#distribution-packages)
- [Shell configuration](#shell-configuration)
- [Neovim](#neovim)
- [Tmux](#tmux)
- [Starship and terminals](#starship-and-terminals)
- [Development tools](#development-tools)
- [Managed files and install locations](#managed-files-and-install-locations)
- [Backups, removal, and restoration](#backups-removal-and-restoration)
- [Environment overrides](#environment-overrides)
- [Troubleshooting and practical limits](#troubleshooting-and-practical-limits)
- [Project structure and extension](#project-structure-and-extension)
- [Validation and tests](#validation-and-tests)
- [Upstream references](#upstream-references)

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

## Requirements and supported systems

The entrypoint requires Bash 4.4 or newer and uses arrays, `mapfile`, and namerefs. Use standard Linux utilities such as `readlink`, `mkdir`, `mv`, `ln`, `date`, and `mktemp`. System installation also needs working distro repositories, network access for downloads, and permission to use `sudo`.

| Family | Recognized metadata | Package manager |
| --- | --- | --- |
| Arch | `arch`, `manjaro`, `cachyos`, `endeavouros`, or an exact matching `ID_LIKE` token | `pacman` |
| Debian | `debian`, `ubuntu`, `linuxmint`, `pop`, or an exact matching `ID_LIKE` token | `apt-get` |
| Other | No supported ID/ancestry match | Config linking only |

Detection reads `/etc/os-release`, checks `ID` first, then the ancestry tokens in `ID_LIKE`. It does not classify a distro merely because its name contains the letters `arch` or `debian`.

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
4. Yes/no questions for independent optional tools.
5. Whether to install the selected tools and required dependencies.
6. Docker service/group questions if Docker was selected and installation is enabled.
7. A resolved plan and final confirmation.

Press Enter to accept a displayed shell/terminal default. Yes/no questions default to **no**. Answer `y` to select an optional tool or accept installation.

Dependencies already implied by the chosen shell or a tool are omitted from later tool questions. For example, choosing Zsh does not ask you separately to select Starship, fzf, nvm, eza, or its plugins. Choosing tmux automatically includes its fzf/plugin requirements. Plugin-manager internals are not standalone wizard questions.

Selecting an already-installed application can still apply its bundled configuration. An installed shell does not bypass checking the rest of that shell's required profile tools.

The plan distinguishes:

- **Configs:** repository templates that will be linked.
- **Optional tools:** your additional selections.
- **Automatic requirements:** tools implied by those selections.
- **Missing tools / distro packages:** the work remaining after installed-tool probes.
- **System changes:** login-shell activation, optional global Zsh bootstrap, and Docker service/group settings.

In `--yes` or `--dry-run` mode the wizard does not ask questions. Explicit selections are useful for reproducible automation.

## Command reference

```text
./bin/dotfiles [setup|install|packages|doctor|unlink] [options]
```

Omitting the command starts `setup`. Use `./bin/dotfiles --help` for the script's current built-in help.

### Commands

| Command | Installs tools | Links configs | Changes default shell |
| --- | --- | --- | --- |
| `setup` | Yes, unless `--no-packages` | Yes | Normally, for a selected shell |
| `packages` | Yes | No | No |
| `install` | No | Yes | No |
| `unlink` | No | Removes owned links only | No |
| `doctor` | No | No | No |

`setup --no-packages` preserves your current default shell unless `--login-shell` is explicitly supplied. An explicitly requested `--system-zshenv` can still perform that system-file change in config-only setup.

### Shared options

| Option | Meaning |
| --- | --- |
| `--dry-run` | Print the plan/commands without downloads, package installation, sudo execution, or config writes |
| `--yes` | Accept changes without the script's interactive prompts |
| `-h`, `--help` | Print usage |

`--yes` does not bypass operating-system authentication: `sudo` can still require credentials. `--dry-run` uses local detection results and cannot prove repository/network availability.

### Setup/package selection

| Option | Accepted values / behavior |
| --- | --- |
| `--shell` | `auto`, `bash`, `fish`, `zsh`, `none` |
| `--terminal` | `auto`, `kitty`, `konsole`, `alacritty`, `ghostty`, `none` |
| `--tools` | Comma-separated public tool names, or `none` |
| `--enable-docker` | Enable/start Docker with `systemctl enable --now docker` |
| `--docker-group` | Add the invoking user to the Docker group |

For **setup**, unspecified shell/terminal selections use detection. For **packages**, they default to `none` unless explicitly supplied: `packages --tools java` does not implicitly configure/install your current shell profile. Explicit `--shell auto` or `--terminal auto` in `packages` requests detection for that selection.

Public tool names are:

```text
git,nvim,tmux,starship,zoxide,nvm,docker,java,codex,fzf,bat,ripgrep,fd,
clipboard,tpm,aws,eza,lf,zsh-plugins,vim,tree,fastfetch
```

These are logical names, not always package/executable names. Use `nvim` for Neovim, `aws` for AWS CLI, `java` for a JDK, and `nvm` for the manager plus Node LTS. `clipboard` covers xclip and wl-clipboard. `tpm` includes the configured tmux plugin bundle. `zsh-plugins` includes all four declared Zsh plugins. The latter two can be named explicitly for maintenance even though the wizard hides their internal selection.

An explicit `--tools` list replaces the default optional list; required dependencies are still added. Empty items, trailing commas, unknown names, and missing values are rejected.

The unattended optional defaults when `--tools` is omitted are:

```text
git,nvim,tmux,starship,zoxide,nvm,docker,java,codex,fzf,bat,ripgrep,fd,tpm,aws
```

The selected profile can add further requirements. Use `--tools none` for just the selected shell/terminal profile.

### Setup-only options

| Option | Meaning |
| --- | --- |
| `--no-packages` | Resolve the profile and link configs, but skip package/vendor installers |
| `--keep-shell` | Preserve the account's login shell while configuring the chosen profile |
| `--login-shell` | Explicitly request default-shell activation, including with `--no-packages` |
| `--system-zshenv` | Append the XDG bootstrap to the global zshenv; requires a Zsh selection |

Normal setup already makes a selected shell default. It checks the account database, accepts only a registered path from `/etc/shells`, and uses `sudo chsh -s <path> <invoking-user>`. Equivalent `/bin` and `/usr/bin` paths are recognized. If that shell is already the account default, `chsh` is skipped. `none` selects no shell profile and no default-shell change.

`--login-shell` and `--keep-shell` are opposing controls; specify the one you intend. The parser processes flags in order.

### Install/unlink-only options

| Option | Meaning |
| --- | --- |
| `--components` | Exact comma-separated configuration components |
| `--all` | Every bundled config, including all shells and terminals |

Components are:

```text
bash,zsh,fish,tmux,nvim,starship,kitty,alacritty,konsole,ghostty
```

Without either selection, `install` and `unlink` use configs for supported programs found on PATH, plus the detected login shell. This can include several shells/terminals. An explicit `--components` list takes precedence over `--all` if both are supplied. No dependency installation occurs through these commands.

### Packages-only option

`--extra` adds the missing packages for all four terminals and clipboard tools. It does not link their configs. It can fail if an enabled repository has no candidate for one of them, such as Ghostty on an older APT release.

## Automatic dependencies

[packages/dependencies.tsv](packages/dependencies.tsv) is the central profile/tool manifest. [lib/dependencies.sh](lib/dependencies.sh) expands it recursively, removes duplicate nodes, and handles cycles such as tmux/TPM references without repeatedly scheduling them.

| Selection | Automatic requirements |
| --- | --- |
| Bash | Git, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, nvm/Node LTS |
| Zsh | Git, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, eza, lf, nvm/Node LTS, clipboard helpers, four Zsh plugins |
| Fish | Git, Vim, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, eza, tree, native nvm/Node LTS, clipboard helpers |
| Fish on CachyOS | Also CachyOS Fish defaults, fastfetch, and `col` |
| Neovim | Git for the existing Lazy bootstrap |
| tmux | fzf and TPM; TPM brings Git, tmux-resurrect, and tmux-continuum |
| Explicit TPM | tmux and Git, with tmux's requirements resolved too |
| Zsh plugins | Git |
| Missing Codex | nvm/Node LTS; an already-present Codex does not add another nvm installation just to be skipped |
| Standalone Java | The distro JDK package |

Fish includes **Vim** because your imported `EDITOR`/`VISUAL` values are `vim`; it also includes **Neovim** for your configured editing helpers. Bash/Zsh use Neovim as their editor default.

Aliases for Docker, AWS, Java-related project work, or tmux do not automatically make every optional application a shell requirement. The shell manifest covers active shell/editor/prompt/navigation modules. Neovim's language-specific servers, formatters, parser builds, and local AI setup have their separate lifecycle below.

When a resolved requirement has a repository config (`nvim`, `tmux`, or `starship`), setup links it too. The package manager independently resolves system-library dependencies.

Manual download prerequisites are scoped to the installer using them:

- Debian Starship downloads need certificate/downloader/archive utilities.
- nvm/Node downloads need certificate/downloader/archive utilities.
- AWS needs its downloader and supporting archive/signature/documentation packages.
- A missing Debian Docker engine needs the certificate/downloader path for its signed repository key.
- Repository-only Java installation does not add Git, curl, nvm, or shell tools.

There is no blanket development-stack installation for every standalone package request.

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

## Detection and repeat runs

Shell suggestions prefer `$SHELL`, then the account database, with Bash as the supported fallback. Default-shell activation separately reads the account database so a stale inherited `$SHELL` does not incorrectly skip `chsh`.

Terminal detection checks `TERM_PROGRAM`, Konsole/Kitty environment markers, and `TERM`. If those clues are absent, it suggests the first available executable in this order: Kitty, Konsole, Alacritty, Ghostty. Otherwise the result is `none`. On SSH or inside another session, this may be an installed-terminal suggestion rather than the physical terminal you are using; explicit flags select the intended target.

The installer adds `~/.local/bin` to its own PATH before probes.

| Tool/group | Installed condition |
| --- | --- |
| Most tools | Expected executable on PATH |
| Java | `javac`, so a JRE alone is insufficient |
| ripgrep | `rg` |
| fd | `fd` or Debian's `fdfind` |
| bat | `bat` or Debian's `batcat` |
| Clipboard | Both `xclip` and `wl-copy`; only missing halves are requested |
| Docker | Docker CLI and successful `docker compose version` |
| Bash/Zsh nvm | `nvm.sh`, a runnable default Node, and Node's LTS release marker |
| Fish nvm | Local nvm index and an installed runnable LTS Node |
| Codex | PATH, a native Fish LTS bin directory, or nvm-sh's default environment |
| Zsh plugins | All declared readable entrypoint files in the plugin directory |
| tmux plugin bundle | Executable entrypoints for TPM, resurrect, and continuum |
| CachyOS Fish defaults | The distro config file exists at its expected system location |

A Node probe recognizes an installed LTS release, not whether it is the newest release or still within its upstream support window. Other PATH checks generally do not enforce versions. Version compatibility still matters for the imported configs.

Repeat runs preserve valid existing programs/plugin versions. They install missing profile requirements even if the selected shell itself exists. Matching config links are skipped; links from another checkout are backed up/replaced when applying this checkout.

If all resolved tools are present, no package-manager call/download is needed. Config linking, an explicit global Zsh request, or a required login-shell/Docker service change can still occur. Setup is not an updater: use normal distro/tool/plugin update commands when you want upgrades.

## Distribution packages

[packages/components.tsv](packages/components.tsv) maps logical names to repository packages.

| Component | Debian-family package | Arch-family package |
| --- | --- | --- |
| Bash / Fish / Zsh | `bash` / `fish` / `zsh` | Same |
| Git | `git` | `git` |
| Neovim | `neovim` | `neovim` |
| Vim | `vim` | `vim` |
| tmux | `tmux` | `tmux` |
| fzf / zoxide / bat / ripgrep | Matching package names | Matching package names |
| fd | `fd-find` | `fd` |
| Java JDK | `default-jdk` | `jdk-openjdk` |
| eza / lf / tree / fastfetch | Matching package names | Matching package names |
| Kitty / Konsole / Alacritty / Ghostty | Matching package names, if available | Matching package names |
| Clipboard | `xclip`, `wl-clipboard` | Same |
| `col` | `bsdextrautils` | `util-linux` |
| CachyOS Fish defaults | Not requested on Debian | `cachyos-fish-config`, only for the CachyOS profile branch |

Vendor-managed components such as nvm, AWS, Codex, and Zsh plugins have dedicated installers instead of a universal repository mapping. Starship and Docker also use distro-specific/vendor paths.

### APT

The installer refreshes metadata with `apt-get update`, checks candidates for the normal planned packages, then uses:

```text
sudo apt-get install -y --no-upgrade -- <missing-packages>
```

Unavailable packages stop installation with their name. The script does not add general-purpose PPAs or substitute another terminal automatically. Docker has its own repository/package checks.

### Pacman

Missing repository packages use:

```text
sudo pacman -S --needed --noconfirm -- <missing-packages>
```

The script does not refresh the database with `-y`, force a full upgrade, or install an AUR helper. If mirrors no longer provide versions in your stale database, update the system normally with `sudo pacman -Syu`, then rerun setup.

Repository availability and versions vary. For example, older APT releases may lack eza/Ghostty or provide Neovim/fzf versions older than the configs expect. Installed tools are normally skipped rather than silently replaced with newer builds.

## Shell configuration

### Bash

`~/.bashrc` links to [shell/bash/bashrc](shell/bash/bashrc). Interactive startup loads the shared modules in this order: environment, aliases, functions, platform aliases, integrations.

- Neovim is the default editor unless already set through the shared environment.
- Personal binaries and nvm-sh are loaded when available.
- Starship, zoxide, and optional fzf shell initialization are guarded by availability.
- APT/pacman aliases use the shared distro detector.
- Debian fd/bat executable names receive conventional aliases.
- Local overrides load last from `$XDG_CONFIG_HOME/bash/local.bash`.

### Fish

[config/fish](config/fish) starts from your imported system config, plugin sources, completions, and universal preferences. Fisher, Tide, and native nvm.fish source files are bundled. Starship is activated by your main interactive configuration.

The portable `conf.d/dotfiles-environment.fish` layer adds the personal PATH, reads the shared distro detector, and handles Debian's alternate bat/fd names. CachyOS defaults load only on CachyOS when available. APT and pacman aliases select the appropriate family; duplicate fzf initialization was removed.

Your main configuration retains the Git/Docker/tmux helpers, Fish-style fzf appearance and previews, `EDITOR=vim`, `VISUAL=vim`, and interactive LTS activation. Fish uses zoxide-backed `cd` interactively when zoxide is present; noninteractive `cd` keeps its native behavior.

Examples include `killfzf`, `gcofzf`, `dbf`, smart no-argument `tmux`, Git shortcuts, Docker/Compose shortcuts, and tmux save/restore commands. The imported `dcud`/`nb` spellings remain in Fish; the corresponding Zsh aliases have the corrections described below.

`fish_variables` is included to retain universal prompt settings and Fisher inventory. Fish can update that file at runtime through the linked directory. Review such changes before committing; histories and credentials are not intended repository content.

There is no custom `dotfiles/local.fish` override hook in this imported entrypoint. Customize its main/modules/functions directly or use Fish's normal configuration mechanisms.

### Zsh

See [the complete Zsh guide](config/zsh/README.md).

The installer manages individual files under `$XDG_CONFIG_HOME/zsh` so it preserves `local.zsh` and unrelated files. It also links a user-level `~/.zshenv` bootstrap and a compatibility `~/.zshrc` bridge.

| File/module | Purpose |
| --- | --- |
| `.zshenv` | XDG defaults, Neovim editor, unique personal PATH, man pager, terminal-aware `GPG_TTY`, Starship path |
| `.zshrc` | History, completion cache/styles, lf icons, zoxide, ordered module loading |
| `node.zsh` | nvm-sh initialization |
| `fzf.zsh` | fd/fdfind/find discovery, bat/batcat/head previews, fzf loading, quoted Ctrl-F insertion |
| `aliases.zsh` | Fish-derived shortcuts, eza listings, distro package aliases |
| `functions.zsh` | Git picker, process picker, Docker build, smart tmux, lf directory changes |
| `bindings.zsh` | Vi cursor configuration, custom keys, post-init reapplication |
| `plugins.zsh`, `plugins.list` | Load declared local plugins and expose explicit updates |
| `prompt.zsh` | Starship and virtualenv prompt suppression |
| `starship.toml` | Link to the project's shared Starship template |
| `local.zsh` | Optional user-owned overrides, loaded last |

Zsh creates `$XDG_STATE_HOME/zsh/history` on use with history capacity 100,000 and uses `$XDG_CACHE_HOME/zsh/zcompdump` for completion metadata. The state/cache directories are created with `mkdir -p`.

Your Fish names are adapted into native Zsh syntax. Notable changes:

- `dcud` is `docker compose up -d`.
- `nb` is `npm run build`.
- `dotfiles` launches this checkout's installer rather than assuming a bare Git repository in `~/.dotfiles`.
- `cd` keeps native behavior; `z` performs ranked zoxide jumps.
- eza/bat/fd replacements fall back or adapt to Debian names.
- Helpers use `command cat` for machine-readable data rather than the colorized cat alias.

Useful keys:

| Key | Action |
| --- | --- |
| Ctrl-F | Insert a non-hidden file selected through fzf, safely quoted |
| Ctrl-T / Alt-C / Ctrl-R | Standard fzf file/directory/history bindings when installed |
| Ctrl-Left / Ctrl-Right | Move by word |
| Up / Down | Substring history search with its plugin; normal history otherwise |
| Ctrl-Backslash | Toggle autosuggestions when the widget is available |

The profile falls back to native vi bindings if plugins are absent. Vi cursor constants are applied through `zvm_config`; fzf/custom keys are restored after plugin initialization. The fzf loader handles the read-only ZLE option restoration issue encountered with the installed Zsh.

Zsh plugins are declared in [config/zsh/plugins.list](config/zsh/plugins.list):

- `zsh-users/zsh-autosuggestions`
- `zsh-users/zsh-history-substring-search`
- `jeffreytse/zsh-vi-mode`
- `zdharma-continuum/fast-syntax-highlighting`

They are cloned during installation into `$XDG_DATA_HOME/zsh/plugins`, or `ZPLUGINDIR`. Startup loads local entrypoints only. `zplugin-update` explicitly runs fast-forward Git pulls; open a new shell after updating. Incomplete plugin directories are reported for repair instead of overwritten.

#### Optional global zshenv

```bash
./bin/dotfiles setup --shell zsh --terminal none --tools none --system-zshenv --yes
```

This appends [config/zsh/system-zshenv.zsh](config/zsh/system-zshenv.zsh) to `/etc/zsh/zshenv` without replacing distro content. An existing file is backed up to the run's `system/zshenv` archive; a marker prevents repeated appends. `ZSH_GLOBAL_ENV_FILE` selects another global path if your Zsh build uses one.

The fragment defaults `XDG_CONFIG_HOME` when needed and redirects startup to its `zsh` directory when the directory exists and startup-file reading is enabled. The user-level bootstrap works without this system change.

`unlink` does not remove the global fragment. To reverse it, remove the marked block or restore its system backup separately.

## Neovim

The project includes your full system Lua setup rather than a minimal starter:

- `init.lua` and `lua/config` modules for options, keybindings, filetypes, Python selection, LSP helpers, and buffer handling.
- `lua/plugins` specifications for Lazy-managed plugins.
- `lazy-lock.json`, StyLua settings, and the YAML ftplugin.
- Tokyo Night theme, lualine, bufferline, Neo-tree, Telescope, completion, formatting, linting, Treesitter, Mason, and local Minuet/Ollama completion.

The imported setup documents **Neovim 0.11.3+**. The installer uses the distro Neovim package and does not automatically choose a newer binary if your repository version is older.

Automatic dependency resolution supplies Git for Lazy. It does **not** execute every Neovim language-tool/parser/model installation. On a fresh machine, after meeting the requirements in [config/nvim/README.md](config/nvim/README.md), use:

```vim
:Lazy restore
:MasonToolsInstall
:TreesitterInstall
```

Use `:checkhealth`, `:Mason`, `:ConformInfo`, and `:checkhealth vim.lsp` to inspect the setup. Node/npm, Python with venv support, Go, a C compiler, tree-sitter CLI, and an appropriate JDK are required by particular language/build workflows. They are not all installed merely because the Neovim package is selected.

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

[config/tmux/tmux.conf](config/tmux/tmux.conf) and the session picker preserve your imported system settings. Setup links both `$XDG_CONFIG_HOME/tmux` and `~/.tmux.conf`, since your reload binding uses the latter.

- Prefix: **Ctrl-Space**.
- Prefix + `R`: reload `~/.tmux.conf`.
- Prefix + `r`: popup fuzzy session picker; built-in tree fallback when fzf is missing.
- Splits/windows open in the active pane's directory.
- Vim-style pane navigation, mouse support, vi copy mode, true-color handling, and Tokyonight Moon styling are retained.
- Desktop clipboard commands use available X11/Wayland utilities, alongside the configured terminal clipboard behavior.
- Resurrect capture and 15-minute continuum save/restore settings are retained.

Selecting tmux automatically brings in fzf, Git, and the plugin bundle listed in [packages/tmux-plugins.tsv](packages/tmux-plugins.tsv):

```text
tmux-plugins/tpm
tmux-plugins/tmux-resurrect
tmux-plugins/tmux-continuum
```

Missing checkouts are cloned into `~/.tmux/plugins`; valid existing checkouts are preserved. Prefix + `I` remains available for TPM maintenance. Setup does not replace/start your running tmux server; open/reload it to activate the configuration.

The popup/reload commands retain their standard home paths. In particular, the popup uses `~/.config/tmux/session-picker.sh`, so a custom `XDG_CONFIG_HOME` needs an appropriate adjustment to that binding.

See [config/tmux/README.md](config/tmux/README.md).

## Starship and terminals

Starship's shared template is [config/starship/starship.toml](config/starship/starship.toml), imported from your system. The Dracula palette, powerline separators, OS/user/directory/Git/runtime/job/time segments, command duration, and input symbols are retained.

The global configuration links to `$XDG_CONFIG_HOME/starship.toml`; Zsh also receives `$ZDOTDIR/starship.toml` pointing to the same repository file. Editing that template affects both. Starship does not require installing every language displayed in its module definitions.

| Terminal | Managed configuration |
| --- | --- |
| Kitty | Directory with font, color, cursor, padding, and close-confirmation settings |
| Alacritty | TOML font, padding, opacity, and color configuration |
| Ghostty | Font, padding, transparency, and Tokyonight Moon colors |
| Konsole | `Moon.colorscheme` only, under the XDG data directory |

Terminal selection installs/configures the chosen terminal; it does not change desktop default-terminal associations. Konsole needs you to select Moon in its profile settings. Its whole preferences directory is not replaced.

A font containing the prompt/editor icon glyphs is needed for those icons; choose an installed Nerd Font in your terminal settings. Font installation is not performed by this script.

## Development tools

### Java

`java` installs `default-jdk` on Debian derivatives or `jdk-openjdk` on Arch derivatives. `javac` is the installed-tool probe. The JDK version follows your configured repositories; this is not SDKMAN or a pinned Java-version manager.

```bash
./bin/dotfiles packages --tools java --yes
```

The script does not add nvm, Node, Neovim, or shell profiles to that standalone request.

### nvm and Node LTS

Bash/Zsh and standalone `packages --tools nvm` use **nvm-sh**, pinned to `v0.40.8` by default. `NVM_VERSION` overrides the manager tag and `NVM_DIR` its directory. The manager's script installation suppresses automatic rc-file edits; the project's shell templates load it.

Missing Node setup runs `nvm install --lts`, sets `default` to the literal `lts/*` alias, and activates the default in the installer child shell. A valid existing default LTS is kept. The profile activates it in a new interactive Bash/Zsh session.

Fish selections use the bundled native **jorgebucaran/nvm.fish** instead. The installer invokes its functions with `fish --no-config`, installs `lts`, and keeps Node data/index under `$XDG_DATA_HOME/nvm` or an exported `nvm_data`. Your interactive Fish config uses `nvm use lts --silent`.

These are separate manager implementations/data directories. Fish's commands are not identical to nvm-sh's; use the corresponding help for that shell. New shells/PATH setup are necessary to use newly installed per-user executables.

### Codex CLI

A missing `codex` selection brings in nvm/Node LTS and installs `@openai/codex` globally through npm in the chosen Node environment, without sudo for npm. Fish uses an installed native LTS bin directory; Bash/Zsh/standalone installation uses nvm-sh's default.

An existing Codex on PATH or in a recognized Node environment is skipped. Setup does not configure credentials or perform sign-in. Run `codex` afterward to complete its normal authentication flow.

### AWS CLI

`aws` uses the official AWS per-user installer for Linux x86_64/aarch64 and puts the executable in `~/.local/bin`. Its data location follows the upstream installer's XDG behavior. The executable's version is checked after installation.

Any existing `aws` command, including AWS CLI v1, is kept rather than automatically upgraded. Account/profile configuration is separate:

```bash
aws configure
# Or, when using an SSO profile:
aws configure sso
```

AWS credentials are not imported into the repository or generated by this setup.

### Docker and Compose

Docker is considered installed when the CLI exists and `docker compose version` succeeds. That check does not require contacting a running daemon. Setup does not claim that the daemon is running merely because the CLI/plugin is present.

Arch uses `docker`, `docker-compose`, and `docker-buildx` for a missing engine, preserving existing engine/Compose pieces where possible.

For a missing Debian/Ubuntu engine, the installer:

1. Resolves the upstream base distro and release codename.
2. Checks conflicting distro packages before applying package installation.
3. Reuses a recognized official repository, or installs its signing key and source metadata.
4. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`.

The generated files are:

```text
/etc/apt/keyrings/dotfiles-docker.asc
/etc/apt/sources.list.d/dotfiles-docker.sources
```

Plain Debian/Ubuntu and Ubuntu derivatives with `UBUNTU_CODENAME` can be resolved automatically. Other derivatives may require explicit **base-release** values:

```bash
DOCKER_DISTRO=debian DOCKER_CODENAME=trixie \
  ./bin/dotfiles packages --tools docker --yes
```

`DOCKER_DISTRO` accepts `debian` or `ubuntu`. The codename must be the corresponding base release, not an unrelated derivative codename.

Conflicting distro packages are reported rather than removed automatically: `docker.io`, `docker-compose`, `docker-compose-v2`, `docker-doc`, `podman-docker`, `containerd`, and `runc` are checked when adding a missing upstream engine.

If Docker already exists but Compose is missing, the installer keeps the engine and searches configured APT repositories for a compatible Compose v2 package. It excludes the upstream-plugin path for a distro `docker.io` engine and rejects old Compose v1 packages. If no compatible candidate exists, it stops with an explanation instead of replacing Docker.

Service/group changes are explicit:

```bash
./bin/dotfiles packages --tools docker --enable-docker --yes
./bin/dotfiles packages --tools docker --enable-docker --docker-group --yes
```

`--enable-docker` starts/enables the service. `--docker-group` grants root-level Docker access to your user; log out/back in to apply group membership. Without it, use `sudo docker` as appropriate. These flags still apply when the tools themselves were skipped as installed, and require Docker to be selected with package installation enabled.

Debian package maintainer scripts may start services during package installation even without an explicit enable flag. Repository/package/service changes are not reversed by `unlink`.

## Managed files and install locations

Defaults below honor the corresponding XDG overrides unless a retained application binding uses a fixed home path.

| Component | Repository source | User destination |
| --- | --- | --- |
| Bash | `shell/bash/bashrc` | `~/.bashrc` |
| Fish | `config/fish/` | `$XDG_CONFIG_HOME/fish/` |
| Neovim | `config/nvim/` | `$XDG_CONFIG_HOME/nvim/` |
| tmux support | `config/tmux/` | `$XDG_CONFIG_HOME/tmux/` |
| tmux startup | `config/tmux/tmux.conf` | `~/.tmux.conf` |
| Starship | `config/starship/starship.toml` | `$XDG_CONFIG_HOME/starship.toml` |
| Kitty | `config/kitty/` | `$XDG_CONFIG_HOME/kitty/` |
| Alacritty | `config/alacritty/` | `$XDG_CONFIG_HOME/alacritty/` |
| Ghostty | `config/ghostty/` | `$XDG_CONFIG_HOME/ghostty/` |
| Konsole | `config/konsole/Moon.colorscheme` | `$XDG_DATA_HOME/konsole/Moon.colorscheme` |
| Zsh environment/rc | `config/zsh/.zshenv`, `.zshrc` | `$XDG_CONFIG_HOME/zsh/.zshenv`, `.zshrc` |
| Zsh modules/manifest | `config/zsh/*.zsh`, `plugins.list` | Individual files under `$XDG_CONFIG_HOME/zsh/` |
| Zsh Starship | Shared Starship template | `$XDG_CONFIG_HOME/zsh/starship.toml` |
| Zsh bootstrap | `shell/zsh/zshenv` | `~/.zshenv` |
| Zsh compatibility rc | `shell/zsh/zshrc` | `~/.zshrc` |

`README.md`, `system-zshenv.zsh`, and your optional `local.zsh` are not all swept into the Zsh directory as a whole; the link registry specifies the managed files individually. Internal link names used by `doctor` are implementation details rather than extra public `--components` values.

Runtime/download locations include:

| Data | Default location |
| --- | --- |
| Backups | `~/.local/state/dotfiles/backups/<timestamp>-<pid>/` |
| Zsh history | `~/.local/state/zsh/history` |
| Zsh completion cache | `~/.cache/zsh/zcompdump` |
| Zsh plugins | `~/.local/share/zsh/plugins/` |
| tmux plugins | `~/.tmux/plugins/` |
| nvm-sh | `~/.nvm/` |
| Native Fish Node versions/index | `~/.local/share/nvm/` |
| Starship/AWS executables installed per-user | `~/.local/bin/` |
| Neovim downloaded plugins/tools/state | Neovim/Lazy/Mason standard XDG paths |
| Installer downloads | A temporary directory cleaned on exit |

The initial system-config import retained source/config files, lockfiles, completions, and prompt preferences. It excluded nested Git metadata, backup copies, histories, recovery files, downloaded Neovim plugins, caches, and credentials. Neovim, tmux, and Starship retain that imported baseline; Fish has the portability adjustments documented above.

## Backups, removal, and restoration

Before replacing a destination, the installer moves its existing file, directory, or dangling symlink into:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/<timestamp>-<pid>/
```

For ordinary targets under HOME, the original relative path is retained. For example:

```text
~/.bashrc                 -> <run>/.bashrc
~/.config/nvim/           -> <run>/.config/nvim/
~/.tmux.conf              -> <run>/.tmux.conf
/etc/zsh/zshenv (optional)-> <run>/system/zshenv
```

Fish, Neovim, tmux support, and supported terminal directories are linked as whole directories. Zsh files and the Konsole scheme are managed individually. Symlink destinations are absolute paths into this checkout, so **keep the checkout at the same location** while the links are active.

### Remove owned links

```bash
./bin/dotfiles unlink --components zsh,tmux,nvim --dry-run
./bin/dotfiles unlink --components zsh,tmux,nvim --yes
```

Only a symlink storing the exact template path for this checkout is removed. External files/links are skipped. Zsh removal covers its support/bootstrap links; tmux removal covers both the support directory and `~/.tmux.conf`.

`unlink` does not:

- Restore archived configuration automatically.
- Uninstall packages or downloaded plugins.
- Revert the account's login shell or Docker group membership.
- Undo Docker repositories/service configuration.
- Remove the optional global Zsh fragment.
- Remove history, completion caches, or backups.

### Restore an archived config

First inspect/select the desired backup. The placeholder path below must be replaced with a real run directory; it is not meant to be executed literally.

```bash
./bin/dotfiles unlink --components nvim --yes

# Replace RUN-DIRECTORY with the selected timestamp/PID directory.
mv -- "$HOME/.local/state/dotfiles/backups/RUN-DIRECTORY/.config/nvim" \
  "$HOME/.config/nvim"
```

The same pattern applies to files such as `.bashrc` and `.tmux.conf`. Confirm that the destination is absent before moving a backup there. Use your actual XDG paths when customized.

For a global zshenv change, remove the marked appended fragment or restore the archived system file with appropriate system privileges. That backup can be root-owned because the original was copied with preserved metadata.

There is no automatic system rollback. If a later step fails, earlier package installs/links may already have completed. Correct the reported issue and rerun; the detection/link checks avoid repeating completed work.

## Environment overrides

| Variable | Default / purpose |
| --- | --- |
| `HOME` | Target user's home; also useful for isolated config-only previews/tests |
| `XDG_CONFIG_HOME` | `$HOME/.config`; managed application configuration |
| `XDG_CACHE_HOME` | `$HOME/.cache`; Zsh completion cache and application caches |
| `XDG_DATA_HOME` | `$HOME/.local/share`; plugins/native Fish Node/Konsole data |
| `XDG_STATE_HOME` | `$HOME/.local/state`; backups and Zsh history |
| `NVM_DIR` | `$HOME/.nvm`; nvm-sh directory |
| `NVM_VERSION` | `v0.40.8`; manager tag, validated as `vX.Y.Z` |
| `nvm_data` | `$XDG_DATA_HOME/nvm`; exported native Fish Node location |
| `ZPLUGINDIR` | `$XDG_DATA_HOME/zsh/plugins`; use consistently during install and startup |
| `DOCKER_DISTRO` | Optional upstream base `debian` or `ubuntu` |
| `DOCKER_CODENAME` | Optional corresponding upstream release codename |
| `ZSH_GLOBAL_ENV_FILE` | `/etc/zsh/zshenv`; destination when the global flag is selected |
| `OS_RELEASE_FILE` | `/etc/os-release`; alternate metadata source, primarily for tests |
| `SHELLS_FILE` | `/etc/shells`; alternate registered-shell list, primarily for tests |

Overrides must be consistent between installer runs and shell startup. In particular, a one-command custom plugin/Node location does not automatically persist that environment variable in future shells. Zsh's `local.zsh` can store its overrides; native Fish configuration can export `nvm_data`.

Some imported Fish editor values are explicitly assigned, while Zsh explicitly uses Neovim. Bash's shared editor defaults preserve an existing setting. The core configs may therefore intentionally differ in how they treat an inherited editor value.

The library computes `ROOT` from the entrypoint location, so normal commands work regardless of your current directory when invoking the script by its path.

## Troubleshooting and practical limits

| Symptom | Meaning / next step |
| --- | --- |
| `Unsupported distro` | Use config-only commands or add a supported package-family implementation |
| `No APT candidate for ...` | Enable a suitable repository, choose another optional tool/terminal, or meet a required profile package before applying that profile |
| Pacman download failures after long inactivity | Refresh/upgrade normally with `sudo pacman -Syu`, then retry |
| Shell is installed but not default | Setup may have used `--keep-shell`/config-only mode; otherwise inspect `chsh` result and log out/back in |
| Shell path not registered | Check `/etc/shells` and the installed executable's system path |
| Zsh history/completion problems | Check write access to the XDG state/cache directories; inspect overrides |
| Zsh profile not read | Inspect `~/.zshenv`, `ZDOTDIR`, and any global zshenv setting; use the supplied bridge/global path appropriate for the build |
| Plugin directory exists but lacks an entrypoint | Repair it or move the incomplete checkout aside, then rerun; the script does not overwrite it blindly |
| Docker repository conflict | Deliberately resolve the named existing distro package or omit Docker; it is not auto-removed |
| Docker CLI works, commands need privileges/daemon | Check the service and intended sudo/group setup separately |
| `docker compose` unavailable with an existing engine | A compatible v2 package is required; the script preserves the engine if none is available |
| Neovim fails after linking | Check its required version and application README; restore prior config if needed |
| Prompt icons look wrong | Select a font containing the configured glyphs |
| tmux popup fails with custom XDG paths | Adjust the retained fixed `~/.config/tmux` binding |

Additional limits:

- Repository versions, not universal upstream latest versions, are used for distro packages.
- Selecting Java does not pin a particular Java LTS; installed tools are generally not upgraded.
- Fonts, desktop terminal associations, user credentials, Git identity, SSH configuration, project environments, and local Ollama models are not provisioned.
- `install --all` manages every template, including several shells and whole application directories; preview its target list first.
- No general AUR-helper installation, automatic restoration command, or complete system rollback is provided.
- User/plugin/application runtime files can change through directory symlinks; review repository changes before committing.

## Project structure and extension

```text
bin/dotfiles                    CLI parsing, shared state, dispatch
lib/core.sh                     Validation, logging, dry-run/sudo wrappers, downloads
lib/platform.sh                 Distro, login-shell, terminal detection
lib/detection.sh                Executable/package/plugin/Node presence checks
lib/dependencies.sh             Recursive dependency expansion and wizard filtering
lib/setup.sh                    Questions, plan, installation/link order, chsh
lib/links.sh                    Component paths, backups, link/unlink ownership
lib/packages.sh                 Missing package plan, repository/vendor dispatch
lib/doctor.sh                   Read-only diagnostics
lib/installers/node.sh          nvm-sh/native Fish Node/Codex
lib/installers/aws.sh            Per-user AWS CLI
lib/installers/docker.sh         Repository, engine/Compose, service/group actions
lib/installers/zsh.sh            Zsh plugins and optional global bootstrap
lib/installers/extras.sh         Starship and tmux plugin bundle
packages/components.tsv         Logical component -> APT/pacman names
packages/dependencies.tsv       Profile/tool -> automatic requirements
packages/tmux-plugins.tsv       tmux repositories and required entrypoints
shell/common/                   Bash/reusable environment, aliases, functions
shell/bash/bashrc               Bash entrypoint
shell/zsh/{zshenv,zshrc}         User/legacy Zsh startup bridges
config/zsh/                     Modular XDG Zsh profile
config/fish/                    Imported Fish plugins/config + portable layer
config/nvim/                    Full Lua editor/plugin specifications + lockfile
config/tmux/                    Imported tmux configuration and picker
config/starship/                Shared prompt
config/{kitty,alacritty,ghostty}/ Terminal templates
config/konsole/                 Moon color scheme
tests/test_installer.py          Isolated behavior tests
```

Read `bin/dotfiles` first, then follow `perform_setup` in `lib/setup.sh`. Dependency expansion happens before detection/package planning; installation happens before config linking, optional global bootstrap, and default-shell activation. Code comments describe shared arrays, inputs, skip decisions, and shell-specific behavior.

To extend the project:

1. Add a public logical tool name to `tools_available` if users should select it directly.
2. Add distro package mappings to `packages/components.tsv`, or a dedicated vendor installer and dispatch case.
3. Add its required components to `packages/dependencies.tsv`; they will be automatic and omitted from applicable wizard questions.
4. Add an installed-tool probe if executable-name detection is insufficient.
5. For configuration, add the component name and source/target mappings to the link registry. Add support-link handling if the component owns multiple files.
6. Add plugin repository/entrypoint metadata to the corresponding manifest when extending a bundle.
7. Update this documentation and exercise the behavior in isolated fixtures.

These registries describe different things: `--tools` names identify logical installation selections; `--components` names identify configuration targets. An internal dependency grouping such as `fish-cachyos` is not itself a public selectable app or package.

## Validation and tests

Install Python 3, Bash, Fish, and Zsh to run the behavior suite:

```bash
python3 -m unittest discover -s tests -v
```

The current suite contains **59 tests**. It uses temporary homes/XDG directories, synthetic distro metadata, a restricted PATH, mocked package/network commands, and pseudo-terminals for real prompt behavior. It does not perform real package installations or contact upstream download hosts.

Coverage includes:

- Whole-token Debian/Arch detection and unsupported-distro config-only behavior.
- Dependency recursion/deduplication, automatic shell profiles, hidden dependency questions, standalone Java/Node isolation.
- Backups, matching-link skips, ownership-safe removal, tmux's startup link, and Zsh support links.
- Shell installation/default activation, already-default skips, stale `$SHELL`, registered-shell validation, opt-outs.
- AWS install/skip behavior, nvm LTS handling, native Fish Codex detection.
- Debian/Arch plans, Docker conflicts, Compose-only preservation, explicit service settings.
- Quiet XDG Zsh startup, history/completion, aliases, keybindings, fzf quoting/option restoration, lf directory changes.
- Plugin bundles, partial installs, repeat runs, startup without download attempts.
- Portable Fish startup and repeatable global-zshenv merging inside a temporary fixture.

Syntax checks can also be run without installing anything:

```bash
for file in bin/dotfiles lib/*.sh lib/installers/*.sh shell/common/*.sh shell/bash/bashrc; do
  bash -n "$file" || exit 1
done

for file in config/zsh/.*zsh* config/zsh/*.zsh shell/zsh/*; do
  zsh -n "$file" || exit 1
done

for file in config/fish/config.fish config/fish/conf.d/*.fish; do
  fish -n "$file" || exit 1
done
```

A passing mocked suite is not a real package-download, daemon, terminal-rendering, or full Neovim language-tool installation test. Use `doctor`, application health commands, and the printed installation plan on the target machine.

## Upstream references

- [Zsh startup files](https://zsh.sourceforge.io/Doc/Release/Files.html)
- [nvm-sh](https://github.com/nvm-sh/nvm)
- [Native nvm.fish](https://github.com/jorgebucaran/nvm.fish)
- [Starship](https://starship.rs/guide/)
- [AWS CLI installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Docker on Debian](https://docs.docker.com/engine/install/debian/)
- [Docker on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [Zsh autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [Zsh substring history](https://github.com/zsh-users/zsh-history-substring-search)
- [Zsh vi mode](https://github.com/jeffreytse/zsh-vi-mode)
- [Fast syntax highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Neovim application guide](config/nvim/README.md)
- [Zsh application guide](config/zsh/README.md)
- [Tmux application guide](config/tmux/README.md)
- [Konsole scheme notes](config/konsole/README.md)
