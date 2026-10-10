"""Public CLI compatibility at the executable boundary."""
import subprocess

from support import CLI, InstallerTestCase


class CliTests(InstallerTestCase):
    def test_help_works_from_another_directory_without_runtime_changes(self):
        result = subprocess.run([str(CLI), '--help'], cwd=self.base,
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        self.assertIn('setup|install|packages|doctor|aliases|unlink', result.stdout)
        self.assertIn('--components bash,zsh,fish,tmux,nvim,starship', result.stdout)
        self.assertFalse((self.home / '.config').exists())
        self.assertFalse(self.log.exists())

    def test_invalid_commands_flags_and_missing_values_stop_before_changes(self):
        cases = (
            (['unknown'], 'Usage:', 2),
            (['setup', '--components', 'bash'], 'applies to install/unlink only', 1),
            (['install', '--shell', 'bash'], 'applies to setup/packages/aliases only', 1),
            (['setup', '--tools'], 'Missing value for --tools', 1),
            (['setup', '--shell', '--yes'], 'Missing value for --shell', 1),
            (['packages', '--tools', ''], 'Missing value for --tools', 1),
            (['setup', '--unknown'], 'Unknown option: --unknown', 1),
        )
        for args, message, status in cases:
            with self.subTest(args=args):
                result = subprocess.run([str(CLI), *args], cwd=self.base,
                                        env=self.env, capture_output=True, text=True)
                self.assertEqual(result.returncode, status, result.stdout + result.stderr)
                self.assertIn(message, result.stdout + result.stderr)
                self.assertFalse((self.home / '.config').exists())
                self.assertFalse(self.log.exists())

    def test_opposing_shell_flags_preserve_argument_order(self):
        for flags, expected in ((['--login-shell', '--keep-shell'], 0),
                                (['--keep-shell', '--login-shell'], 1)):
            with self.subTest(flags=flags):
                output = self.cli('setup', '--shell', 'bash', '--terminal', 'none',
                                  '--tools', 'none', '--no-packages', '--dry-run', *flags)
                self.assertIn(f'Change login shell: {expected}', output)
                self.assertFalse((self.home / '.config').exists())
