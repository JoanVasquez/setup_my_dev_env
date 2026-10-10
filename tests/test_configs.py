"""Offline regression tests for configs."""
import subprocess

from support import InstallerTestCase, ROOT


class ConfigsTests(InstallerTestCase):
    def test_backup_repeat_and_unlink_ownership(self):
        original = self.home / ".bashrc"
        original.write_text("my existing config\n")
        self.cli("install", "--components", "bash,ghostty", "--yes")
        self.assertEqual(original.resolve(), ROOT / "shell/bash/bashrc")
        backups = list((self.home / ".local/state/dotfiles/backups").rglob(".bashrc"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "my existing config\n")
        output = self.cli("install", "--components", "bash", "--yes")
        self.assertIn("already linked", output)
        self.assertEqual(len(list((self.home / ".local/state/dotfiles/backups").rglob(".bashrc"))), 1)
        original.unlink()
        original.write_text("replacement")
        self.cli("unlink", "--components", "bash,ghostty", "--yes")
        self.assertEqual(original.read_text(), "replacement")
        self.assertFalse((self.home / ".config/ghostty").exists())

    def test_fedora_all_config_templates_link_and_unlink_without_packages(self):
        self.release.write_text("ID=fedora\n")
        self.cli("install", "--all", "--yes")
        for component in ("nvim", "tmux", "kitty", "alacritty", "ghostty"):
            self.assertTrue((self.home / ".config" / component).is_symlink())
        self.assertTrue((self.home / ".local/share/konsole/Moon.colorscheme").is_symlink())
        self.cli("unlink", "--all", "--yes")
        self.assertFalse((self.home / ".bashrc").exists())
        self.assertFalse((self.home / ".config/nvim").exists())
        self.assertFalse(self.log.exists())

    def test_zsh_links_back_up_startup_files_and_preserve_local_override(self):
        directory = self.home / ".config/zsh"
        directory.mkdir(parents=True)
        (directory / ".zshrc").write_text("old XDG rc")
        (directory / "local.zsh").write_text("typeset -g MY_LOCAL_SETTING=kept\n")
        (self.home / ".zshenv").write_text("old bootstrap")
        self.cli("install", "--components", "zsh", "--yes")
        archives = self.home / ".local/state/dotfiles/backups"
        self.assertEqual(next(archives.rglob(".zshenv")).read_text(), "old bootstrap")
        self.assertEqual(next(archives.rglob(".zshrc")).read_text(), "old XDG rc")
        result = self.zsh('print -r -- "$MY_LOCAL_SETTING"')
        self.assertEqual(result.stdout.strip(), "kept")
        self.cli("unlink", "--components", "zsh", "--yes")
        self.assertFalse((directory / ".zshrc").exists())
        self.assertFalse((self.home / ".zshenv").exists())
        self.assertTrue((directory / "local.zsh").exists())
        self.assertTrue((self.home / ".cache/zsh").is_dir())

    def test_ssh_agent_units_link_repeatably_and_preserve_unrelated_services(self):
        directory = self.home / ".config/systemd/user"
        directory.mkdir(parents=True)
        unrelated = directory / "personal.service"
        unrelated.write_text("personal service\n")
        previous = directory / "ssh-agent.socket"
        previous.write_text("previous socket\n")
        output = self.cli("install", "--components", "ssh-agent", "--dry-run")
        self.assertIn("ssh-agent.service", output)
        self.assertEqual(previous.read_text(), "previous socket\n")
        self.cli("install", "--components", "ssh-agent", "--yes")
        for name in ("ssh-agent.socket", "ssh-agent.service"):
            self.assertEqual((directory / name).resolve(), ROOT / "config/systemd/user" / name)
        archives = list((self.home / ".local/state/dotfiles/backups").rglob("ssh-agent.socket"))
        self.assertEqual(len(archives), 1)
        self.assertEqual(archives[0].read_text(), "previous socket\n")
        self.cli("install", "--components", "ssh-agent", "--yes")
        self.cli("unlink", "--components", "ssh-agent", "--yes")
        self.assertFalse(previous.exists())
        self.assertFalse((directory / "ssh-agent.service").exists())
        self.assertEqual(unrelated.read_text(), "personal service\n")

    def test_tmux_startup_link_is_backed_up_and_removed(self):
        startup = self.home / ".tmux.conf"
        startup.write_text("old tmux config")
        self.cli("install", "--components", "tmux", "--yes")
        self.assertEqual(startup.resolve(), ROOT / "config/tmux/tmux.conf")
        archives = list((self.home / ".local/state/dotfiles/backups").rglob(".tmux.conf"))
        self.assertEqual(len(archives), 1)
        self.assertEqual(archives[0].read_text(), "old tmux config")
        self.cli("install", "--components", "tmux", "--yes")
        self.cli("unlink", "--components", "tmux", "--yes")
        self.assertFalse(startup.exists())
        self.assertFalse((self.home / ".config/tmux").exists())

    def test_fish_migration_keeps_universal_state_and_local_overrides(self):
        destination = self.home / ".config/fish"
        destination.parent.mkdir()
        destination.symlink_to(ROOT / "config/fish")
        original = (ROOT / "config/fish/fish_variables").read_bytes()
        self.cli("install", "--components", "fish", "--yes")
        self.assertFalse(destination.is_symlink())
        self.assertTrue((destination / "config.fish").is_symlink())
        variables = destination / "fish_variables"
        self.assertFalse(variables.is_symlink())
        variables.write_text("# local preferences\n")
        local = destination / "local.fish"
        local.write_text("set -gx DOTFILES_TEST_OVERRIDE works\n")
        self.cli("install", "--components", "fish", "--yes")
        self.assertEqual(variables.read_text(), "# local preferences\n")
        result = subprocess.run(["fish", "-c", "echo $DOTFILES_TEST_OVERRIDE"],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "works")
        self.assertEqual((ROOT / "config/fish/fish_variables").read_bytes(), original)
        self.cli("unlink", "--components", "fish", "--yes")
        self.assertTrue(variables.exists())
        self.assertTrue(local.exists())
        self.assertFalse((destination / "config.fish").exists())
