"""Offline regression tests for docker."""


from support import InstallerTestCase


class DockerTests(InstallerTestCase):
    def test_fedora_existing_engine_gets_only_compose(self):
        self.release.write_text("ID=fedora\n")
        self.fake_system()
        self.mock_command("docker", '[[ "${1:-}" != compose ]]')
        self.cli("packages", "--tools", "docker", "--yes")
        self.assertEqual(self.log.read_text(), "dnf --refresh install -y -- docker-compose\n")

    def test_fedora_podman_provider_conflict_fails_before_changes(self):
        self.release.write_text("ID=fedora\n")
        self.fake_system()
        (self.base / "installed-packages").write_text("podman-docker\n")
        self.mock_command("docker", 'exit 0')
        output = self.cli("setup", "--shell", "none", "--terminal", "none",
                          "--tools", "docker", "--yes", ok=False)
        self.assertIn("conflicts with installed podman-docker", output)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.home / ".config").exists())

    def test_debian_official_docker_and_java(self):
        self.fake_system()
        self.cli("packages", "--shell", "none", "--terminal", "none", "--tools",
                 "docker,java,starship", "--yes")
        log = self.log.read_text()
        self.assertIn("openjdk-21-jdk", log)
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

    def test_missing_compose_preserves_existing_docker(self):
        self.fake_system()
        self.mock_command("docker", '[[ "${1:-}" == --version ]]')
        (self.base / "installed-packages").write_text("docker.io\n")
        output = self.cli("packages", "--shell", "none", "--terminal", "none",
                          "--tools", "docker", "--yes")
        self.assertIn("Docker is already installed", output)
        log = self.log.read_text()
        self.assertIn("apt-get install -y --reinstall docker-compose-v2", log)
        self.assertNotIn("docker-ce", log)
        self.assertNotIn("dotfiles-docker.sources", log)

    def test_skipped_docker_still_honors_service_choice(self):
        self.fake_system()
        self.mock_command("docker", 'exit 0')
        self.cli("packages", "--shell", "none", "--terminal", "none",
                 "--tools", "docker", "--enable-docker", "--yes")
        self.assertEqual(self.log.read_text(), "systemctl enable --now docker\n")
