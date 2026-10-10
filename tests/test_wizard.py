"""Offline regression tests for wizard."""
import os
import pty
import subprocess

from support import InstallerTestCase, CLI


class WizardTests(InstallerTestCase):
    def test_fish_wizard_does_not_ask_to_select_required_tools(self):
        self.fake_system()
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen([str(CLI), "setup", "--shell", "fish", "--terminal", "none", "--no-packages"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Checklist: move to Codex, toggle it, then accept the plan.
            os.write(master, b"jj \ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Optional tools: codex", stdout)
            for label in ("Neovim editor", "nvm + Node.js LTS", "starship", "zoxide", "fzf", "bat", "clipboard"):
                self.assertFalse(any(line.lstrip().split(") ", 1)[-1].startswith("[ ] " + label)
                                     for line in stderr.splitlines()))
            self.assertNotIn("Zsh autosuggestions", stderr)
            self.assertNotIn("[ ] Java JDK", stderr)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_zsh_wizard_does_not_offer_profile_dependency_questions(self):
        self.fake_system()
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen([str(CLI), "setup", "--shell", "zsh", "--terminal", "none", "--no-packages"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Accept the empty checklist, then confirm the resolved profile.
            os.write(master, b"\ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Optional tools: none", stdout)
            for label in ("Neovim editor", "git", "nvm + Node.js LTS", "starship", "zoxide", "fzf", "bat", "fd", "eza", "lf", "clipboard", "Zsh autosuggestions"):
                self.assertFalse(any(line.lstrip().split(") ", 1)[-1].startswith("[ ] " + label)
                                     for line in stderr.splitlines()))
            self.assertIn("Automatic requirements:", stdout)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    # A pseudo-terminal makes read -p behave as it does for a user; queued answers exercise
    # the actual wizard rather than replacing its prompt functions.
    def test_tool_wizard_accepts_multiple_selections(self):
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                [str(CLI), "setup", "--no-packages", "--shell", "none", "--terminal", "none"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Stable checklist rows: nvim, tmux, Docker, Java, Codex, AWS.
            os.write(master, b" j 6 \ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("AWS CLI", stderr)
            self.assertIn("Optional tools: nvim,tmux,aws", stdout)
            self.assertTrue((self.home / ".config/nvim").is_symlink())
            self.assertTrue((self.home / ".config/tmux").is_symlink())
            self.assertFalse((self.home / ".config/starship.toml").exists())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_interactive_wizard(self):
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                [str(CLI), "setup", "--no-packages", "--tools", "none"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True)
            os.close(slave)
            slave = None
            os.write(master, b"\x1b[B\n\ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Shell: fish | Terminal: none", stdout)
            self.assertTrue((self.home / ".config/fish/config.fish").is_symlink())
            self.assertFalse((self.home / ".bashrc").exists())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_confirmation_menu_defaults_navigation_and_cancel(self):
        for keys, expected, status in (
            (b"\n", "Cancelled", 0),
            (b"\x1b[B\n", "Setup complete", 0),
            (b"\x1b[A\n", "Setup complete", 0),
            (b"9\n", "Cancelled", 0),
            (b"q", "Selection cancelled", 1),
        ):
            with self.subTest(keys=keys):
                master, slave = pty.openpty()
                try:
                    process = subprocess.Popen(
                        [str(CLI), "setup", "--no-packages", "--tools", "none",
                         "--shell", "none", "--terminal", "none"],
                        env=self.env, stdin=slave, stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, text=True)
                    os.close(slave)
                    slave = None
                    os.write(master, keys)
                    stdout, stderr = process.communicate(timeout=10)
                    self.assertEqual(process.returncode, status, stdout + stderr)
                    self.assertIn(expected, stdout + stderr)
                    self.assertIn("1) no", stderr)
                    self.assertIn("2) yes", stderr)
                    self.assertFalse((self.home / ".config").exists())
                finally:
                    os.close(master)
                    if slave is not None:
                        os.close(slave)

    def test_shell_wizard_installs_and_activates_selected_shell(self):
        self.fake_system()
        (self.mock / "zsh").unlink()
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                [str(CLI), "setup", "--tools", "none"], env=self.env,
                stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Choose Zsh/no terminal, install packages, then accept the plan.
            # There is intentionally no separate make-default prompt.
            os.write(master, b"3\n\ny\ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Default login shell set to zsh", stdout)
            self.assertNotIn("Make the selected shell", stderr)
            self.assertIn("apt-get install", self.log.read_text())
            self.assertIn(f"chsh -s {self.mock / 'zsh'}", self.log.read_text())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)
