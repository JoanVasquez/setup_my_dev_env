"""Offline regression tests for node."""
import shutil
import subprocess

from support import InstallerTestCase, ROOT


class NodeTests(InstallerTestCase):
    def test_nvm_alone_does_not_install_shell_profile_tools(self):
        self.fake_system()
        output = self.cli("packages", "--tools", "nvm", "--yes")
        self.assertIn("Automatic requirements: none", output)
        log = self.log.read_text()
        self.assertIn("nvm install --lts", log)
        for unwanted in ("neovim", "fzf", "zoxide", "starship", "git clone", "openjdk-21-jdk"):
            self.assertNotIn(unwanted, log)

    def test_existing_nvm_lts_and_codex_are_not_updated(self):
        self.fake_system()
        self.cli("packages", "--shell", "none", "--terminal", "none",
                 "--tools", "nvm,codex", "--yes")
        before = self.log.read_text()
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "nvm,codex", "--yes")
        self.assertIn("skip: nvm already installed", output)
        self.assertIn("skip: codex already installed", output)
        self.assertEqual(self.log.read_text(), before)

    def test_nvm_without_node_still_installs_lts(self):
        self.fake_system()
        directory = self.home / ".nvm"
        directory.mkdir()
        (directory / "nvm.sh").write_text(r'''nvm() {
    printf 'nvm %s\n' "$*" >> "$TEST_LOG"
    case "$1" in
        which) [[ -x "$NVM_DIR/node" ]] && printf '%s\n' "$NVM_DIR/node" ;;
        install) printf '#!/usr/bin/env bash\nprintf "true\\n"\n' > "$NVM_DIR/node"; chmod +x "$NVM_DIR/node" ;;
    esac
}''')
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "nvm", "--yes")
        self.assertIn("Install Node LTS", output)
        self.assertIn("nvm install --lts", self.log.read_text())
        self.assertNotIn("Install nvm v", output)

    def test_native_fish_nvm_activates_lts_and_preserves_errors(self):
        fish_config = self.home / ".config/fish"
        fish_config.parent.mkdir(parents=True)
        shutil.copytree(ROOT / "config/fish", fish_config)
        (self.home / "lib").mkdir(exist_ok=True)
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
        (self.home / "shell/common").mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "shell/common/package-aliases.tsv", self.home / "shell/common/package-aliases.tsv")
        shutil.copy2(ROOT / "shell/common/node-bin", self.home / "shell/common/node-bin")
        directory = self.home / ".local/share/nvm"
        node_bin = directory / "v24.0.0/bin"
        node_bin.mkdir(parents=True)
        (directory / ".index").write_text("v24.0.0 lts/test\n")
        (node_bin / "node").write_text("#!/usr/bin/env bash\nprintf 'true\\n'\n")
        (node_bin / "node").chmod(0o755)
        self.mock_command("node", "exit 0")
        script = (
            'nvm use lts --silent; or exit 1; '
            'test "$PATH[1]" = "$nvm_data/v24.0.0/bin"; or exit 2; '
            'nvm use unavailable --silent; test $status -eq 1; or exit 3; '
            'nvm use system --silent; or exit 4; '
            'set -q nvm_current_version; and exit 5; exit 0'
        )
        result = subprocess.run(["fish", "-c", script], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_existing_native_fish_lts_is_skipped(self):
        self.fake_system()
        directory = self.home / ".local/share/nvm/v24.0.0/bin"
        directory.mkdir(parents=True)
        (directory.parent.parent / ".index").write_text("v24.0.0 lts/test\n")
        (directory / "node").write_text("#!/usr/bin/env bash\nprintf 'true\\n'\n")
        (directory / "node").chmod(0o755)
        self.seed_shell_dependencies("fish")
        output = self.cli("packages", "--shell", "fish", "--terminal", "none",
                          "--tools", "nvm", "--yes")
        self.assertIn("skip: nvm already installed", output)
        self.assertFalse(self.log.exists())

    def test_codex_in_native_fish_lts_is_detected(self):
        self.fake_system()
        directory = self.home / ".local/share/nvm/v24.0.0/bin"
        directory.mkdir(parents=True)
        for name, body in (("node", "printf 'true\\n'"), ("codex", "exit 0")):
            binary = directory / name
            binary.write_text("#!/usr/bin/env bash\n" + body + "\n")
            binary.chmod(0o755)
        self.seed_shell_dependencies("fish")
        output = self.cli("packages", "--shell", "fish", "--terminal", "none",
                          "--tools", "codex", "--yes")
        self.assertIn("skip: codex already installed", output)
        self.assertIn("Optional tools: codex", output)
        self.assertFalse(self.log.exists())

    def test_native_fish_node_and_codex_work_in_fresh_zsh(self):
        directory = self.home / ".local/share/nvm/v24.0.0/bin"
        directory.mkdir(parents=True)
        (directory / "node").write_text('#!/usr/bin/env bash\nif [[ "${1:-}" == -p ]]; then echo true; else echo fish-node; fi\n')
        (directory / "node").chmod(0o755)
        (directory / "codex").write_text('#!/usr/bin/env bash\necho cross-shell-codex\n')
        (directory / "codex").chmod(0o755)
        self.cli("install", "--components", "zsh", "--yes")
        result = self.zsh("node --version; codex --version")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("fish-node", result.stdout)
        self.assertIn("cross-shell-codex", result.stdout)

    def test_nvm_sh_node_and_codex_work_in_fresh_fish(self):
        directory = self.home / ".nvm/versions/node/v24.0.0/bin"
        directory.mkdir(parents=True)
        (self.home / ".nvm/nvm.sh").write_text('nvm() { printf "%s\\n" "$NVM_DIR/versions/node/v24.0.0/bin/node"; }')
        for name in ("node", "codex"):
            (directory / name).write_text(f'#!/usr/bin/env bash\necho shared-{name}\n')
            (directory / name).chmod(0o755)
        self.cli("install", "--components", "fish", "--yes")
        result = subprocess.run(["fish", "-c", "node --version; codex --version"],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("shared-node", result.stdout)
        self.assertIn("shared-codex", result.stdout)

    def test_incomplete_native_fish_node_directory_is_repaired(self):
        self.fake_system()
        directory = self.home / ".local/share/nvm/v24.0.0"
        directory.mkdir(parents=True)
        (directory / "local-notes").write_text("preserve this")
        self.cli("packages", "--shell", "fish", "--tools", "nvm", "--yes")
        self.assertTrue((directory / "bin/node").exists())
        backups = list((self.home / ".local/state/dotfiles/backups").rglob("local-notes"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "preserve this")

    def test_broken_nvm_manager_is_backed_up_and_reinstalled(self):
        self.fake_system()
        directory = self.home / ".nvm"
        directory.mkdir()
        (directory / "nvm.sh").write_text("return 1\n")
        output = self.cli("packages", "--tools", "nvm", "--yes")
        self.assertIn("Install nvm", output)
        backups = list((self.home / ".local/state/dotfiles/backups").rglob("nvm.sh"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "return 1\n")
        self.assertIn("Verified selected tools", output)
