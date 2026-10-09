"""Behavior tests run in temporary homes, with no network or system changes."""
import os
import pty
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/dotfiles"


class InstallerTests(unittest.TestCase):
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
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        PATH=str(self.mock), TEST_LOG=str(self.log),
                        TEST_BIN=str(self.mock), TEST_PACKAGES=str(self.base / "installed-packages"),
                        NVM_DIR=str(self.home / ".nvm"), TERM="dumb", TERM_PROGRAM="",
                        KONSOLE_VERSION="", KITTY_WINDOW_ID="")
        # A restricted PATH prevents the host's tools from masquerading as fixtures.
        for utility in ("bash", "sh", "env", "dirname", "date", "mkdir", "mv", "ln", "readlink",
                        "rm", "cat", "mktemp", "cut", "id", "awk", "grep", "tar", "uname",
                        "chmod", "sort", "sed", "head", "find", "ps", "tr", "cp", "install", "fish", "zsh"):
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
        for var in ("DOCKER_DISTRO", "DOCKER_CODENAME", "NVM_VERSION", "ZDOTDIR", "ZPLUGINDIR", "ZSH_GLOBAL_ENV_FILE", "GPG_TTY"):
            self.env.pop(var, None)

    # Write a tiny executable into the restricted PATH to simulate a tool or package command.
    def mock_command(self, name, script):
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
    "apt-get install "*|"pacman -S "*)
        for package in "$@"; do
            case "$package" in
                docker|docker-ce|docker-compose|docker-compose-plugin|docker-compose-v2)
                    printf '#!/usr/bin/env bash\nprintf "Docker Compose version v2.test\\n"\n' > "$TEST_BIN/docker"
                    chmod +x "$TEST_BIN/docker" ;;
                fish|zsh)
                    if [[ -L "$TEST_BIN/$package" ]]; then rm "$TEST_BIN/$package"; fi
                    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$package"
                    chmod +x "$TEST_BIN/$package" ;;
                neovim) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/nvim"; chmod +x "$TEST_BIN/nvim" ;;
                zoxide|fzf|bat|fd|rg|eza|lf|vim|tree|xclip|wl-copy|fastfetch|col|tmux|starship) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/$package"; chmod +x "$TEST_BIN/$package" ;;
                util-linux|bsdextrautils) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/col"; chmod +x "$TEST_BIN/col" ;;
                fd-find) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/fdfind"; chmod +x "$TEST_BIN/fdfind" ;;
                ripgrep) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/rg"; chmod +x "$TEST_BIN/rg" ;;
                wl-clipboard) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/wl-copy"; chmod +x "$TEST_BIN/wl-copy" ;;
                default-jdk|jdk-openjdk) printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_BIN/javac"; chmod +x "$TEST_BIN/javac" ;;
            esac
            printf '%s\n' "$package" >> "$TEST_PACKAGES"
        done ;;
esac
''')
        self.mock_command("apt-cache", 'printf "  Candidate: 1.0\\n"')
        self.mock_command("dpkg-query", 'if [[ -f "$TEST_PACKAGES" ]] && grep -Fxq "${!#}" "$TEST_PACKAGES"; then printf "install ok installed"; else exit 1; fi')
        self.mock_command("pacman", '[[ -f "$TEST_PACKAGES" ]] && grep -Fxq "${!#}" "$TEST_PACKAGES"')
        self.mock_command("dpkg", 'printf "amd64\\n"')
        self.mock_command("npm", r'''printf "npm %s\n" "$*" >> "$TEST_LOG"
printf '#!/usr/bin/env bash\nprintf "codex test\\n"\n' > "$TEST_BIN/codex"
chmod +x "$TEST_BIN/codex"
''')
        self.mock_zsh_plugin_clones()
        # Fake downloads produce miniature installers, so the real orchestrator can source/run
        # them and later detect the resulting files during repeat-run tests.
        self.mock_command("curl", '''
