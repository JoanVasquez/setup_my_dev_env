"""Offline regression tests for shells."""
import shutil
from pathlib import Path
import subprocess

from support import InstallerTestCase, ROOT


class ShellsTests(InstallerTestCase):
    def test_aliases_cli_lists_all_shells_without_installing_or_linking(self):
        self.mock_command("zoxide", 'printf "should not execute\\n" >&2; exit 1')
        for distro, expected in (("ubuntu", "sudo apt install"),
                                 ("arch", "sudo pacman -S"), ("fedora", "sudo dnf install")):
            with self.subTest(distro=distro):
                self.release.write_text(f"ID={distro}\n")
                output = self.cli("aliases")
                for shell in ("bash", "fish", "zsh"):
                    self.assertIn(f"[{shell} aliases]", output)
                install_aliases = [line for line in output.splitlines() if line.startswith("alias install")]
                self.assertEqual(len(install_aliases), 3)
                for line in install_aliases:
                    self.assertIn(expected, line)
                self.assertIn("docker compose up -d", output)
                self.assertNotIn("alias cd z", output)
                self.assertNotIn("should not execute", output)
                self.assertFalse(self.log.exists())
                self.assertEqual(list(self.home.iterdir()), [])

    def test_aliases_cli_single_shell_auto_missing_shell_and_validation(self):
        output = self.cli("aliases", "--shell", "zsh")
        self.assertIn("[zsh aliases]", output)
        self.assertNotIn("[fish aliases]", output)
        self.assertNotIn("[bash aliases]", output)
        output = self.cli("aliases", "--shell", "auto")
        self.assertIn("[bash aliases]", output)
        self.cli("aliases", "--shell", "none", ok=False)
        (self.mock / "fish").unlink()
        output = self.cli("aliases")
        self.assertIn("[fish] skipped: shell is not installed", output)
        self.assertIn("[zsh aliases]", output)
        output = self.cli("aliases", "--shell", "fish", ok=False)
        self.assertIn("shell is not installed", output)
        self.cli("aliases", "--tools", "none", ok=False)

    def test_live_aliases_function_includes_session_aliases_in_every_shell(self):
        for shell in ("bash", "zsh", "fish"):
            with self.subTest(shell=shell):
                if shell == "fish":
                    script = f'source "{ROOT}/config/fish/functions/aliases.fish"\nalias user_example "echo session addition"\naliases'
                    arguments = ["--no-config", "-c"]
                else:
                    filename = "shell/common/functions.sh" if shell == "bash" else "config/zsh/functions.zsh"
                    script = f'source "{ROOT}/{filename}"\nalias user_example="echo session addition"\naliases'
                    arguments = ["-fc"]
                result = subprocess.run([shutil.which(shell), *arguments, script],
                                        env=self.env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("user_example", result.stdout)
                self.assertIn("echo session addition", result.stdout)
                self.assertFalse(self.log.exists())

    def test_local_bin_and_debian_aliases_are_detected(self):
        self.fake_system()
        local_bin = self.home / ".local/bin"
        local_bin.mkdir(parents=True)
        (local_bin / "aws").write_text("#!/usr/bin/env bash\nexit 0\n")
        (local_bin / "aws").chmod(0o755)
        self.mock_command("batcat", 'exit 0')
        self.mock_command("fdfind", 'exit 0')
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws,bat,fd", "--yes")
        self.assertIn("skip: aws already installed", output)
        self.assertIn("skip: bat already installed", output)
        self.assertIn("skip: fd already installed", output)
        self.assertFalse(self.log.exists())

    def test_legacy_fzf_files_initialize_bash_and_fish(self):
        self.mock_command("fzf", 'exit 1')
        directory = self.home / ".fzf/shell"
        directory.mkdir(parents=True)
        (directory / "key-bindings.bash").write_text('export FZF_BINDINGS_READY=yes\n')
        (directory / "completion.bash").write_text('export FZF_COMPLETION_READY=yes\n')
        script = f'DOTFILES_SHELL=bash\nsource "{ROOT}/shell/common/integrations.sh"\nprintf "%s|%s" "$FZF_BINDINGS_READY" "$FZF_COMPLETION_READY"'
        result = subprocess.run(["bash", "-c", script], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "yes|yes")
        (directory / "key-bindings.fish").write_text('set -gx FZF_BINDINGS_READY yes\n')
        script = f'source "{ROOT}/config/fish/conf.d/dotfiles-environment.fish"\nsource "{ROOT}/config/fish/config.fish"\nprintf "%s" "$FZF_BINDINGS_READY"'
        result = subprocess.run([shutil.which("fish"), "--no-config", "-ic", script],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "yes")
        self.assertNotIn("nvm:", result.stderr)

    def test_package_aliases_execute_for_all_shells_and_distro_families(self):
        self.mock_command("sudo", '"$@"')
        for executable in ("apt", "apt-cache", "pacman", "dnf"):
            self.mock_command(executable, f'printf "{executable} %s\\n" "$*" >> "$TEST_LOG"')
        for release, family in (
            ('ID=ubuntu\nVERSION_ID=22.04\n', "debian"),
            ('ID=debian\nVERSION_ID=13\n', "debian"),
            ('ID=linuxmint\n', "debian"),
            ('ID=pop\n', "debian"),
            ('ID=custom\nID_LIKE="custom ubuntu debian"\n', "debian"),
            ('ID=arch\n', "arch"),
            ('ID=cachyos\n', "arch"),
            ('ID=custom\nID_LIKE="custom arch"\n', "arch"),
            ('ID=fedora\nVERSION_ID=43\n', "fedora"),
            ('ID=nobara\n', "fedora"),
            ('ID=custom\nID_LIKE="custom fedora"\n', "fedora"),
        ):
            self.release.write_text(release)
            for shell in ("bash", "zsh", "fish"):
                with self.subTest(release=release, shell=shell):
                    self.log.unlink(missing_ok=True)
                    if shell == "fish":
                        script = f'source "{ROOT}/config/fish/conf.d/dotfiles-environment.fish"\nsource "{ROOT}/config/fish/config.fish"'
                        arguments = ["--no-config", "-c"]
                    else:
                        script = f'DOTFILES_HOME="{ROOT}"\nsource "$DOTFILES_HOME/lib/platform.sh"\nsource "$DOTFILES_HOME/shell/common/platform.sh"'
                        if shell == "bash":
                            script = 'shopt -s expand_aliases\n' + script
                        arguments = ["-fc"]
                    commands = 'update\ninstall "package name"\nremove old-package\nsearch "search words"\n'
                    if shell == "zsh":
                        # Zsh parses a -c script before sourced aliases are defined.
                        script += "\neval '" + commands + "'"
                    else:
                        script += '\n' + commands
                    result = subprocess.run([shutil.which(shell), *arguments, script],
                                            env=self.env, text=True, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    expected = (
                        ["apt update", "apt upgrade", "apt install package name", "apt remove old-package", "apt-cache search search words"]
                        if family == "debian" else
                        ["dnf upgrade --refresh", "dnf install package name", "dnf remove old-package", "dnf search search words"]
                        if family == "fedora" else
                        ["pacman -Syu", "pacman -S package name", "pacman -Rns old-package", "pacman -Ss search words"]
                    )
                    self.assertEqual(self.log.read_text().splitlines(), expected)

    def test_fish_debian_names_xdg_paths_and_wayland_clipboard(self):
        self.mock_command("batcat", 'exit 0')
        self.mock_command("fdfind", 'exit 0')
        self.mock_command("wl-copy", 'printf "clipboard\\n" >> "$TEST_LOG"')
        self.mock_command("nvim", 'printf "%s\\n" "$@" >> "$TEST_LOG"')
        script = f'source "{ROOT}/config/fish/conf.d/dotfiles-environment.fish"\nsource "{ROOT}/config/fish/config.fish"\n'
        script += 'cfish\ncnvim\nxcopy\nprintf "%s\\n" "$MANPAGER"\nfunctions bat fd\n'
        result = subprocess.run([shutil.which("fish"), "--no-config", "-c", script],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.log.read_text().splitlines(),
                         [str(self.home / ".config/fish/config.fish"),
                          str(self.home / ".config/nvim"), "clipboard"])
        self.assertIn("batcat -l man -p", result.stdout)
        self.assertIn("batcat $argv", result.stdout)
        self.assertIn("fdfind $argv", result.stdout)

    def test_shell_helpers_preserve_docker_arguments_and_tmux_shell_quoting(self):
        self.mock_command("docker", 'printf "%s\\n" "$@" >> "$TEST_LOG"')
        self.mock_command("tmux", '[[ "$1" == run-shell ]] && exec sh -c "$2"')
        scripts = self.home / ".tmux/plugins/tmux-resurrect/scripts"
        scripts.mkdir(parents=True)
        for name in ("save", "restore"):
            target = scripts / f"{name}.sh"
            target.write_text(f'#!/bin/sh\nprintf "{name}\\n" >> "$TEST_LOG"\n')
            target.chmod(0o755)
        for shell in ("fish", "zsh"):
            with self.subTest(shell=shell):
                self.log.unlink(missing_ok=True)
                result = self.configured_shell(shell, 'dbf "Dockerfile dev" "image:dev" "context\nsecond line"\ndbf\ntsave\ntrestore')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.log.read_text().splitlines(),
                                 ["build", "-f", "Dockerfile dev", "-t", "image:dev", "context", "second line",
                                  "build", "-f", "Dockerfile", "-t", "latest-app", ".", "save", "restore"])

    def test_shell_clipboard_prefers_wayland_and_grep_keeps_grep_options(self):
        self.env["WAYLAND_DISPLAY"] = "wayland-0"
        self.mock_command("xclip", 'printf "xclip\\n" >> "$TEST_LOG"')
        self.mock_command("wl-copy", 'printf "wayland\\n" >> "$TEST_LOG"')
        self.mock_command("rg", 'exit 42')
        for shell in ("fish", "zsh"):
            with self.subTest(shell=shell):
                self.log.unlink(missing_ok=True)
                result = self.configured_shell(shell, "xcopy\nprintf 'a\\nb\\n' | grep -G '^a$'")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "a\n")
                self.assertEqual(self.log.read_text(), "wayland\n")

    def test_fish_native_cd_works_when_zoxide_exists_without_initialization(self):
        self.mock_command("zoxide", 'exit 0')
        self.env["DOTFILES_ALIAS_LISTING"] = "1"
        result = self.configured_shell("fish", 'cd /\ncd "$HOME"\ncd - >/dev/null\npwd')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "/\n")

    def test_shared_ssh_agent_preserves_forwarding_and_requires_runtime_directory(self):
        self.cli("install", "--components", "fish,zsh", "--yes")
        for shell in ("fish", "zsh"):
            for connection, tty, runtime, expected in (
                ("", "", "/run/user/1234", "/run/user/1234/ssh-agent.socket"),
                ("remote", "", "/run/user/1234", "/forwarded/agent"),
                ("", "/dev/pts/1", "/run/user/1234", "/forwarded/agent"),
                ("", "", "", "/forwarded/agent"),
            ):
                with self.subTest(shell=shell, connection=connection, tty=tty, runtime=runtime):
                    env = dict(self.env, SSH_CONNECTION=connection, SSH_TTY=tty,
                               XDG_RUNTIME_DIR=runtime, SSH_AUTH_SOCK="/forwarded/agent")
                    result = subprocess.run([shutil.which(shell), "-ic", 'printf "%s" "$SSH_AUTH_SOCK"'],
                                            env=env, text=True, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout, expected)

    def test_fish_git_picker_filters_head_and_preserves_cancellation(self):
        self.env["BRANCH_INPUT"] = str(self.base / "branches")
        self.mock_command("git", r'''case "$1" in
    rev-parse) exit 0 ;;
    for-each-ref) printf 'main\norigin/main\norigin/feature\norigin/HEAD\nupstream/HEAD\n' ;;
    switch) printf '%s\n' "$@" > "$TEST_LOG" ;;
esac''')
        self.mock_command("fzf", 'cat > "$BRANCH_INPUT"; printf "feature\\n"')
        result = self.configured_shell("fish", 'gcofzf')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(self.env["BRANCH_INPUT"]).read_text().splitlines(), ["feature", "main"])
        self.assertEqual(self.log.read_text().splitlines(), ["switch", "--", "feature"])
        self.log.unlink()
        self.mock_command("fzf", 'cat >/dev/null; printf "feature\\n"; exit 130')
        result = self.configured_shell("fish", 'gcofzf')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())

    def test_process_picker_ignores_headers_and_cancelled_selections(self):
        self.mock_command("kill", 'printf "%s\\n" "$@" >> "$TEST_LOG"')
        for shell in ("fish", "zsh"):
            for selection, exit_status in (("PID COMMAND", 0), ("123 process", 130), ("123 process", 0)):
                with self.subTest(shell=shell, selection=selection, status=exit_status):
                    self.log.unlink(missing_ok=True)
                    self.mock_command("fzf", f'cat >/dev/null; printf "{selection}\\n"; exit {exit_status}')
                    result = self.configured_shell(shell, 'killfzf')
                    self.assertEqual(result.returncode, 0, result.stderr)
                    if selection.startswith("123") and exit_status == 0:
                        self.assertEqual(self.log.read_text().splitlines(), ["-9", "--", "123"])
                    else:
                        self.assertFalse(self.log.exists())

    def test_shells_resolve_symlinked_repo(self):
        self.cli("install", "--components", "bash,zsh,fish", "--yes")
        for executable, args in [
            ("bash", ["--noprofile", "--rcfile", str(self.home / ".bashrc"), "-ic", 'printf "%s" "$DOTFILES_HOME"']),
            ("zsh", ["-ic", 'printf "%s" "$DOTFILES_HOME"'])]:
            result = subprocess.run([executable, *args], env=self.env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(ROOT), result.stdout)
        # Runtime universal-variable updates must stay in the temporary home,
        # not in the repository behind the installer's directory symlink.
        fish_config = self.home / ".config/fish"
        # The installer now gives Fish a real directory with writable state.
        self.assertFalse((fish_config / "fish_variables").is_symlink())
        (self.home / "lib").mkdir(exist_ok=True)
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
        (self.home / "shell/common").mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "shell/common/package-aliases.tsv", self.home / "shell/common/package-aliases.tsv")
        shutil.copy2(ROOT / "shell/common/node-bin", self.home / "shell/common/node-bin")
        result = subprocess.run(["fish", "-c", "type nvm; type install"], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo apt install", result.stdout)

    def test_fish_fzf_uses_compatible_commands_and_real_debian_binary_names(self):
        self.mock_command("fdfind", "exit 0")
        self.mock_command("batcat", "exit 0")
        self.cli("install", "--components", "fish", "--yes")
        result = subprocess.run(["fish", "-c",
                                 'printf "%s\\n" "$FZF_CTRL_T_COMMAND" "$FZF_CTRL_T_OPTS" "$FZF_ALT_C_OPTS"'],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("fdfind --type f", result.stdout)
        self.assertIn("batcat --color", result.stdout)
        self.assertNotIn("--walker-skip", result.stdout)
