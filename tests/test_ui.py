"""Exercise menu input without installation or external dependencies."""
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MenuTests(unittest.TestCase):
    def menu(self, keys, mode="multiple", options="one two three", default="none"):
        return subprocess.run(
            ["bash", "-c", 'set -euo pipefail; source "$1/lib/core.sh"; '
             'source "$1/lib/ui/menu.sh"; menu_labels=(); '
             'prompt_menu answer "Test menu" "$2" "$3" ${4}; printf "RESULT=%s\\n" "$answer"',
             "menu-test", str(ROOT), default, mode, options],
            input=keys, text=True, capture_output=True,
            env=dict(os.environ, TERM="dumb"), timeout=5)

    def test_toggle_multiple_and_wrap(self):
        result = self.menu(" k \n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RESULT=one,three", result.stdout)
        self.assertIn("[x] three | 2 selected", result.stderr)
        self.assertNotIn("\x1b", result.stderr)

    def test_select_all_clear_and_toggle_off(self):
        for keys, expected in (("a\n", "one,two,three"), ("an\n", "none"), ("  \n", "none")):
            with self.subTest(keys=keys):
                result = self.menu(keys)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("RESULT=" + expected, result.stdout)

    def test_more_than_nine_options_are_reachable(self):
        result = self.menu("k \n", options=" ".join("tool" + str(i) for i in range(12)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RESULT=tool11", result.stdout)

    def test_cancel_and_eof_return_no_selection(self):
        for keys in ("q", ""):
            result = self.menu(keys)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("RESULT=", result.stdout)

    def test_defaults_and_arrow_navigation(self):
        result = self.menu("\x1b[B\n", mode="single", default="two")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RESULT=three", result.stdout)
