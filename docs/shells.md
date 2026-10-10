# Shells

[Project home](../README.md)

## Listing aliases

Run `aliases` in Bash, Fish, or Zsh to list every alias currently loaded, including personal overrides and aliases defined during the session. Open a new shell after installing these changes. Fish's alias wrappers are included; ordinary functions are separate.

To browse this checkout's configured aliases across shells without changing shells or installing anything:

```bash
./bin/dotfiles aliases                  # All installed shells, grouped by shell
./bin/dotfiles aliases --shell fish     # Fish configuration only
./bin/dotfiles aliases --shell auto     # Detected login-shell family
```

The CLI reads the repository configuration using clean, noninteractive shells, so it works before configs are linked. It resolves OS-specific and executable-specific aliases on the current machine. Missing shells are reported and skipped in the combined listing; an explicitly requested missing shell reports an error. CLI output includes repository aliases; use the live `aliases` function for personal/session additions. Neither command executes the listed aliases.

## Shell configuration

### Bash

`~/.bashrc` links to [shell/bash/bashrc](../shell/bash/bashrc). Interactive startup loads the shared modules in this order: environment, aliases, functions, platform aliases, integrations.

- Neovim is the default editor unless already set through the shared environment.
- Personal binaries and nvm-sh are loaded when available.
- Starship, zoxide, and optional fzf shell initialization are guarded by availability.
- `update`, `install`, `remove`, and `search` use shared APT/pacman/DNF mappings from `shell/common/package-aliases.tsv` in Bash, Fish, and Zsh. Distribution ancestry comes from `ID`/`ID_LIKE`, without release-version checks.
- Debian fd/bat executable names receive conventional aliases.
- Local overrides load last from `$XDG_CONFIG_HOME/bash/local.bash`.

### Fish

[config/fish](../config/fish) starts from your imported system config, plugin sources, completions, and universal preferences. Fisher, Tide, and native nvm.fish source files are bundled. Starship is activated by your main interactive configuration.

The portable `conf.d/dotfiles-environment.fish` layer adds the personal PATH, reads the shared distro detector, and handles Debian's alternate bat/fd names. CachyOS defaults load only on CachyOS when available. APT, pacman and DNF aliases load the same mappings as Bash/Zsh; duplicate fzf initialization was removed.

Fish config-editing shortcuts honor `$XDG_CONFIG_HOME`; `xcopy` uses xclip or falls back to wl-copy. The man pager uses the actual bat/batcat executable.

Your main configuration retains the Git/Docker/tmux helpers, Fish-style fzf appearance and previews, `EDITOR=vim`, `VISUAL=vim`, and interactive LTS activation. Fish uses zoxide-backed `cd` interactively when zoxide is present; noninteractive `cd` keeps its native behavior.

Examples include `killfzf`, `gcofzf`, `dbf`, smart no-argument `tmux`, Git shortcuts, Docker/Compose shortcuts, and tmux save/restore commands. `dcud` runs `docker compose up -d` and `nb` runs `npm run build` in both Fish and Zsh.

`fish_variables` and `fish_plugins` seed a writable user directory once. Fish source files are linked individually; universal preferences, Fisher inventory and local overrides remain in your home. Setup migrates the former whole-directory link with a backup and preserves existing preferences. Fish runtime updates no longer modify these checkout files.

Put personal overrides in `$XDG_CONFIG_HOME/fish/local.fish`; they load last and survive repeat setup.

### Zsh

See [the complete Zsh guide](../config/zsh/README.md).

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

Zsh plugins are declared in [config/zsh/plugins.list](../config/zsh/plugins.list):

- `zsh-users/zsh-autosuggestions`
- `zsh-users/zsh-history-substring-search`
- `jeffreytse/zsh-vi-mode`
- `zdharma-continuum/fast-syntax-highlighting`

They are cloned during installation into `$XDG_DATA_HOME/zsh/plugins`, or `ZPLUGINDIR`. Startup loads local entrypoints only. `zplugin-update` explicitly runs fast-forward Git pulls; open a new shell after updating. Incomplete plugin directories are repaired automatically: clone and verify a replacement first, then archive the original under the run’s backup directory before activating it.

#### Optional global zshenv

```bash
./bin/dotfiles setup --shell zsh --terminal none --tools none --system-zshenv --yes
```

This appends [config/zsh/system-zshenv.zsh](../config/zsh/system-zshenv.zsh) to the distro startup file (`/etc/zsh/zshenv` on Debian; `/etc/zshenv` on Arch/Fedora) without replacing distro content. An existing file is backed up to the run's `system/zshenv` archive; a marker prevents repeated appends. `ZSH_GLOBAL_ENV_FILE` selects another global path if your Zsh build uses one.

The fragment defaults `XDG_CONFIG_HOME` when needed and redirects startup to its `zsh` directory when the directory exists and startup-file reading is enabled. The user-level bootstrap works without this system change.

`unlink` does not remove the global fragment. To reverse it, remove the marked block or restore its system backup separately.

## Development tools

### Java

`java` installs `openjdk-21-jdk` on Debian derivatives, `jdk-openjdk` on Arch derivatives, or `java-21-openjdk-devel` on Fedora derivatives. The probe requires `javac` 21+. If an older Debian release lacks an OpenJDK 21 candidate, setup stops with the package name instead of claiming the editor requirements are satisfied.

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

Fedora uses `moby-engine`, `docker-cli`, `docker-buildx`, and `docker-compose` from configured distro repositories. Fedora's [Compose package](https://packages.fedoraproject.org/pkgs/docker-compose/docker-compose/fedora-43.html) installs the CLI plugin used by `docker compose`. If the engine already exists, only missing Compose is requested. An installed `podman-docker` provider is reported as a conflict rather than treated as Docker or automatically removed. Podman itself can remain installed.

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
