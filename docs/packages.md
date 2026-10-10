# Packages

[Project home](../README.md)

## Automatic dependencies

[packages/dependencies.tsv](../packages/dependencies.tsv) is the central profile/tool manifest. [lib/packages/dependencies.sh](../lib/packages/dependencies.sh) expands it recursively, removes duplicate nodes, and handles cycles such as tmux/TPM references without repeatedly scheduling them.

| Selection | Automatic requirements |
| --- | --- |
| Bash | Git, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, nvm/Node LTS |
| Zsh | Git, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, eza, lf, nvm/Node LTS, clipboard helpers, four Zsh plugins |
| Fish | Git, Vim, Neovim, Starship, zoxide, fzf, bat, fd, ripgrep, eza, tree, native nvm/Node LTS, clipboard helpers |
| Fish on CachyOS | Also CachyOS Fish defaults, fastfetch, and `col` |
| Neovim | Git, nvm/Node LTS, Python with venv, Go, JDK, C compiler, make, Tree-sitter CLI, ripgrep, fd, clipboard helpers, curl, tar, unzip, gzip |
| tmux | fzf and TPM; TPM brings Git, tmux-resurrect, and tmux-continuum |
| Explicit TPM | tmux and Git, with tmux's requirements resolved too |
| Zsh plugins | Git |
| Missing Codex | nvm/Node LTS; an already-present Codex does not add another nvm installation just to be skipped |
| Standalone Java | The distro JDK package |

Fish includes **Vim** because your imported `EDITOR`/`VISUAL` values are `vim`; it also includes **Neovim** for your configured editing helpers. Bash/Zsh use Neovim as their editor default.

Aliases for Docker, AWS, Java-related project work, or tmux do not automatically make every optional application a shell requirement. The shell manifest covers active shell/editor/prompt/navigation modules. Neovim's language-specific servers, formatters, parser builds, and local AI setup have their separate lifecycle below.

Shell selections that require Neovim also inherit its requirements, including the JDK.

When a resolved requirement has a repository config (`nvim`, `tmux`, or `starship`), setup links it too. The package manager independently resolves system-library dependencies.

Manual download prerequisites are scoped to the installer using them:

- Debian/Fedora Starship downloads need certificate/downloader/archive utilities.
- Fedora lf uses an upstream standalone release in `~/.local/bin`, with downloader/archive prerequisites.
- nvm/Node downloads need certificate/downloader/archive utilities.
- AWS needs its downloader and supporting archive/signature/documentation packages.
- A missing Debian Docker engine needs the certificate/downloader path for its signed repository key.
- Repository-only Java installation does not add Git, curl, nvm, or shell tools.

There is no blanket development-stack installation for every standalone package request.

## Detection and repeat runs

Shell suggestions prefer `$SHELL`, then the account database, with Bash as the supported fallback. Default-shell activation separately reads the account database so a stale inherited `$SHELL` does not incorrectly skip `chsh`.

Terminal detection checks `TERM_PROGRAM`, Konsole/Kitty environment markers, and `TERM`. If those clues are absent, it suggests the first available executable in this order: Kitty, Konsole, Alacritty, Ghostty. Otherwise the result is `none`. On SSH or inside another session, this may be an installed-terminal suggestion rather than the physical terminal you are using; explicit flags select the intended target.

The installer adds `~/.local/bin` to its own PATH before probes.

| Tool/group | Installed condition |
| --- | --- |
| Most CLI tools | Expected executable successfully runs a harmless version probe (bounded to 10 seconds when `timeout` is available) |
| Java | Runnable `javac` reporting JDK 21+, as required by JDTLS |
| ripgrep | `rg` |
| fd | `fd` or Debian's `fdfind` |
| bat | `bat` or Debian's `batcat` |
| Clipboard | Both `xclip` and `wl-copy`; only missing halves are requested |
| Docker | Docker CLI and successful `docker compose version` |
| Bash/Zsh nvm | `nvm.sh`, a runnable default Node, its LTS release marker and working npm |
| Fish nvm | Valid local nvm index matching a runnable installed LTS Node, plus working npm |
| Codex | PATH, a native Fish LTS bin directory, or nvm-sh's default environment |
| Zsh plugins | All declared nonempty entrypoint files in the plugin directory |
| tmux plugin bundle | Executable entrypoints for TPM, resurrect, and continuum |
| CachyOS Fish defaults | The distro config file exists at its expected system location |