url=""; output=""
while (($#)); do
    case "$1" in https://*) url="$1" ;; -o) shift; output="$1" ;; esac
    shift
done
case "$url" in
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
                     "eza", "lf", "xclip", "wl-copy", "vim", "tree"):
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

    def test_zsh_requirements_are_automatic_even_with_tools_none(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--dry-run")
        self.assertIn("Optional tools: none", output)
        line = next(line for line in output.splitlines() if line.startswith("Automatic requirements:"))
        for tool in ("git", "nvim", "starship", "zoxide", "fzf", "bat", "fd", "ripgrep", "eza", "lf", "nvm", "clipboard", "zsh-plugins"):
            self.assertIn(tool, line.split())
        self.assertNotIn("java", line.split())
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
        self.assertIn("Distro packages: default-jdk", output)
        log = self.log.read_text()
        self.assertIn("-- default-jdk", log)
        for unwanted in ("curl", "git", "nvm", "neovim", "fzf", "starship", "ca-certificates"):
            self.assertNotIn(unwanted, log)

    def test_nvm_alone_does_not_install_shell_profile_tools(self):
        self.fake_system()
        output = self.cli("packages", "--tools", "nvm", "--yes")
        self.assertIn("Automatic requirements: none", output)
        log = self.log.read_text()
        self.assertIn("nvm install --lts", log)
        for unwanted in ("neovim", "fzf", "zoxide", "starship", "git clone", "default-jdk"):
            self.assertNotIn(unwanted, log)

    def test_tmux_requirements_resolve_cycles_without_duplicates(self):
        self.fake_system()
        output = self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "tmux,tpm", "--dry-run")
        line = next(line for line in output.splitlines() if line.startswith("Missing tools:"))
        self.assertEqual(line.split().count("tmux"), 1)
        self.assertEqual(line.split().count("tpm"), 1)
        self.assertEqual(line.split().count("fzf"), 1)
        self.assertEqual(output.count("https://github.com/tmux-plugins/tpm"), 1)

    def test_fish_wizard_does_not_ask_to_select_required_tools(self):
        self.fake_system()
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen([str(CLI), "setup", "--shell", "fish", "--terminal", "none", "--no-packages"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Optional tmux, Docker, Java, Codex, AWS, lf, fastfetch; then the plan.
            os.write(master, b"n\nn\ny\nn\nn\nn\nn\ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Optional tools: java", stdout)
            for label in ("Neovim", "nvm + Node.js LTS", "starship", "zoxide", "fzf", "bat", "clipboard"):
                self.assertNotIn("Install/configure " + label, stderr)
            self.assertNotIn("Zsh autosuggestions", stderr)
            self.assertIn("Install/configure Java JDK", stderr)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_fish_starts_quietly_on_debian_without_cachyos_defaults(self):
        config = self.home / ".config/fish"
        config.parent.mkdir(parents=True)
        shutil.copytree(ROOT / "config/fish", config)
        (self.home / "lib").mkdir()
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
        result = subprocess.run(["fish", "-c", 'echo $DOTFILES_OS_FAMILY; type install; cd /; pwd'], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("debian", result.stdout)
        self.assertIn("sudo apt install", result.stdout)
        self.assertTrue(result.stdout.rstrip().endswith("/"))

    def test_config_only_profiles_resolve_requirements_but_do_not_install_them(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "java", "--no-packages", "--yes")
        self.assertIn("Automatic requirements:", output)
        self.assertIn("Package installation: skipped", output)
        self.assertFalse(self.log.exists())
        self.assertTrue((self.home / ".config/zsh/.zshrc").is_symlink())

    def test_zsh_wizard_does_not_offer_profile_dependency_questions(self):
        self.fake_system()
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen([str(CLI), "setup", "--shell", "zsh", "--terminal", "none", "--no-packages"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # Only optional tmux/Docker/Java/Codex/AWS/Vim/tree/fastfetch, then confirm.
            os.write(master, ("n\n" * 8 + "y\n").encode())
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Optional tools: none", stdout)
            for label in ("Neovim", "git", "nvm + Node.js LTS", "starship", "zoxide", "fzf", "bat", "fd", "eza", "lf", "clipboard", "Zsh autosuggestions"):
                self.assertNotIn("Install/configure " + label, stderr)
            self.assertIn("Automatic requirements:", stdout)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_tmux_install_fetches_configured_plugins_without_extra_choices(self):
        self.fake_system()
        self.cli("packages", "--tools", "tmux", "--yes")
        log = self.log.read_text()
        for name in ("tpm", "tmux-resurrect", "tmux-continuum"):
            self.assertIn("https://github.com/tmux-plugins/" + name, log)
        before = log
        self.cli("packages", "--tools", "tmux", "--yes")
        self.assertEqual(self.log.read_text(), before)

    def test_token_based_distro_detection(self):
        for metadata, expected in [
            ('ID=cachyos\nID_LIKE=arch\n', 'arch'),
            ('ID=linuxmint\nID_LIKE="ubuntu debian"\n', 'debian'),
            ('ID=custom\nID_LIKE="custom arch"\n', 'arch'),
            ('ID=notarchlinux\n', 'unsupported'),
            ('ID=fedora\n', 'unsupported')]:
            self.release.write_text(metadata)
            output = self.cli("doctor")
            self.assertIn(f"Detected OS family: {expected}", output)

    def test_dry_run_makes_no_changes(self):
        self.fake_system()
        output = self.cli("setup", "--dry-run", "--shell", "fish", "--terminal", "kitty")
        self.assertIn('docker-compose-plugin', output)
        self.assertIn('nvm', output)
        self.assertFalse(self.log.exists())
        self.assertEqual(list(self.home.iterdir()), [])

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

    def test_invalid_selection_changes_nothing(self):
        for args in [("setup", "--shell", "bad"), ("setup", "--tools", "git,,nvm"),
                     ("install", "--components", "fish,unknown"),
                     ("install", "--tools", "nvm"), ("setup", "--terminal")]:
            self.cli(*args, "--yes", ok=False)
            self.assertEqual(list(self.home.iterdir()), [])

    def test_unsupported_config_only(self):
        self.release.write_text("ID=fedora\n")
        self.cli("setup", "--no-packages", "--shell", "fish", "--terminal", "none",
                 "--tools", "nvim,tmux,starship,zoxide", "--yes")
        self.assertTrue((self.home / ".config/fish").is_symlink())
        self.cli("setup", "--shell", "fish", "--terminal", "none", "--yes", ok=False)

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
        self.assertTrue((self.home / ".config/fish").is_symlink())

    def test_debian_official_docker_and_java(self):
        self.fake_system()
        self.cli("packages", "--shell", "none", "--terminal", "none", "--tools",
                 "docker,java,starship", "--yes")
        log = self.log.read_text()
        self.assertIn("default-jdk", log)
        self.assertIn("dotfiles-docker.sources", log)
        self.assertIn("docker-ce docker-ce-cli containerd.io", log)
        self.assertIn("docker-compose-plugin", log)
        self.assertNotIn("systemctl", log)
        self.assertNotIn("usermod", log)
        self.assertFalse((self.home / ".config").exists())

    def test_existing_docker_repository_is_reused(self):
        self.fake_system()
        self.mock_command("apt-cache", 'printf "  Candidate: 1.0\\n  https://download.docker.com/linux/ubuntu noble/stable\\n"')
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "docker", "--yes")
        self.assertIn("Reuse the configured", output)
        self.assertNotIn("dotfiles-docker.sources", self.log.read_text())
        self.assertIn("docker-compose-plugin", self.log.read_text())

    def test_docker_conflict_stops_before_changes(self):
        self.fake_system()
        self.mock_command("dpkg-query", 'printf "install ok installed"')
        output = self.cli("setup", "--tools", "docker", "--yes", ok=False)
        self.assertIn("conflicts", output)
        self.assertFalse(self.log.exists())

    def test_missing_apt_terminal_does_not_link(self):
        self.fake_system()
        self.mock_command("apt-cache", 'printf "  Candidate: (none)\\n"')
        output = self.cli("setup", "--shell", "none", "--terminal", "ghostty",
                          "--tools", "none", "--yes", ok=False)
        self.assertIn("No APT candidate", output)
        self.assertFalse((self.home / ".config").exists())

    def test_installed_tools_skip_all_installation_commands(self):
        self.fake_system()
        for name in ("tmux", "nvim", "docker", "javac", "starship", "codex", "aws", "fzf"):
            self.mock_command(name, 'exit 0')
        for name, entry in (("tpm", "tpm"), ("tmux-resurrect", "scripts/save.sh"), ("tmux-continuum", "continuum.tmux")):
            plugin = self.home / ".tmux/plugins" / name / entry
            plugin.parent.mkdir(parents=True)
            plugin.write_text("#!/usr/bin/env bash\nexit 0\n")
            plugin.chmod(0o755)
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "tmux,nvim,docker,java,starship,codex,aws", "--yes")
        for name in ("tmux", "nvim", "docker", "java", "starship", "codex", "aws"):
            self.assertIn(f"skip: {name} already installed", output)
        self.assertNotIn("Missing tools: nvm", output)
        self.assertFalse(self.log.exists())

    def test_local_bin_and_debian_aliases_are_detected(self):
        self.fake_system()
        local_bin = self.home / ".local/bin"
        local_bin.mkdir(parents=True)
        (local_bin / "aws").write_text("#!/usr/bin/env bash\nexit 0\n")
        (local_bin / "aws").chmod(0o755)
        self.mock_command("batcat", 'exit 0')
        self.mock_command("fdfind", 'exit 0')
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws,bat,fd", "--yes")
        self.assertIn("skip: aws already installed", output)
        self.assertIn("skip: bat already installed", output)
        self.assertIn("skip: fd already installed", output)
        self.assertFalse(self.log.exists())

    def test_missing_aws_installs_once_per_user(self):
        self.fake_system()
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws", "--yes")
        self.assertIn("aws-cli/2.test", output)
        self.assertEqual(self.log.read_text().count("aws installed"), 1)
        before = self.log.read_text()
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "aws", "--yes")
        self.assertIn("skip: aws already installed", output)
        self.assertEqual(self.log.read_text(), before)

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
        (directory / "nvm.sh").write_text('nvm() { printf "nvm %s\\n" "$*" >> "$TEST_LOG"; case "$1" in which) return 1 ;; esac; }')
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "nvm", "--yes")
        self.assertIn("Install Node LTS", output)
        self.assertIn("nvm install --lts", self.log.read_text())
        self.assertNotIn("Install nvm v", output)

    def test_missing_compose_preserves_existing_docker(self):
        self.fake_system()
        self.mock_command("docker", 'exit 1')
        (self.base / "installed-packages").write_text("docker.io\n")
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "docker", "--yes")
        self.assertIn("Docker is already installed", output)
        log = self.log.read_text()
        self.assertIn("apt-get install -y --no-upgrade docker-compose-v2", log)
        self.assertNotIn("docker-ce", log)
        self.assertNotIn("dotfiles-docker.sources", log)

    def test_skipped_docker_still_honors_service_choice(self):
        self.fake_system()
        self.mock_command("docker", 'exit 0')
        self.cli("packages", "--shell", "none", "--terminal", "none",
                 "--tools", "docker", "--enable-docker", "--yes")
        self.assertEqual(self.log.read_text(), "systemctl enable --now docker\n")

    # A pseudo-terminal makes read -p behave as it does for a user; queued answers exercise
    # the actual wizard rather than replacing its prompt functions.
    def test_tool_wizard_accepts_individual_yes_no_answers(self):
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                [str(CLI), "setup", "--no-packages", "--shell", "none", "--terminal", "none"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.close(slave)
            slave = None
            # git, nvim, tmux, starship, zoxide, nvm, docker, java, codex,
            # fzf, bat, ripgrep, fd, clipboard, tpm, aws.
            answers = ["y", "y", "n", "n", "n", "y"] + ["n"] * 12 + ["y"]
            os.write(master, ("\n".join(answers) + "\n").encode())
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Install/configure AWS CLI?", stderr)
            self.assertIn("Optional tools: nvim,tmux,aws", stdout)
            self.assertTrue((self.home / ".config/nvim").is_symlink())
            self.assertTrue((self.home / ".config/tmux").is_symlink())
            self.assertFalse((self.home / ".config/starship.toml").exists())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def zsh(self, script, interactive=True):
        args = ["zsh", "-ic" if interactive else "-c", script]
        return subprocess.run(args, env=self.env, cwd=self.home, text=True, capture_output=True)

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

    def mock_zsh_plugin_clones(self):
        self.mock_command("git", r'''
printf "git %s\n" "$*" >> "$TEST_LOG"
if [[ "$1" == clone ]]; then
    destination="${!#}"
    name="${destination##*/}"
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

    def test_default_zsh_plan_includes_requested_dependencies(self):
        self.fake_system()
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--dry-run")
        self.assertIn("eza lf", output)
        self.assertIn("zsh-plugins", output)
        self.assertIn("https://github.com/jeffreytse/zsh-vi-mode.git", output)
        self.assertFalse(self.log.exists())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_zsh_profile_packages_map_on_both_distros(self):
        self.fake_system()
        for distro in ("arch", "debian"):
            self.release.write_text("ID=" + distro + "\n")
            output = self.cli("packages", "--shell", "none", "--terminal", "none", "--tools", "eza,lf", "--dry-run")
            self.assertIn("eza lf", output)
            self.assertFalse(self.log.exists())

    def test_system_zshenv_fragment_preserves_defaults_and_is_repeatable(self):
        destination = self.base / "etc/zsh/zshenv"
        destination.parent.mkdir(parents=True)
        original = '# distro configuration\nexport DISTRO_DEFAULT=kept\n'
        destination.write_text(original)
        self.env["ZSH_GLOBAL_ENV_FILE"] = str(destination)
        script = r'''
set -euo pipefail
source "$1/lib/core.sh"
source "$1/lib/installers/zsh.sh"
ROOT=$1
backup_dir=$2
dry=0
system_zshenv=1
# All target paths are inside the temporary fixture; no sudo/system writes occur.
privileged() { "$@"; }
install_system_zshenv
install_system_zshenv
'''
        result = subprocess.run(["bash", "-c", script, "test", str(ROOT), str(self.base / "backups")], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        merged = destination.read_text()
        self.assertTrue(merged.startswith(original))
        self.assertEqual(merged.count("# dotfiles-pro: XDG Zsh startup"), 1)
        self.assertEqual((self.base / "backups/system/zshenv").read_text(), original)
        self.assertIn("already installed", result.stdout)

    def test_system_zshenv_option_requires_zsh_and_dry_run_does_not_write(self):
        self.cli("setup", "--shell", "fish", "--system-zshenv", "--yes", ok=False)
        destination = self.base / "global-env"
        self.env["ZSH_GLOBAL_ENV_FILE"] = str(destination)
        output = self.cli("setup", "--shell", "zsh", "--tools", "none", "--terminal", "none", "--system-zshenv", "--dry-run")
        self.assertIn("Append XDG bootstrap", output)
        self.assertFalse(destination.exists())

    def test_shells_resolve_symlinked_repo(self):
        self.cli("install", "--components", "bash,zsh,fish", "--yes")
        for executable, args in [
            ("bash", ["--noprofile", "--rcfile", str(self.home / ".bashrc"), "-ic", 'printf "%s" "$DOTFILES_HOME"']),
            ("zsh", ["-ic", 'printf "%s" "$DOTFILES_HOME"'])]:
            result = subprocess.run([executable, *args], env=self.env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(ROOT), result.stdout)
        # Runtime universal-variable updates must stay in the temporary home,
        # not in the repository behind the installer's directory symlink.
        fish_config = self.home / ".config/fish"
        fish_config.unlink()
        shutil.copytree(ROOT / "config/fish", fish_config)
        (self.home / "lib").mkdir(exist_ok=True)
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
        result = subprocess.run(["fish", "-c", "type nvm; type install"], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo apt install", result.stdout)

    def test_interactive_wizard(self):
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                [str(CLI), "setup", "--no-packages", "--tools", "none"],
                env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True)
            os.close(slave)
            slave = None
            os.write(master, b"fish\nnone\ny\n")
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stdout + stderr)
            self.assertIn("Shell: fish | Terminal: none", stdout)
            self.assertTrue((self.home / ".config/fish").is_symlink())
            self.assertFalse((self.home / ".bashrc").exists())
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_native_fish_nvm_activates_lts_and_preserves_errors(self):
        fish_config = self.home / ".config/fish"
        fish_config.parent.mkdir(parents=True)
        shutil.copytree(ROOT / "config/fish", fish_config)
        (self.home / "lib").mkdir(exist_ok=True)
        shutil.copy2(ROOT / "lib/platform.sh", self.home / "lib/platform.sh")
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
            os.write(master, b"zsh\nnone\ny\ny\n")
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

    def test_missing_selected_shell_is_installed_and_made_default(self):
        for family in ("debian", "arch"):
            with self.subTest(family=family):
                self.release.write_text("ID=" + family + "\nVERSION_CODENAME=trixie\n")
                self.fake_system()
                zsh = self.mock / "zsh"
                zsh.unlink(missing_ok=True)
                self.log.unlink(missing_ok=True)
                # Keep package inventory empty for each distro case.
                (self.base / "installed-packages").unlink(missing_ok=True)
                output = self.cli("setup", "--shell", "zsh", "--terminal", "none",
                                  "--tools", "none", "--yes")
                log = self.log.read_text()
                self.assertIn("zsh", log)
                self.assertIn(f"chsh -s {zsh}", log)
                manager = "apt-get install" if family == "debian" else "pacman -S"
                self.assertLess(log.index(manager), log.index("chsh -s"))
                self.assertIn("Default login shell set to zsh", output)
                self.assertTrue((self.home / ".zshrc").is_symlink())

    def test_installed_shell_still_becomes_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        log = self.log.read_text()
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", log)
        self.assertNotIn("apt-get", log)
        self.assertNotIn("pacman", log)

    def test_already_default_shell_skips_chsh(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.env["TEST_ACCOUNT_SHELL"] = str(self.mock / "zsh")
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        self.assertIn("already your default login shell", output)
        self.assertFalse(self.log.exists())

    def test_keep_shell_and_config_only_preserve_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        for mode in ("--keep-shell", "--no-packages"):
            self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", mode, "--yes")
            self.assertFalse(self.log.exists())

    def test_config_only_can_explicitly_change_default(self):
        self.fake_system()
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none",
                 "--no-packages", "--login-shell", "--yes")
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", self.log.read_text())
        self.assertNotIn("apt-get", self.log.read_text())

    def test_login_shell_uses_account_database_instead_of_stale_environment(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.env["SHELL"] = str(self.mock / "zsh")
        self.env["TEST_ACCOUNT_SHELL"] = "/bin/bash"
        self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes")
        self.assertIn(f"chsh -s {self.mock / 'zsh'}", self.log.read_text())

    def test_unregistered_shell_cannot_become_default(self):
        self.fake_system()
        self.seed_shell_dependencies("zsh")
        self.shells.write_text("/bin/bash\n")
        output = self.cli("setup", "--shell", "zsh", "--terminal", "none", "--tools", "none", "--yes", ok=False)
        self.assertIn("not registered", output)
        self.assertFalse(self.log.exists())

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


if __name__ == "__main__":
    unittest.main()
