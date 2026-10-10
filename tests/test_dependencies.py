"""Offline regression tests for dependencies."""


from support import InstallerTestCase


class DependenciesTests(InstallerTestCase):
    def test_zsh_requirements_are_automatic_even_with_tools_none(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--dry-run")
        self.assertIn("Optional tools: none", output)
        line = next(line for line in output.splitlines() if line.startswith("Automatic requirements:"))
        for tool in ("git", "nvim", "starship", "zoxide", "fzf", "bat", "fd", "ripgrep", "eza", "lf", "nvm", "clipboard", "zsh-plugins"):
            self.assertIn(tool, line.split())
        self.assertIn("java", line.split())
        self.assertNotIn("docker", line.split())
        self.assertFalse(self.log.exists())

    def test_fish_requirements_are_automatic_and_distro_specific(self):
        self.fake_system()
        for distro in ("ubuntu", "cachyos"):
            self.release.write_text("ID=" + distro + "\nID_LIKE=" + ("debian" if distro == "ubuntu" else "arch") + "\n")
            output = self.cli("packages", "--shell", "fish", "--terminal", "none", "--tools", "none", "--dry-run")
            line = next(line for line in output.splitlines() if line.startswith("Automatic requirements:"))
            for tool in ("git", "vim", "nvim", "starship", "zoxide", "fzf", "bat", "tree", "nvm", "clipboard"):
                self.assertIn(tool, line.split())
            self.assertEqual("cachyos-fish-config" in line.split(), distro == "cachyos")
            self.assertEqual("fastfetch" in line.split(), distro == "cachyos")
        self.assertFalse(self.log.exists())

    def test_java_alone_only_installs_jdk(self):
        self.fake_system()
        output = self.cli("packages", "--tools", "java", "--yes")
        self.assertIn("Automatic requirements: none", output)
        self.assertIn("Distro packages: openjdk-21-jdk", output)
        log = self.log.read_text()
        self.assertIn("-- openjdk-21-jdk", log)
        for unwanted in ("curl", "git", "nvm", "neovim", "fzf", "starship", "ca-certificates"):
            self.assertNotIn(unwanted, log)

    def test_tmux_requirements_resolve_cycles_without_duplicates(self):
        self.fake_system()
        output = self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "tmux,tpm", "--dry-run")
        line = next(line for line in output.splitlines() if line.startswith("Missing tools:"))
        self.assertEqual(line.split().count("tmux"), 1)
        self.assertEqual(line.split().count("tpm"), 1)
        self.assertEqual(line.split().count("fzf"), 1)
        self.assertEqual(output.count("https://github.com/tmux-plugins/tpm"), 1)

    def test_config_only_profiles_resolve_requirements_but_do_not_install_them(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "java", "--no-packages", "--yes")
        self.assertIn("Automatic requirements:", output)
        self.assertIn("Package installation: skipped", output)
        self.assertFalse(self.log.exists())
        self.assertTrue((self.home / ".config/zsh/.zshrc").is_symlink())

    def test_arch_install_and_codex_dependency(self):
        self.release.write_text("ID=cachyos\nID_LIKE=arch\n")
        self.fake_system()
        self.cli("setup", "--shell", "fish", "--terminal", "ghostty", "--tools",
                 "codex,docker,java,starship", "--enable-docker", "--yes")
        log = self.log.read_text()
        self.assertIn("pacman -S --needed", log)
        self.assertIn("jdk-openjdk", log)
        self.assertIn("ghostty", log)
        self.assertIn("docker-compose", log)
        self.assertIn("nvm.fish install lts", log)
        self.assertIn("npm install -g @openai/codex", log)
        self.assertIn("systemctl enable --now docker", log)
        self.assertTrue((self.home / ".config/fish/config.fish").is_symlink())

    def test_missing_chsh_is_an_automatic_activation_dependency(self):
        self.release.write_text("ID=fedora\n")
        self.fake_system()
        (self.mock / "chsh").unlink()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none",
                          "--tools", "none", "--dry-run")
        self.assertIn("chsh", output)
        self.assertIn("util-linux", output)
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none",
                          "--tools", "none", "--keep-shell", "--dry-run")
        self.assertNotIn(" chsh", output)
        self.assertNotIn("util-linux", output)
