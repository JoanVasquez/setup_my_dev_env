# Contributing

[Project home](../README.md)

## Project structure and extension

```text
bin/dotfiles                 Stable executable: load, parse, initialize, dispatch
bin/check                    Offline syntax and regression checks
lib/bootstrap.sh             Explicit library loading order
lib/core.sh                  Validation, logging, privilege and download helpers
lib/platform.sh              Shared Bash/Zsh-compatible distro and shell detection
lib/cli/                     Selection catalog, help, arguments, runtime, dispatch
lib/commands/                Packages-only handler, doctor, alias listing
lib/setup/                   Wizard, resolved plan, login-shell change, execution
lib/ui/                      Dependency-free menus and confirmation
lib/config/                  Paths, component selection, links, profiles, Fish migration
lib/packages/                Health probes, dependencies, package plan, manager, vendors
lib/installers/              One module per vendor/runtime or plugin bundle
packages/                    Distro mappings, dependency and tmux-plugin manifests
shell/                       Bash/Zsh startup bridges and shared shell helpers
config/                      Application templates, plugins, and per-app guides
docs/                        User guides and maintenance/development reference
scripts/                     Offline syntax-check helpers
tests/support.py             Temporary-home fixtures and mocked system commands
tests/test_*.py              Behavior suites grouped by subsystem
```

Follow `bin/dotfiles` into `lib/bootstrap.sh` and `lib/cli/dispatch.sh`. Setup runs
through `lib/setup/execute.sh`: collect preferences, resolve and verify the plan,
confirm, install, link, bootstrap the editor, and activate the login shell.
`packages` uses the same planning and installation pipeline without linking.

The installer deliberately runs in one Bash process. Modules define functions;
`lib/cli/catalog.sh` owns public selection lists and unattended tool defaults;
`parse_arguments` sets per-run options. Runtime initialization sets platform and
backup paths. Planning owns `chosen`, `package_components`, `resolved_components`,
`automatic_components`, `missing_components`, `installed_components`, `pkgs`, and
`repair_pkgs`. Installers consume these arrays after final confirmation.
Use local variables for temporary values so modules do not overwrite one another.

Application paths under `config/` and `shell/`, and the shared `lib/platform.sh`,
remain stable because installed symlinks and shell startup files reference them.
Keep mutable history, caches, plugin installs, and editor state outside the checkout.
Fish's imported Tide/Fisher/nvm files remain together in the layout Fish expects;
its installer links source files individually and preserves user-owned state.

To extend the project:

1. Add a public logical tool to `lib/cli/catalog.sh`; help and validation use the catalog.
2. Add distro mappings to `packages/components.tsv`, or an installer in `lib/installers/` and a dispatch case in `lib/packages/vendors.sh`.
3. Add automatic requirements to `packages/dependencies.tsv`.
4. Add composite/version probes to `lib/packages/detection.sh` where command presence is insufficient.
5. For configuration, add the component to the catalog and its mappings to `lib/config/paths.sh`. Multiple-file handling belongs in `lib/config/profiles.sh` or `lib/config/fish.sh`.
6. Register new modules in `lib/bootstrap.sh`; its explicit order avoids filesystem-dependent loading.
7. Add regression coverage to the relevant test module and update the relevant guide.

`--tools` names identify logical installations; `--components` names identify
configuration targets. Internal dependency grouping nodes are not public apps.


## Validation and tests

Install Python 3, Bash, Fish, and Zsh to run the behavior suite:

```bash
python3 -m unittest discover -s tests -v
```

The suite uses temporary homes/XDG directories, synthetic distro metadata, a restricted PATH, mocked package/network commands, and pseudo-terminals for real prompt behavior. It does not perform real package installations or contact upstream download hosts.

Coverage includes:

- Whole-token Debian/Arch/Fedora detection and unsupported-distro config-only behavior.
- Dependency recursion/deduplication, automatic shell profiles, hidden dependency questions, standalone Java/Node isolation.
- Backups, matching-link skips, ownership-safe removal, tmux's startup link, and Zsh support links.
- Shell installation/default activation, already-default skips, stale `$SHELL`, registered-shell validation, opt-outs.
- AWS install/skip behavior, nvm LTS handling, native Fish Codex detection.
- Debian/Arch/Fedora plans, RPM package skipping, Docker/Podman provider conflicts, Compose-only preservation, explicit service settings.
- Quiet XDG Zsh startup, history/completion, aliases, keybindings, fzf quoting/option restoration, lf directory changes.
- Plugin bundles, partial installs, repeat runs, startup without download attempts.
- Portable Fish startup and repeatable global-zshenv merging inside a temporary fixture.

Run all shell/Lua syntax checks and regression tests together:

```bash
./bin/check
```

The tests are grouped into activation, configs, dependencies, Docker, editor,
Node, packages, plugin bundles, shell runtime, tmux, wizard, Zsh, and menu suites.
Shared fixtures live in `tests/support.py`. To run one subsystem:

```bash
python3 -m unittest discover -s tests -p 'test_docker.py' -v
```

A passing mocked suite is not a real package-download, daemon, terminal-rendering, or full Neovim language-tool installation test. Use `doctor`, application health commands, and the printed installation plan on the target machine.
