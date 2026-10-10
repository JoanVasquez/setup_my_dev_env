"""Temporary-home fixtures and mocked system commands for offline behavior tests."""
import os
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/dotfiles"


class InstallerTestCase(unittest.TestCase):
    # Each test gets a disposable home and fake os-release; paths intentionally contain
    # spaces to catch quoting errors. addCleanup removes the fixture even after failures.
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base / "home with spaces"
        self.home.mkdir()
        self.release = self.base / "os-release"
        self.release.write_text('ID=ubuntu\nID_LIKE=debian\nVERSION_CODENAME=noble\n')
        self.mock = self.base / "bin"
        self.mock.mkdir()
        self.log = self.base / "commands"
        # Redirect every writable user directory into the fixture. Clear terminal clues
        # so the real desktop session cannot change detection defaults.
        self.env = dict(os.environ, HOME=str(self.home), SHELL="/bin/bash",
                        OS_RELEASE_FILE=str(self.release),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        PATH=str(self.mock), TEST_LOG=str(self.log),
                        TEST_BIN=str(self.mock), TEST_PACKAGES=str(self.base / "installed-packages"),
                        NVM_DIR=str(self.home / ".nvm"), TERM="dumb", TERM_PROGRAM="",
                        KONSOLE_VERSION="", KITTY_WINDOW_ID="")
        # A restricted PATH prevents the host's tools from masquerading as fixtures.
        for utility in ("bash", "sh", "env", "dirname", "date", "mkdir", "mv", "ln", "readlink",
                        "rm", "cat", "mktemp", "cut", "id", "awk", "grep", "tar", "uname",
                        "chmod", "sort", "sed", "head", "find", "ps", "tr", "cp", "install", "gzip", "fish", "zsh"):
            executable = shutil.which(utility)
            if executable:
                (self.mock / utility).symlink_to(executable)
        self.shells = self.base / "shells"
        self.shells.write_text("\n".join(str(self.mock / name) for name in ("bash", "fish", "zsh")) + "\n")
        self.env["SHELLS_FILE"] = str(self.shells)
        self.env["TEST_ACCOUNT_SHELL"] = "/bin/bash"
        self.mock_command("getent", 'printf "test:x:1000:1000::%s:%s\\n" "$HOME" "$TEST_ACCOUNT_SHELL"')
        self.mock_command("dpkg-query", 'exit 1')
        self.mock_command("pacman", 'exit 1')
        self.mock_command("rpm", 'exit 1')
        self.mock_command("chsh", 'exit 0')
        for var in ("DOCKER_DISTRO", "DOCKER_CODENAME", "NVM_VERSION", "ZDOTDIR", "ZPLUGINDIR", "ZSH_GLOBAL_ENV_FILE", "GPG_TTY", "STARSHIP_CONFIG", "nvm_data"):
            self.env.pop(var, None)

    # Write a tiny executable into the restricted PATH to simulate a tool or package command.
    def mock_command(self, name, script):
        if name == "javac" and script == "exit 0":
            script = 'printf "javac 21.0.7\\n"'
        if name == "nvim" and script == "exit 0":
            script = 'printf "NVIM v0.11.5\\n"'
        target = self.mock / name
        if target.is_symlink():
            target.unlink()
        target.write_text("#!/usr/bin/env bash\nset -eu\n" + script + "\n")
        target.chmod(0o755)

    # Exercise the public entrypoint as a subprocess, checking both exit status and messages.
    def cli(self, *args, ok=True):
        result = subprocess.run([str(CLI), *args], env=self.env,
                                capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result.stdout + result.stderr

    # Replace sudo/network/package commands: record requests and synthesize installed binaries.
    # These fixtures never elevate privileges, contact upstream hosts, or install real packages.
    def fake_system(self):
        # Handle only the installer's native nvm.fish command; ordinary Fish tests
        # continue to use the real interpreter. Never write through a system symlink.
        real_fish = shutil.which("fish")
        self.mock_command("fish", r'''if [[ "$1" == --no-config && "$*" == *"nvm install lts"* ]]; then
    directory="${!#}"
    mkdir -p "$directory/v24.0.0/bin"
    printf '#!/usr/bin/env bash\nprintf "true\\n"\n' > "$directory/v24.0.0/bin/node"
    chmod +x "$directory/v24.0.0/bin/node"
    printf 'v24.0.0 lts/test\n' > "$directory/.index"
    printf 'nvm.fish install lts\n' >> "$TEST_LOG"
    exit 0
fi
''' + f'exec "{real_fish}" "$@"')
        self.mock_command("sudo", r'''
printf "%s\n" "$*" >> "$TEST_LOG"
case "$*" in
    "apt-get install "*|"pacman -S "*|"dnf --refresh install "*|"dnf reinstall "*)
        for package in "$@"; do
            case "$package" in
                docker|docker-ce|moby-engine|docker-cli|docker-compose|docker-compose-plugin|docker-compose-v2)
                    printf '#!/usr/bin/env bash\nprintf "Docker Compose version v2.test\\n"\n' > "$TEST_BIN/docker"
                    chmod +x "$TEST_BIN/docker" ;;
                fish|zsh)
                    if [[ -L "$TEST_BIN/$package" ]]; then rm "$TEST_BIN/$package"; fi
                    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$package"
                    chmod +x "$TEST_BIN/$package" ;;
                python3|python) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/python3"; chmod +x "$TEST_BIN/python3" ;;
                gcc|make|golang-go|golang|go|tree-sitter-cli)
                    binary="$package"
                    [[ "$package" != golang-go && "$package" != golang ]] || binary=go
                    [[ "$package" != tree-sitter-cli ]] || binary=tree-sitter
                    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$binary"; chmod +x "$TEST_BIN/$binary" ;;
                neovim) printf '#!/usr/bin/env bash\nprintf "NVIM v0.11.5\\n"\n' > "$TEST_BIN/nvim"; chmod +x "$TEST_BIN/nvim" ;;
                zoxide|fzf|bat|fd|rg|eza|lf|vim|tree|xclip|wl-copy|fastfetch|col|tmux|starship|unzip|kitty|alacritty|konsole|ghostty) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$package"; chmod +x "$TEST_BIN/$package" ;;
                util-linux|bsdextrautils) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/col"; chmod +x "$TEST_BIN/col" ;;
                passwd) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/chsh"; chmod +x "$TEST_BIN/chsh" ;;
                vim-enhanced) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/vim"; chmod +x "$TEST_BIN/vim" ;;
                fd-find) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/fdfind"; chmod +x "$TEST_BIN/fdfind" ;;
                ripgrep) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/rg"; chmod +x "$TEST_BIN/rg" ;;
                wl-clipboard) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/wl-copy"; chmod +x "$TEST_BIN/wl-copy" ;;
                openjdk-21-jdk|jdk-openjdk|java-21-openjdk-devel) printf '#!/usr/bin/env bash\nprintf "javac 21.0.7\\n"\n' > "$TEST_BIN/javac"; chmod +x "$TEST_BIN/javac" ;;
            esac
            printf '%s\n' "$package" >> "$TEST_PACKAGES"
        done ;;
esac
''')
        self.mock_command("apt-cache", 'printf "  Candidate: 1.0\\n"')
        self.mock_command("dpkg-query", 'if [[ -f "$TEST_PACKAGES" ]] && grep -Fxq "${!#}" "$TEST_PACKAGES"; then printf "install ok installed"; else exit 1; fi')
        self.mock_command("pacman", '[[ -f "$TEST_PACKAGES" ]] && grep -Fxq "${!#}" "$TEST_PACKAGES"')
        self.mock_command("rpm", '[[ -f "$TEST_PACKAGES" ]] && grep -Fxq "${!#}" "$TEST_PACKAGES"')
        self.mock_command("dnf", 'exit 0')
        self.mock_command("dpkg", 'printf "amd64\\n"')
        self.mock_command("npm", r'''[[ "${1:-}" != --version ]] || exit 0
printf "npm %s\n" "$*" >> "$TEST_LOG"
printf '#!/usr/bin/env bash\nprintf "codex test\\n"\n' > "$TEST_BIN/codex"
chmod +x "$TEST_BIN/codex"
''')
        self.mock_zsh_plugin_clones()
        # Fake downloads produce miniature installers, so the real orchestrator can source/run
        # them and later detect the resulting files during repeat-run tests.
        self.mock_command("curl", '''
[[ "${1:-}" != --version ]] || exit 0
url=""; output=""
while (($#)); do
    case "$1" in https://*) url="$1" ;; -o) shift; output="$1" ;; esac
    shift
done
case "$url" in
    */nvim-linux-*.tar.gz)
        archive="${url##*/}"
        archive="${archive%.tar.gz}"
        mkdir -p "$TEST_BIN/neovim-release/$archive/bin"
        printf '#!/usr/bin/env bash\nprintf "NVIM v0.11.5\\n"\n' > "$TEST_BIN/neovim-release/$archive/bin/nvim"
        chmod +x "$TEST_BIN/neovim-release/$archive/bin/nvim"
        tar -czf "$output" -C "$TEST_BIN/neovim-release" "$archive" ;;
    */lf-linux-*.tar.gz)
        mkdir -p "$TEST_BIN/lf-release"
        printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/lf-release/lf"
        tar -czf "$output" -C "$TEST_BIN/lf-release" lf ;;
    */tree-sitter-linux-*.gz)
        printf '#!/usr/bin/env bash\nexit 0\n' | gzip > "$output" ;;
    */nvm/*/install.sh)
        cat > "$output" <<'INSTALL'
mkdir -p "$NVM_DIR"
cat > "$NVM_DIR/nvm.sh" <<'NVM'
nvm() {
    if [[ "$1" != which ]]; then printf 'nvm %s\\n' "$*" >> "$TEST_LOG"; fi
    case "$1" in
        which) printf '%s\\n' "$NVM_DIR/node" ;;
        install)
            printf '#!/usr/bin/env bash\\nprintf "true\\\\n"\\n' > "$NVM_DIR/node"
            chmod +x "$NVM_DIR/node" ;;
    esac
}
NVM
INSTALL
        ;;
    https://awscli.amazonaws.com/v2/install.sh)
        cat > "$output" <<'AWS'
mkdir -p "$XDG_BIN_HOME"
printf '#!/usr/bin/env bash\\nprintf "aws-cli/2.test\\\\n"\\n' > "$XDG_BIN_HOME/aws"
chmod +x "$XDG_BIN_HOME/aws"
printf 'aws installed\\n' >> "$TEST_LOG"
AWS
        ;;
    https://starship.rs/install.sh)
        cat > "$output" <<'STARSHIP'
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\\nexit 0\\n' > "$HOME/.local/bin/starship"
chmod +x "$HOME/.local/bin/starship"
STARSHIP
        ;;
    */install.sh) printf 'exit 0\\n' > "$output" ;;
    */gpg) printf 'test-key\\n' > "$output" ;;
    *) exit 1 ;;
esac
''')

    def seed_shell_dependencies(self, shell):
        # Pre-existing runtime tools let activation/skip tests avoid unrelated installs.
        for name in ("git", "nvim", "starship", "zoxide", "fzf", "bat", "fd", "rg",
                     "eza", "lf", "xclip", "wl-copy", "vim", "tree", "python3", "go",
                     "javac", "cc", "make", "tree-sitter", "curl", "unzip", "npm"):
            self.mock_command(name, "exit 0")
        if shell == "fish":
            directory = self.home / ".local/share/nvm"
            node = directory / "v24.0.0/bin/node"
            node.parent.mkdir(parents=True, exist_ok=True)
            (directory / ".index").write_text("v24.0.0 lts/test\n")
        else:
            directory = self.home / ".nvm"
            directory.mkdir(exist_ok=True)
            node = directory / "node"
            (directory / "nvm.sh").write_text('nvm() { [[ "$1" != which ]] || printf "%s\\n" "$NVM_DIR/node"; }')
        node.write_text("#!/usr/bin/env bash\nprintf 'true\\n'\n")
        node.chmod(0o755)
        for repository, entry in (line.split() for line in (ROOT / "config/zsh/plugins.list").read_text().splitlines() if line and not line.startswith("#")):
            target = self.home / ".local/share/zsh/plugins" / repository.split("/")[-1] / entry
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("# existing plugin\n")

    def zsh(self, script, interactive=True):
        args = ["zsh", "-ic" if interactive else "-c", script]
        return subprocess.run(args, env=self.env, cwd=self.home, text=True, capture_output=True)

    def configured_shell(self, shell, commands):
        if shell == "fish":
            script = f'source "{ROOT}/config/fish/conf.d/dotfiles-environment.fish"\nsource "{ROOT}/config/fish/config.fish"\n' + commands
            args = [shutil.which(shell), "--no-config", "-c", script]
        else:
            script = f'DOTFILES_HOME="{ROOT}"\nsource "$DOTFILES_HOME/lib/platform.sh"\ncompdef() {{ :; }}\nsource "$DOTFILES_HOME/config/zsh/aliases.zsh"\nsource "$DOTFILES_HOME/config/zsh/functions.zsh"\neval "$1"'
            args = [shutil.which(shell), "-dfc", script, "test-shell", commands]
        return subprocess.run(args, env=self.env, text=True, capture_output=True)

    def mock_zsh_plugin_clones(self):
        self.mock_command("git", r'''
[[ "${1:-}" != --version ]] || exit 0
printf "git %s\n" "$*" >> "$TEST_LOG"
if [[ "$1" == clone ]]; then
    destination="${!#}"
    repository="${@: -2:1}"
    name="${repository##*/}"
    name="${name%.git}"
    mkdir -p "$destination"
    case "$name" in
        zsh-autosuggestions|zsh-history-substring-search) entry="$name.zsh" ;;
        tpm) entry=tpm ;;
        tmux-resurrect) entry=scripts/save.sh ;;
        tmux-continuum) entry=continuum.tmux ;;
        *) entry="$name.plugin.zsh" ;;
    esac
    mkdir -p "$destination/$(dirname "$entry")"
    printf 'typeset -ga dotfiles_test_plugins; dotfiles_test_plugins+=(%s)\n' "$name" > "$destination/$entry"
    chmod +x "$destination/$entry"
    if [[ "$name" == zsh-vi-mode ]]; then
        cat >> "$destination/$entry" <<'VI'
ZVM_CURSOR_BEAM=beam
ZVM_CURSOR_BLOCK=block
zvm_config
zvm_after_init
VI
    fi
fi
''')
