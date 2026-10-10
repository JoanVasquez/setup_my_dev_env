"""Offline regression tests for tmux."""
import subprocess

from support import InstallerTestCase, ROOT


class TmuxTests(InstallerTestCase):
    def test_tmux_number_icons_handle_all_windows_and_invalid_indices(self):
        script = ROOT / "config/tmux/scripts/number.sh"
        for index, expected in (("1", "󰎦"), ("9", "󰎾"), ("10", "10"),
                                ("99999999999999999999", "99999999999999999999")):
            with self.subTest(index=index):
                result = subprocess.run([str(script), index], env=self.env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, f" {expected} ")
        for args in ([], ["0"], ["-1"], ["01"], ["1+1"], ["abc"], ["1", "2"]):
            result = subprocess.run([str(script), *args], env=self.env,
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, "")

    def test_tmux_session_dots_follow_active_session_id_and_handle_no_server(self):
        script = ROOT / "config/tmux/scripts/status.sh"
        self.mock_command("tmux", r"""[[ "$*" == "list-sessions -F #{session_id}" ]]
        printf '$0\n$2\n$10\n'
        """)
        result = subprocess.run([str(script), "sessions", "$2"], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "● 👻 ● ")
        self.mock_command("tmux", "exit 1")
        result = subprocess.run([str(script), "sessions", "$2"], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        result = subprocess.run([str(script), "uptime"], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"^(?:\d+d )?(?:\d+h )?\d+m$")
