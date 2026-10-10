# CLI reference

[Project home](../README.md)

## Command reference

```text
./bin/dotfiles [setup|install|packages|doctor|aliases|unlink] [options]
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
| `aliases` | No | No | No |

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
bash,zsh,fish,tmux,nvim,starship,kitty,alacritty,konsole,ghostty,ssh-agent
```

Without either selection, `install` and `unlink` use configs for supported programs found on PATH, plus the detected login shell. This can include several shells/terminals. An explicit `--components` list takes precedence over `--all` if both are supplied. No dependency installation occurs through these commands.

### Shared SSH agent

Fish and Zsh use `$XDG_RUNTIME_DIR/ssh-agent.socket` in local sessions when a runtime
directory is available. SSH sessions retain their forwarded agent. Install the
socket and matching service with:

```sh
./bin/dotfiles install --components ssh-agent --yes
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.socket
```

The units link individually into `$XDG_CONFIG_HOME/systemd/user` (by default
`~/.config/systemd/user`), preserving unrelated services. Reinstall your Fish or
Zsh component to load the shell configuration if it is not already linked.
The installer links configuration; the commands above activate it.

Requires a systemd user session and OpenSSH 10.0 or newer, or a distribution build
with socket activation backported. See the [OpenSSH 10.0 release notes](https://www.openssh.org/txt/release-10.0).
The service runs `ssh-agent -D` without `-a` so it inherits systemd's listening
socket. It starts on the first connection, so it can be inactive until `ssh-add`
or SSH uses the socket.

```sh
systemctl --user status ssh-agent.socket ssh-agent.service
ssh-add ~/.ssh/id_ed25519
```

To disable activation and stop an already running agent:

```sh
systemctl --user disable --now ssh-agent.socket
systemctl --user stop ssh-agent.service
```

Before removing the managed units, stop them as above, then run:

```sh
./bin/dotfiles unlink --components ssh-agent --yes
systemctl --user daemon-reload
```

### Packages-only option

`--extra` adds the missing packages for all four terminals and clipboard tools. It does not link their configs. It can fail if an enabled repository has no candidate for one of them, such as Ghostty on an older APT release.
