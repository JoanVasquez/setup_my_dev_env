"""Offline regression tests for packages."""
import subprocess

from support import InstallerTestCase, ROOT


class PackagesTests(InstallerTestCase):
    def test_token_based_distro_detection(self):
        for metadata, expected in [
            ('ID=cachyos\nID_LIKE=arch\n', 'arch'),
            ('ID=linuxmint\nID_LIKE="ubuntu debian"\n', 'debian'),
            ('ID=custom\nID_LIKE="custom arch"\n', 'arch'),
            ('ID=notarchlinux\n', 'unsupported'),
            ('ID=fedora\n', 'fedora'),
            ('ID=nobara\n', 'fedora'),
            ('ID=custom\nID_LIKE="custom fedora"\n', 'fedora'),
            ('ID=notfedora\nID_LIKE=notdebian\n', 'unsupported')]:
            self.release.write_text(metadata)
            output = self.cli("doctor")
            self.assertIn(f"Detected OS family: {expected}", output)

    def test_dry_run_makes_no_changes(self):
        self.fake_system()
        output = self.cli("setup", "--dry-run", "--shell", "fish", "--terminal", "kitty")
        self.assertIn('docker-compose-plugin', output)
        self.assertIn('nvm', output)
        self.assertFalse(self.log.exists())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_invalid_selection_changes_nothing(self):
        for args in [("setup", "--shell", "bad"), ("setup", "--tools", "git,,nvm"),
                     ("install", "--components", "fish,unknown"),
                     ("install", "--tools", "nvm"), ("setup", "--terminal")]:
            self.cli(*args, "--yes", ok=False)
            self.assertEqual(list(self.home.iterdir()), [])

    def test_unsupported_config_only(self):
        self.release.write_text("ID=alpine\n")
        self.cli("setup", "--no-packages", "--shell", "fish", "--terminal", "none",
                 "--tools", "nvim,tmux,starship,zoxide", "--yes")
        self.assertTrue((self.home / ".config/fish/config.fish").is_symlink())
        self.cli("setup", "--shell", "fish", "--terminal", "none", "--yes", ok=False)

    def test_fedora_dry_run_needs_no_package_manager_and_makes_no_changes(self):
        self.release.write_text("ID=fedora\n")
        output = self.cli("setup", "--shell", "zsh", "--terminal", "kitty",
                          "--tools", "docker,codex,aws", "--dry-run")
        self.assertIn("dnf --refresh install -y --", output)
        self.assertIn("moby-engine", output)
        self.assertIn("Install lf r42", output)
        self.assertFalse(self.log.exists())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_fedora_install_plan_and_repeat_skip(self):
        self.release.write_text("ID=fedora\nVERSION_ID=43\n")
        self.fake_system()
        args = ("setup", "--shell", "fish", "--terminal", "kitty", "--keep-shell",
                "--tools", "nvim,tmux,docker,java,codex,aws,starship", "--yes")
        output = self.cli(*args)
        log = self.log.read_text()
        self.assertIn("dnf --refresh install -y --", log)
        for package in ("moby-engine", "docker-cli", "docker-buildx", "docker-compose",
                        "java-21-openjdk-devel", "golang", "python3-pip", "tree-sitter-cli", "gnupg2"):
            self.assertIn(package, log)
        for unwanted in ("apt-get", "pacman", "dotfiles-docker.sources", "docker-ce",
                         "systemctl", "usermod", "--allowerasing", "--skip-unavailable"):
            self.assertNotIn(unwanted, log)
        self.assertIn("Install Starship", output)
        for component in ("nvim", "tmux", "kitty"):
            self.assertTrue((self.home / ".config" / component).is_symlink())
        self.cli(*args)
        self.assertEqual(self.log.read_text(), log)

    def test_fedora_rpm_inventory_skips_installed_packages(self):
        self.release.write_text("ID=fedora\n")
        self.fake_system()
        (self.base / "installed-packages").write_text("java-21-openjdk-devel\n")
        output = self.cli("packages", "--tools", "java", "--yes")
        self.assertIn("java-21-openjdk-devel", output)
        self.assertIn("dnf reinstall", self.log.read_text())

    def test_fedora_atomic_allows_configs_and_rejects_host_package_installs(self):
        self.release.write_text("ID=fedora\nVARIANT_ID=silverblue\n")
        output = self.cli("setup", "--shell", "bash", "--terminal", "none",
                          "--tools", "none", "--yes", ok=False)
        self.assertIn("Fedora Atomic/OSTree", output)
        self.assertFalse((self.home / ".bashrc").exists())
        self.cli("setup", "--shell", "bash", "--terminal", "none",
                 "--tools", "none", "--no-packages", "--yes")
        self.assertTrue((self.home / ".bashrc").is_symlink())

    def test_fedora_unavailable_package_stops_before_config_links(self):
        self.release.write_text("ID=fedora\n")
        self.fake_system()
        self.mock_command("dnf", 'printf "No match for argument: ghostty\\n" >&2; exit 1')
        self.mock_command("sudo", '"$@"')
        output = self.cli("setup", "--shell", "none", "--terminal", "ghostty",
                          "--tools", "none", "--yes", ok=False)
        self.assertIn("No match for argument: ghostty", output)
        self.assertFalse((self.home / ".config").exists())

    def test_missing_apt_terminal_does_not_link(self):
        self.fake_system()
        self.mock_command("apt-cache", 'printf "  Candidate: (none)\\n"')
        output = self.cli("setup", "--shell", "none", "--terminal", "ghostty",
                          "--tools", "none", "--yes", ok=False)
        self.assertIn("No APT candidate", output)
        self.assertFalse((self.home / ".config").exists())

    def test_installed_tools_skip_all_installation_commands(self):
        self.fake_system()
        self.seed_shell_dependencies("bash")
        for name in ("tmux", "nvim", "docker", "javac", "starship", "codex", "aws", "fzf"):
            self.mock_command(name, 'exit 0')
        for name, entry in (("tpm", "tpm"), ("tmux-resurrect", "scripts/save.sh"), ("tmux-continuum", "continuum.tmux")):
            plugin = self.home / ".tmux/plugins" / name / entry
            plugin.parent.mkdir(parents=True)
            plugin.write_text("#!/usr/bin/env bash\nexit 0\n")
            plugin.chmod(0o755)
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "tmux,nvim,docker,java,starship,codex,aws", "--yes")
        for name in ("tmux", "nvim", "docker", "java", "starship", "codex", "aws"):
            self.assertIn(f"skip: {name} already installed", output)
        self.assertNotIn("Missing tools: nvm", output)
        self.assertFalse(self.log.exists())

    def test_missing_aws_installs_once_per_user(self):
        self.fake_system()
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws", "--yes")
        self.assertIn("aws-cli/2.test", output)
        self.assertEqual(self.log.read_text().count("aws installed"), 1)
        before = self.log.read_text()
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws", "--yes")
        self.assertIn("skip: aws already installed", output)
        self.assertEqual(self.log.read_text(), before)

    def test_package_manifest_mapping_errors_are_not_swallowed(self):
        self.fake_system()
        script = f'set -euo pipefail\nROOT="{ROOT}"\nsource "$ROOT/lib/core.sh"\nsource "$ROOT/lib/packages/plan.sh"\nfamily=fedora\nmissing_components=(cachyos-fish-config)\npackage_installed() {{ return 1; }}\nbuild_packages'
        result = subprocess.run(["bash", "-c", script], env=self.env,
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No fedora package mapping", result.stderr)

    def test_zsh_profile_packages_map_on_both_distros(self):
        self.fake_system()
        for distro in ("arch", "debian"):
            self.release.write_text("ID=" + distro + "\n")
            output = self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "eza,lf", "--dry-run")
            self.assertIn("eza lf", output)
            self.assertFalse(self.log.exists())

    def test_system_zshenv_option_requires_zsh_and_dry_run_does_not_write(self):
        self.cli("setup", "--shell", "fish", "--system-zshenv", "--yes", ok=False)
        destination = self.base / "global-env"
        self.env["ZSH_GLOBAL_ENV_FILE"] = str(destination)
        output = self.cli("setup", "--shell", "zsh", "--tools", "none", "--terminal", "none", "--system-zshenv", "--dry-run")
        self.assertIn("Append XDG bootstrap", output)
        self.assertFalse(destination.exists())

    def test_broken_executable_is_reinstalled_even_when_package_is_recorded(self):
        self.fake_system()
        self.mock_command("fzf", "exit 127")
        (self.base / "installed-packages").write_text("fzf\n")
        output = self.cli("packages", "--tools", "fzf", "--yes")
        self.assertIn("Missing tools: fzf", output)
        self.assertIn("apt-get install -y --reinstall -- fzf", self.log.read_text())
        self.assertIn("Verified selected tools", output)
        before = self.log.read_text()
        self.cli("packages", "--tools", "fzf", "--yes")
        self.assertEqual(self.log.read_text(), before)

    def test_missing_executable_is_repaired_on_arch_with_installed_package(self):
        self.release.write_text("ID=arch\n")
        self.fake_system()
        (self.base / "installed-packages").write_text("fzf\n")
        self.cli("packages", "--tools", "fzf", "--yes")
        self.assertIn("pacman -S --noconfirm -- fzf", self.log.read_text())
        self.assertNotIn("--needed", self.log.read_text())

    def test_successful_package_transaction_does_not_hide_runtime_failure(self):
        self.fake_system()
        self.mock_command("fzf", "exit 126")
        self.mock_command("sudo", "exit 0")
        output = self.cli("packages", "--tools", "fzf", "--yes", ok=False)
        self.assertIn("Runtime verification failed: fzf", output)

    def test_malformed_multi_shell_choice_fails_before_changes(self):
        self.cli("setup", "--shell", "fish,zsh", "--yes", ok=False)
        self.assertFalse((self.home / ".config").exists())
