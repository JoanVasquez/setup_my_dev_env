"""Offline regression tests for zsh."""
from pathlib import Path

from support import InstallerTestCase


class ZshTests(InstallerTestCase):
    def test_fedora_zsh_profile_installs_lf_without_external_repositories(self):
        self.release.write_text("ID=ultramarine\nID_LIKE=fedora\n")
        self.fake_system()
        args = ("setup", "--shell", "zsh", "--terminal", "none",
                "--tools", "none", "--keep-shell", "--yes")
        output = self.cli(*args)
        self.assertIn("Install lf r42", output)
        self.assertTrue((self.home / ".local/bin/lf").is_file())
        self.assertTrue((self.home / ".config/zsh/.zshrc").is_symlink())
        first_log = self.log.read_text()
        self.assertNotIn("copr", first_log)
        self.assertNotIn("apt-get", first_log)
        self.assertNotIn("pacman", first_log)
        self.cli(*args)
        self.assertEqual(self.log.read_text(), first_log)

    def test_zsh_xdg_environment_is_quiet_for_noninteractive_shells(self):
        self.cli("install", "--components", "zsh", "--yes")
        result = self.zsh('print -r -- "$ZDOTDIR|$XDG_CACHE_HOME|$XDG_DATA_HOME|$XDG_STATE_HOME|$EDITOR|$STARSHIP_CONFIG|${GPG_TTY:-unset}"', interactive=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        expected = "|".join([str(self.home / ".config/zsh"), str(self.home / ".cache"),
                             str(self.home / ".local/share"), str(self.home / ".local/state"),
                             "nvim", str(self.home / ".config/zsh/starship.toml"), "unset"])
        self.assertEqual(result.stdout.strip(), expected)

    def test_zsh_history_completion_and_bindings_load_without_plugins(self):
        self.cli("install", "--components", "zsh", "--yes")
        result = self.zsh('print -r -- "$HISTFILE|$HISTSIZE|$SAVEHIST"; bindkey -M viins "^F"; alias dcud nb install; print -r -- $DOTFILES_HOME')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn(str(self.home / ".local/state/zsh/history") + "|100000|100000", result.stdout)
        self.assertIn("_fzf_file_no_hidden", result.stdout)
        self.assertIn("docker compose up -d", result.stdout)
        self.assertIn("npm run build", result.stdout)
        self.assertIn("sudo apt install", result.stdout)
        self.assertTrue((self.home / ".cache/zsh/zcompdump").exists())

    def test_zsh_lf_uses_plain_cat_and_handles_spaces(self):
        self.cli("install", "--components", "zsh", "--yes")
        chosen = self.home / "selected directory"
        chosen.mkdir()
        self.env["LF_CHOICE"] = str(chosen)
        self.mock_command("bat", 'printf "decorated output\n"')
        self.mock_command("lf", 'file="${1#-last-dir-path=}"; printf "%s\n" "$LF_CHOICE" > "$file"')
        result = self.zsh('lf; [[ "$PWD" == "$LF_CHOICE" ]]')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_zsh_docker_build_preserves_arguments(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.mock_command("docker", 'printf "%s\n" "$@" > "$TEST_LOG"')
        result = self.zsh('dbf "Dockerfile dev" "my-image:dev" "context dir"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), ["build", "-f", "Dockerfile dev", "-t", "my-image:dev", "context dir"])

    def test_zsh_debian_bat_and_fd_names_are_supported(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.mock_command("batcat", "exit 0")
        self.mock_command("fdfind", "exit 0")
        result = self.zsh('alias bat fd; print -r -- "$FZF_DEFAULT_COMMAND|$MANPAGER"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("bat=batcat", result.stdout)
        self.assertIn("fd=fdfind", result.stdout)
        self.assertIn("fdfind --type f", result.stdout)
        self.assertIn("batcat -l man -p", result.stdout)

    def test_zsh_croot_failure_keeps_current_directory(self):
        self.mock_command("git", 'exit 1')
        result = self.configured_shell("zsh", 'before=$PWD; croot; result=$?; [[ $result != 0 && $PWD == $before ]]')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_zsh_ancestry_detection_works_in_both_shells(self):
        self.release.write_text('ID=custom\nID_LIKE="custom debian"\n')
        self.cli("install", "--components", "zsh", "--yes")
        result = self.zsh('print -r -- "$(os_family)"; alias install')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("debian", result.stdout)
        self.assertIn("sudo apt install", result.stdout)

    def test_zsh_file_widget_quotes_names_without_executing_them(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.env["FILE_PICK"] = 'file with spaces;$(touch UNEXPECTED)'
        self.mock_command("fd", 'printf "%s\n" "$*" > "$TEST_LOG"; printf "%s\n" "$FILE_PICK"')
        self.mock_command("fzf", '[[ "${1:-}" != --zsh ]] || exit 1; cat')
        script = r"""
zle() { :; }
LBUFFER='cat '
_fzf_file_no_hidden
# Evaluating a correctly quoted array recovers exactly one filename argument.
eval "selection=( $LBUFFER )"
[[ ${#selection} == 2 && "${selection[2]}" == "$FILE_PICK" ]]
"""
        result = self.zsh(script)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--hidden", self.log.read_text())
        self.assertFalse((self.home / "UNEXPECTED").exists())

    def test_zsh_git_picker_filters_remote_head_and_switches_selected_branch(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.env["BRANCH_INPUT"] = str(self.base / "branches")
        self.mock_command("git", r"""case "$1" in
    rev-parse) exit 0 ;;
    for-each-ref) printf 'main\norigin/main\norigin/feature\norigin/HEAD\n' ;;
    switch) printf '%s\n' "$@" > "$TEST_LOG" ;;
esac""")
        self.mock_command("fzf", '[[ "${1:-}" != --zsh ]] || exit 1; cat > "$BRANCH_INPUT"; printf "feature\n"')
        result = self.zsh('gcofzf')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(self.env["BRANCH_INPUT"]).read_text().splitlines(), ["feature", "main"])
        self.assertEqual(self.log.read_text().splitlines(), ["switch", "--", "feature"])

    def test_zsh_modern_fzf_initialization_is_preferred(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.mock_command("fzf", '[[ "$1" != --zsh ]] || printf "typeset -g DOTFILES_FZF_READY=yes\\n"')
        result = self.zsh('print -r -- "$DOTFILES_FZF_READY"; bindkey -M viins "^F"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("yes", result.stdout)
        self.assertIn("_fzf_file_no_hidden", result.stdout)

    def test_zsh_restores_fzf_keys_after_vi_mode_resets_them(self):
        self.cli("install", "--components", "zsh", "--yes")
        self.mock_command("fzf", r'''
[[ "${1:-}" == --zsh ]] || exit 1
cat <<'INIT'
(( $+widgets[fzf-history-widget] )) && return
fzf-history-widget() { :; }
fzf-file-widget() { :; }
fzf-cd-widget() { :; }
zle -N fzf-history-widget
zle -N fzf-file-widget
zle -N fzf-cd-widget
INIT
''')
        result = self.zsh(r'''
bindkey -v
bindkey -M viins '^R' history-incremental-search-backward
zvm_after_init
bindkey -M viins '^R'
bindkey -M viins '^T'
bindkey -M viins '\ec'
bindkey -M viins '^['
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('"^R" fzf-history-widget', result.stdout)
        self.assertIn('"^T" fzf-file-widget', result.stdout)
        self.assertIn('fzf-cd-widget', result.stdout)
        self.assertIn('"^[" _dotfiles_escape', result.stdout)

    def test_fzf_option_restore_leaves_readonly_zle_untouched(self):
        self.cli("install", "--components", "zsh", "--yes")
        # Reproduce the option snapshot/restore used by the installed fzf scripts.
        self.mock_command("fzf", r'''
[[ "${1:-}" == --zsh ]] || exit 1
cat <<'INIT'
__fzf_saved_options="options=(${(j: :)${(kv)options[@]}})"
unsetopt numericglobsort
setopt beep
eval "$__fzf_saved_options"
unset __fzf_saved_options
INIT
''')
        result = self.zsh('print -r -- "$options[numericglobsort]|$options[beep]"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout.strip(), "on|off")

    def test_default_zsh_plan_includes_requested_dependencies(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--dry-run")
        self.assertIn("eza lf", output)
        self.assertIn("zsh-plugins", output)
        self.assertIn("https://github.com/jeffreytse/zsh-vi-mode.git", output)
        self.assertFalse(self.log.exists())
        self.assertEqual(list(self.home.iterdir()), [])
