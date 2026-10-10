# Maintenance

[Project home](../README.md)

## Managed files and install locations

Defaults below honor the corresponding XDG overrides unless a retained application binding uses a fixed home path.

| Component | Repository source | User destination |
| --- | --- | --- |
| Bash | `shell/bash/bashrc` | `~/.bashrc` |
| Fish | Individual `config/fish/**/*.fish` sources; user-owned state seeded once | `$XDG_CONFIG_HOME/fish/` |
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
distro global zshenv (optional) -> <run>/system/zshenv
```

Fish, Neovim, tmux support, and supported terminal directories are linked as whole directories. Zsh files and the Konsole scheme are managed individually. Symlink destinations are absolute paths into this checkout, so **keep the checkout at the same location** while the links are active.

### Remove owned links

```bash
./bin/dotfiles unlink --components zsh,tmux,nvim --dry-run
./bin/dotfiles unlink --components zsh,tmux,nvim --yes
```

Only a symlink storing the exact template path for this checkout is removed. External files/links are skipped. Fish removal preserves universal preferences, inventory and local overrides. Zsh removal covers its support/bootstrap links; tmux removal covers both the support directory and `~/.tmux.conf`.

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
| `ZSH_GLOBAL_ENV_FILE` | `/etc/zsh/zshenv` on Debian; `/etc/zshenv` on Arch/Fedora; override for custom Zsh builds |
| `OS_RELEASE_FILE` | `/etc/os-release`; alternate metadata source, primarily for tests |
| `SHELLS_FILE` | `/etc/shells`; alternate registered-shell list, primarily for tests |

Overrides must be consistent between installer runs and shell startup. In particular, a one-command custom plugin/Node location does not automatically persist that environment variable in future shells. Zsh's `local.zsh` can store its overrides; native Fish configuration can export `nvm_data`.

Some imported Fish editor values are explicitly assigned, while Zsh explicitly uses Neovim. Bash's shared editor defaults preserve an existing setting. The core configs may therefore intentionally differ in how they treat an inherited editor value.

The library computes `ROOT` from the entrypoint location, so normal commands work regardless of your current directory when invoking the script by its path.

## Troubleshooting and practical limits

| Symptom | Meaning / next step |
| --- | --- |
| `Unsupported distro` | Use config-only commands or add a supported package-family implementation |
| DNF reports `No match for argument ...` | Enable a suitable repository or choose another optional tool; no third-party repositories are enabled automatically |
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
| Fedora Atomic host package installation rejected | Use `--no-packages` for host configs and provision packages using the OS image workflow |

Additional limits:

- Repository versions, not universal upstream latest versions, are used for distro packages. Neovim gets a user runtime fallback when the distro binary is too old (Linux x86_64/aarch64); the downloaded binary must be compatible with the host glibc. Package-family support does not guarantee every optional package exists in every release.
- Fedora selects Java 21; Debian/Arch follow their distro JDK versions. JDTLS requires a recent JDK (21+); installed tools are generally not upgraded.
- Fonts, desktop terminal associations, user credentials, Git identity, SSH configuration, project environments, and local Ollama models are not provisioned.
- `install --all` manages every template, including several shells and whole application directories; preview its target list first.
- No general AUR-helper installation, automatic restoration command, or complete system rollback is provided.
- Fish preferences and Neovim’s writable plugin lockfile live in user directories. Other application directory links can still expose editable checkout files; review changes before committing.

## Repair and shell switching

Run `./bin/dotfiles setup` again to repair a failed install. CLI health checks
execute harmless version probes; package records alone never make a broken
selected tool count as ready. APT uses `--reinstall`; pacman allows same-version
reinstalls for a repair; Fedora runs `dnf reinstall` for recorded packages.
Incomplete Zsh/tmux plugins and the managed Neovim runtime are backed up before
replacement. A launcher in an unrelated PATH directory can still shadow the
repaired package: the final verification reports that failure instead of success.

Bash, Zsh and Fish expose both nvm-sh's default Node prefix and the newest locally
installed nvm.fish LTS prefix. Node, npm and globally installed commands such as
Codex therefore stay discoverable after switching shells. The native manager
still controls version selection in its own shell. Configure each shell once:

```sh
./bin/dotfiles setup --shell zsh --terminal none --tools none --keep-shell --yes
./bin/dotfiles setup --shell fish --terminal none --tools none --keep-shell --yes
```

Ordinary setup provisions Neovim's missing plugins, Mason language tools and
Treesitter parsers after linking its config. It waits for installation and
checks artifacts before reporting success. Config-only setup skips downloads.
The committed plugin lockfile seeds `$XDG_STATE_HOME/nvim/lazy-lock.json` once;
subsequent plugin operations write there. `:MasonToolsInstallSync` uses the
[upstream blocking install command](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim#commands);
`:TreesitterInstall!` waits and verifies the configured parsers. First setup can
take several minutes and requires network access.
