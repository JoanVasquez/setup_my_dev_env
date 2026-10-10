"""Offline regression tests for activation."""
import shutil
import subprocess

from support import InstallerTestCase, ROOT


class ActivationTests(InstallerTestCase):
    def test_fish_starts_quietly_on_debian_without_cachyos_defaults(self):
        config = self.home / ".config/fish"
        config.parent.mkdir(parents=True)
        shutil.copytree(ROOT / "config/fish", config)
        (self.home / "lib").mkdir()
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
        (self.home / "shell/common").mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "shell/common/package-aliases.tsv", self.home / "shell/common/package-aliases.tsv")
        shutil.copy2(ROOT / "shell/common/node-bin", self.home / "shell/common/node-bin")
        result = subprocess.run(["fish", "-c", 'echo $DOTFILES_OS_FAMILY; type install; cd /; pwd'], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("debian", result.stdout)
        self.assertIn("sudo apt install", result.stdout)
        self.assertTrue(result.stdout.rstrip().endswith("/"))

    def test_distro_global_zshenv_defaults_and_override(self):
        for family, expected in (("debian", "/etc/zsh/zshenv"),
                                 ("arch", "/etc/zshenv"), ("fedora", "/etc/zshenv")):
            with self.subTest(family=family):
                script = f'source "{ROOT}/lib/platform.sh"; family={family}; system_zshenv_path'
                result = subprocess.run(["bash", "-c", script], env=self.env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), expected)
        override_env = dict(self.env, ZSH_GLOBAL_ENV_FILE=str(self.base / "global"))
        result = subprocess.run(["bash", "-c", script], env=override_env,
                                text=True, capture_output=True)
        self.assertEqual(result.stdout.strip(), str(self.base / "global"))

    def test_system_zshenv_fragment_preserves_defaults_and_is_repeatable(self):
        destination = self.base / "etc/zsh/zshenv"
        destination.parent.mkdir(parents=True)
        original = '# distro configuration\nexport DISTRO_DEFAULT=kept\n'
        destination.write_text(original)
        self.env["ZSH_GLOBAL_ENV_FILE"] = str(destination)
        script = r'''
set -euo pipefail
source "$1/lib/core.sh"
source "$1/lib/platform.sh"
source "$1/lib/installers/zsh.sh"
ROOT=$1
backup_dir=$2
dry=0
system_zshenv=1
# All target paths are inside the temporary fixture; no sudo/system writes occur.
privileged() { "$@"; }
install_system_zshenv
install_system_zshenv
'''
        result = subprocess.run(["bash", "-c", script, "test", str(ROOT), str(self.base / "backups")], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        merged = destination.read_text()
        self.assertTrue(merged.startswith(original))
        self.assertEqual(merged.count("# dotfiles-pro: XDG Zsh startup"), 1)
        self.assertEqual((self.base / "backups/system/zshenv").read_text(), original)
        self.assertIn("already installed", result.stdout)

    def test_missing_selected_shell_is_installed_and_made_default(self):
        for family in ("debian", "arch"):
            with self.subTest(family=family):
                self.release.write_text("ID=" + family + "\nVERSION_CODENAME=trixie\n")
                self.fake_system()
                zsh = self.mock / "zsh"
                zsh.unlink(missing_ok=True)
                self.log.unlink(missing_ok=True)
                # Keep package inventory empty for each distro case.
                (self.base / "installed-packages").unlink(missing_ok=True)
                output = self.cli("setup", "--shell", "zsh", "--terminal", "none",
                                  "--tools", "none", "--yes")
                log = self.log.read_text()
                self.assertIn("zsh", log)
                self.assertIn(f"chsh -s {zsh}", log)
                manager = "apt-get install" if family == "debian" else "pacman -S"
                self.assertLess(log.index(manager), log.index("chsh -s"))
                self.assertIn("Default login shell set to zsh", output)
                self.assertTrue((self.home / ".zshrc").is_symlink())

    def test_installed_shell_still_becomes_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        log = self.log.read_text()
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", log)
        self.assertNotIn("apt-get", log)
        self.assertNotIn("pacman", log)

    def test_already_default_shell_skips_chsh(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.env["TEST_ACCOUNT_SHELL"] = str(self.mock / "zsh")
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        self.assertIn("already your default login shell", output)
        self.assertFalse(self.log.exists())

    def test_keep_shell_and_config_only_preserve_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        for mode in ("--keep-shell", "--no-packages"):
            self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", mode, "--yes")
            self.assertFalse(self.log.exists())

    def test_config_only_can_explicitly_change_default(self):
        self.fake_system()
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none",
                 "--no-packages", "--login-shell", "--yes")
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", self.log.read_text())
        self.assertNotIn("apt-get", self.log.read_text())

    def test_login_shell_uses_account_database_instead_of_stale_environment(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.env["SHELL"] = str(self.mock / "zsh")
        self.env["TEST_ACCOUNT_SHELL"] = "/bin/bash"
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", self.log.read_text())

    def test_unregistered_shell_cannot_become_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.shells.write_text("/bin/bash\n")
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes", ok=False)
        self.assertIn("not registered", output)
        self.assertFalse(self.log.exists())