A Node probe recognizes an installed LTS release, not whether it is the newest release or still within its upstream support window. Health probes test startup, not service connectivity, authentication or every application feature. Neovim and Java also enforce the configuration minimum versions.

Repeat runs preserve compatible existing programs/plugin versions. Neovim is also checked against the configuration minimum version. They install missing profile requirements even if the selected shell itself exists. Setup verifies selected tool health after installation and before declaring success. Matching config links are skipped; links from another checkout are backed up/replaced when applying this checkout.

If all resolved tools are healthy, no system package-manager call is needed. Neovim setup still checks its plugins, language tools and parsers, installing missing artifacts. Config linking, an explicit global Zsh request, or a required login-shell/Docker service change can still occur. Setup is not an updater: use normal distro/tool/plugin update commands when you want upgrades.

## Distribution packages

[packages/components.tsv](../packages/components.tsv) maps logical names to repository packages.

| Component | Debian-family package | Arch-family package | Fedora-family package |
| --- | --- | --- | --- |
| Bash / Fish / Zsh | `bash` / `fish` / `zsh` | Same | Same |
| Git / Neovim / tmux | `git` / `neovim` / `tmux` | Same | Same |
| Vim | `vim` | `vim` | `vim-enhanced` |
| fzf / zoxide / bat / ripgrep | Matching package names | Same | Same |
| fd | `fd-find` | `fd` | `fd-find` (executable `fd`) |
| Java JDK | `openjdk-21-jdk` | `jdk-openjdk` | `java-21-openjdk-devel` |
| Python + venv | `python3`, `python3-venv` | `python` | `python3`, `python3-pip` |
| Go | `golang-go` | `go` | `golang` |
| C compiler / make | `gcc`, `make` | Same | Same |
| Tree-sitter CLI | Upstream binary | `tree-sitter-cli` | `tree-sitter-cli` |
| eza / tree / fastfetch | Matching package names | Same | Same |
| lf | `lf` | `lf` | Upstream r42 binary |
| Kitty / Konsole / Alacritty / Ghostty | Matching package names, if available | Same | Same, from configured repositories |
| Clipboard | `xclip`, `wl-clipboard` | Same | Same |
| `col` | `bsdextrautils` | `util-linux` | `util-linux` |
| `chsh` (when needed for login-shell activation) | `passwd` | `util-linux` | `util-linux` |
| CachyOS Fish defaults | Not requested | `cachyos-fish-config`, only on CachyOS | Not requested |

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

### DNF

Fedora-family installs consult RPM for prerequisites. A missing or broken selected tool still schedules its packages; packages already recorded by RPM receive `dnf reinstall`. New packages use syntax shared by DNF4 and DNF5:

```text
sudo dnf --refresh install -y -- <missing-packages>
```

Unavailable package names or dependency conflicts abort the transaction before config linking. Setup does not use `--skip-unavailable`, `--allowerasing`, or a system-wide upgrade. Starship and lf use upstream user installations; Docker uses Fedora's native Moby stack. Ghostty may require a separately configured repository on Debian/Fedora; setup does not automatically enable PPAs or COPRs. See [Ghostty's package guidance](https://ghostty.org/docs/install/binary).

Repository availability and versions vary. For example, older APT releases may lack eza/Ghostty or provide Neovim/fzf versions older than the configs expect. Installed tools are normally skipped rather than silently replaced with newer builds.
