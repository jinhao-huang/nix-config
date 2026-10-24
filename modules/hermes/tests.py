"""Regression checks for private state synchronization and service restart policy."""

import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, os.environ["HERMES_SOURCE"])
import runtime


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="hermes-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "hermes"
        self.config = self.root / "config.json"
        self.config.write_text(json.dumps({"model": {"provider": "custom", "default": "fixture"}}))
        self.setup = self.root / "setup"
        self.setup.write_text(
            f"#!{sys.executable}\nfrom pathlib import Path\n"
            f"Path({str(self.home / 'config.yaml')!r}).write_bytes("
            f"Path({str(self.config)!r}).read_bytes())\n"
            f"Path({str(self.home / '.managed')!r}).write_text('home-manager')\n"
        )
        self.setup.chmod(0o700)
        self.calls = self.root / "calls"
        self.manager = self.root / "manager"
        self.active, self.failure = self.root / "active", self.root / "fail"
        self.probe_failure = self.root / "probe-fail"
        self.active.touch()
        self.manager.write_text(
            f"#!{sys.executable}\nimport sys\nfrom pathlib import Path\n"
            f"with Path({str(self.calls)!r}).open('a') as output:\n"
            " output.write(' '.join(sys.argv[1:]) + '\\n')\n"
            "probe = 'is-active' in sys.argv or 'print' in sys.argv\n"
            f"status = 0 if Path({str(self.active)!r}).exists() else (113 if 'print' in sys.argv else 3)\n"
            f"if Path({str(self.probe_failure)!r}).exists(): status = 1\n"
            "sys.exit(status if probe "
            f"else (1 if Path({str(self.failure)!r}).exists() else 0))\n"
        )
        self.manager.chmod(0o700)
        self.policy = {
            "configFile": str(self.config),
            "environment": {},
            "environmentFiles": [],
            "hermesHome": str(self.home),
            "stateDirs": ["sessions", "memories", "logs", "cron", "plugins"],
            "stateSetup": str(self.setup),
            "platform": "linux",
            "manager": str(self.manager),
            "services": ["hermes-agent", "hermes-backend"],
        }

    def apply(self):
        previous = os.umask(0o022)
        try:
            runtime.apply(self.policy)
        finally:
            os.umask(previous)

    def test_initial_private_state_and_unchanged_activation(self):
        self.home.mkdir(mode=0o755)
        (self.home / "sessions").mkdir(mode=0o755)
        self.apply()
        for path in [self.home, *(self.home / name for name in self.policy["stateDirs"])]:
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700)
        for name in ["config.yaml", ".env", ".managed"]:
            self.assertEqual(stat.S_IMODE((self.home / name).stat().st_mode), 0o600)
        self.apply()
        runtime.restart(self.policy)
        self.assertFalse(self.calls.exists())

    def test_removed_yaml_keys_and_secret_rotation_restart(self):
        secret = self.root / "secrets.env"
        secret.write_text("TOKEN=first\n")
        secret.chmod(0o600)
        self.policy["environmentFiles"] = [str(secret)]
        self.apply()
        config = json.loads(self.config.read_text())
        config["removed_setting"] = True
        self.config.write_text(json.dumps(config))
        self.apply()
        runtime.restart(self.policy)
        del config["removed_setting"]
        self.config.write_text(json.dumps(config))
        self.apply()
        self.assertNotIn("removed_setting", (self.home / "config.yaml").read_text())
        runtime.restart(self.policy)
        secret.write_text("TOKEN=second\n")
        self.apply()
        self.assertIn(b"TOKEN=second", (self.home / ".env").read_bytes())
        runtime.restart(self.policy)
        self.assertEqual(self.calls.read_text().count("--user restart hermes-agent.service"), 3)

    def test_environment_order_and_clearing_last_source(self):
        secret = self.root / "secrets.env"
        secret.write_text("VALUE=private\n")
        secret.chmod(0o600)
        self.policy.update(environment={"VALUE": "public"}, environmentFiles=[str(secret)])
        self.apply()
        from dotenv import dotenv_values
        self.assertEqual(dotenv_values(self.home / ".env")["VALUE"], "private")
        self.policy.update(environment={}, environmentFiles=[])
        self.apply()
        self.assertEqual((self.home / ".env").read_bytes(), b"")
        self.assertTrue((self.home / ".restart-needed").exists())

    def test_invalid_inputs_preserve_existing_files(self):
        self.apply()
        before = {name: (self.home / name).read_bytes() for name in ["config.yaml", ".env"]}
        self.policy["environmentFiles"] = [str(self.root / "missing")]
        with self.assertRaises(FileNotFoundError):
            self.apply()
        for name, content in before.items():
            self.assertEqual((self.home / name).read_bytes(), content)
        self.assertFalse((self.home / ".restart-needed").exists())

    def test_setup_failure_restores_config_and_keeps_environment(self):
        self.apply()
        before = (self.home / "config.yaml").read_bytes()
        self.config.write_text(json.dumps({"model": {"provider": "custom", "default": "new"}}))
        self.policy["environment"] = {"VALUE": "new"}
        self.setup.write_text(self.setup.read_text() + "raise SystemExit(1)\n")
        with self.assertRaises(subprocess.CalledProcessError):
            self.apply()
        self.assertEqual((self.home / "config.yaml").read_bytes(), before)
        self.assertEqual((self.home / ".env").read_bytes(), b"")

    def test_failed_restart_is_retried_after_unchanged_activation(self):
        self.apply()
        self.policy["environment"] = {"VALUE": "changed"}
        self.apply()
        self.failure.touch()
        with self.assertRaises(subprocess.CalledProcessError):
            runtime.restart(self.policy)
        self.assertTrue((self.home / ".restart-needed").exists())
        self.failure.unlink()
        self.apply()
        runtime.restart(self.policy)
        self.assertFalse((self.home / ".restart-needed").exists())

    def test_environment_publication_failure_restores_both_files(self):
        self.apply()
        previous = (self.home / "config.yaml").read_bytes()
        self.config.write_text(json.dumps({"model": {"provider": "custom", "default": "new"}}))
        self.policy["environment"] = {"VALUE": "new"}
        replace = os.replace

        def fail_environment(source, destination):
            if Path(source).name == "environment":
                raise OSError("Synthetic environment publication failure")
            return replace(source, destination)

        with patch("runtime.os.replace", side_effect=fail_environment):
            with self.assertRaises(OSError):
                self.apply()
        self.assertEqual((self.home / "config.yaml").read_bytes(), previous)
        self.assertEqual((self.home / ".env").read_bytes(), b"")

    def test_service_query_errors_remain_pending_on_both_platforms(self):
        self.apply()
        for platform in ["linux", "darwin"]:
            with self.subTest(platform=platform):
                self.policy["platform"] = platform
                self.policy["environment"] = {"VALUE": platform}
                self.apply()
                self.probe_failure.touch()
                with self.assertRaises(subprocess.CalledProcessError):
                    runtime.restart(self.policy)
                self.assertTrue((self.home / ".restart-needed").exists())
                self.probe_failure.unlink()
                runtime.restart(self.policy)
                self.assertFalse((self.home / ".restart-needed").exists())

    def test_darwin_restarts_loaded_agents_and_skips_unloaded_agents(self):
        self.policy["platform"] = "darwin"
        self.apply()
        self.policy["environment"] = {"VALUE": "changed"}
        self.apply()
        runtime.restart(self.policy)
        calls = self.calls.read_text()
        for service in self.policy["services"]:
            self.assertIn(f"kickstart -k gui/{os.getuid()}/org.nix-community.home.{service}", calls)
        self.active.unlink()
        self.policy["environment"] = {}
        self.apply()
        runtime.restart(self.policy)
        self.assertEqual(self.calls.read_text().count("kickstart"), 2)


if __name__ == "__main__":
    unittest.main()
