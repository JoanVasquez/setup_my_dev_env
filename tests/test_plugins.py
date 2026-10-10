"""Offline regression tests for plugins."""


from support import InstallerTestCase, ROOT


class PluginsTests(InstallerTestCase):
    def test_tmux_install_fetches_configured_plugins_without_extra_choices(self):
        self.fake_system()
        self.cli("packages", "--tools", "tmux", "--yes")
        log = self.log.read_text()
        for name in ("tpm", "tmux-resurrect", "tmux-continuum"):
            self.assertIn("https://github.com/tmux-plugins/" + name, log)
        before = log
        self.cli("packages", "--tools", "tmux", "--yes")
        self.assertEqual(self.log.read_text(), before)

    def test_zsh_plugins_install_once_and_startup_stays_offline(self):
        self.fake_system()
        self.mock_zsh_plugin_clones()
        self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "zsh-plugins", "--yes")
        before = self.log.read_text()
        self.assertEqual(before.count("git clone"), 4)
        self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "zsh-plugins", "--yes")
        self.assertEqual(self.log.read_text(), before)
        self.cli("install", "--components", "zsh", "--yes")
        result = self.zsh('print -r -- "${#dotfiles_test_plugins}|$ZVM_INSERT_MODE_CURSOR"; bindkey -M viins "^F"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("4|beam", result.stdout)
        self.assertIn("_fzf_file_no_hidden", result.stdout)
        self.assertEqual(self.log.read_text(), before)
        self.assertFalse((ROOT / "config/zsh/plugins").exists())

    def test_zsh_plugin_partial_install_only_clones_missing_plugins(self):
        self.fake_system()
        self.mock_zsh_plugin_clones()
        directory = self.home / ".local/share/zsh/plugins/zsh-autosuggestions"
        directory.mkdir(parents=True)
        (directory / "zsh-autosuggestions.zsh").write_text("# already installed\n")
        self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "zsh-plugins", "--yes")
        log = self.log.read_text()
        self.assertEqual(log.count("git clone"), 3)
        self.assertNotIn("https://github.com/zsh-users/zsh-autosuggestions.git", log)

    def test_incomplete_plugin_is_replaced_and_original_is_preserved(self):
        self.fake_system()
        destination = self.home / ".local/share/zsh/plugins/zsh-autosuggestions"
        destination.mkdir(parents=True)
        (destination / "local-notes").write_text("keep my changes")
        (destination / "zsh-autosuggestions.zsh").touch()
        output = self.cli("packages", "--tools", "zsh-plugins", "--yes")
        self.assertIn("backup:", output)
        self.assertGreater((destination / "zsh-autosuggestions.zsh").stat().st_size, 0)
        backups = list((self.home / ".local/state/dotfiles/backups").rglob("local-notes"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "keep my changes")
        before = self.log.read_text()
        self.cli("packages", "--tools", "zsh-plugins", "--yes")
        self.assertEqual(self.log.read_text(), before)
