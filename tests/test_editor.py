"""Offline regression tests for editor."""
import subprocess

from support import InstallerTestCase, ROOT


class EditorTests(InstallerTestCase):
    def test_neovim_installs_missing_requirements_on_both_families(self):
        self.fake_system()
        self.mock_command("nvim", "exit 0")
        for distro, packages in (
            ("ubuntu", ("python3", "python3-venv", "golang-go", "openjdk-21-jdk", "gcc", "make", "ripgrep", "fd-find", "xclip", "wl-clipboard", "unzip")),
            ("arch", ("python", "go", "jdk-openjdk", "gcc", "make", "tree-sitter-cli", "ripgrep", "fd", "xclip", "wl-clipboard", "unzip")),
            ("fedora", ("python3", "python3-pip", "golang", "java-21-openjdk-devel", "gcc", "make", "tree-sitter-cli", "ripgrep", "fd-find", "xclip", "wl-clipboard", "unzip")),
        ):
            self.release.write_text(f"ID={distro}\n")
            output = self.cli("packages", "--tools", "nvim", "--dry-run")
            self.assertIn("skip: nvim already installed", output)
            requirements = next(line for line in output.splitlines() if line.startswith("Automatic requirements:"))
            for tool in ("git", "nvm", "python", "go", "java", "c-compiler", "make", "tree-sitter", "ripgrep", "fd", "clipboard"):
                self.assertIn(tool, requirements.split())
            planned = next(line for line in output.splitlines() if line.startswith("Distro packages:"))
            for package in packages:
                self.assertIn(package, planned.split())
            self.assertNotIn("neovim", planned.split())
        self.assertFalse(self.log.exists())

    def test_neovim_dependency_install_is_repeatable(self):
        self.fake_system()
        self.cli("packages", "--tools", "nvim", "--yes")
        self.assertTrue((self.home / ".local/bin/tree-sitter").is_file())
        first_log = self.log.read_text()
        self.assertIn("nvm install --lts", first_log)
        output = self.cli("packages", "--tools", "nvim", "--yes")
        self.assertIn("No missing distro packages to install", output)
        self.assertEqual(self.log.read_text(), first_log)

    def test_old_neovim_gets_user_runtime_with_launcher_backup_and_repeat_skip(self):
        self.seed_shell_dependencies("bash")
        self.fake_system()
        launcher = self.home / ".local/bin/nvim"
        launcher.parent.mkdir(parents=True, exist_ok=True)
        old_launcher = '#!/usr/bin/env bash\nprintf "NVIM v0.10.4\\n"\n'
        launcher.write_text(old_launcher)
        launcher.chmod(0o755)
        output = self.cli("packages", "--tools", "nvim", "--yes")
        self.assertIn("Ensure Neovim v0.11.5 user runtime", output)
        self.assertIn("Backed up previous Neovim launcher", output)
        self.assertTrue(launcher.is_symlink())
        self.assertTrue(launcher.resolve().is_file())
        backups = list((self.home / ".local/state/dotfiles/backups").glob("*/.local/bin/nvim"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), old_launcher)
        self.assertNotIn("neovim", self.log.read_text())
        first_log = self.log.read_text()
        output = self.cli("packages", "--tools", "nvim", "--yes")
        self.assertIn("skip: nvim already installed", output)
        self.assertEqual(self.log.read_text(), first_log)

    def test_neovim_version_requirement_and_download_failure_preserve_existing_binary(self):
        self.fake_system()
        self.seed_shell_dependencies("bash")
        for version, compatible in (("0.10.4", False), ("0.11.2", False),
                                    ("0.11.3", True), ("0.12.0-dev", True), ("1.0.0", True)):
            with self.subTest(version=version):
                self.mock_command("nvim", f'printf "NVIM v{version}\\n"')
                script = f'source "{ROOT}/lib/packages/detection.sh"; neovim_compatible'
                result = subprocess.run(["bash", "-c", script], env=self.env, capture_output=True)
                self.assertEqual(result.returncode == 0, compatible)
        self.mock_command("nvim", 'printf "NVIM v0.10.4\\n"')
        existing = (self.mock / "nvim").read_text()
        self.mock_command("curl", 'exit 1')
        self.cli("packages", "--tools", "nvim", "--yes", ok=False)
        self.assertEqual((self.mock / "nvim").read_text(), existing)
        self.assertFalse((self.home / ".local/bin/nvim").exists())

    def test_config_only_never_provisions_editor(self):
        self.mock_command("nvim", 'printf "nvim %s\\n" "$*" >> "$TEST_LOG"')
        self.cli("setup", "--shell", "none", "--terminal", "none", "--tools", "nvim",
                 "--no-packages", "--yes")
        self.assertFalse(self.log.exists())

    def test_old_java_cannot_satisfy_editor_requirements(self):
        self.fake_system()
        self.mock_command("javac", 'printf "javac 17.0.12\\n"')
        output = self.cli("packages", "--tools", "java", "--yes")
        self.assertIn("Missing tools: java", output)
        self.assertIn("openjdk-21-jdk", self.log.read_text())
        self.assertIn("Verified selected tools", output)

    def test_setup_provisions_editor_after_linking_and_propagates_failure(self):
        self.seed_shell_dependencies("zsh")
        self.mock_command("nvim", r'''if [[ "${1:-}" == --version ]]; then
    echo 'NVIM v0.11.5'; exit 0
fi
[[ -L "$XDG_CONFIG_HOME/nvim" ]] || exit 9
printf '%s\n' "$*" >> "$TEST_LOG"
exit 1''')
        output = self.cli("setup", "--shell", "none", "--terminal", "none",
                          "--tools", "nvim", "--yes", ok=False)
        self.assertIn("--headless -i NONE -S", self.log.read_text())
        self.assertIn("bootstrap.lua", self.log.read_text())
        self.assertNotIn("Setup complete", output)
