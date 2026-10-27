import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class CredentialHelperTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.call = self.root / "gh-call"
        self.token = 'test-token-"quoted"\\backslash'
        self.environment = {
            **os.environ,
            "HOME": str(self.root),
            "GH_TEST_CALL": str(self.call),
            "GH_TEST_TOKEN": self.token,
            "GH_TEST_FAIL": "0",
        }

    def run_helper(self, *arguments, payload="ghcr.io"):
        return subprocess.run(
            [os.environ["HELPER"], *arguments],
            input=payload,
            text=True,
            capture_output=True,
            env=self.environment,
            check=False,
        )

    def test_get_returns_docker_credentials_for_fixed_account(self):
        result = self.run_helper("get")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {"Username": "test-user", "Secret": self.token},
        )
        self.assertEqual(result.stderr, "")
        self.assertEqual(
            self.call.read_text().splitlines(),
            ["auth", "token", "--hostname", "github.com", "--user", "test-user"],
        )

    def test_get_accepts_newline_terminated_registry(self):
        result = self.run_helper("get", payload="ghcr.io\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["Secret"], self.token)

    def test_other_registries_never_receive_github_credentials(self):
        for registry in ("docker.io", "ghcr.io.evil.example", "", "ghcr.io\nevil"):
            with self.subTest(registry=registry):
                result = self.run_helper("get", payload=registry)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(
                    result.stdout.strip(), "credentials not found in native keychain"
                )
                self.assertNotIn(self.token, result.stdout + result.stderr)
                self.assertFalse(self.call.exists())

    def test_missing_login_reports_recovery_without_leaking_gh_output(self):
        self.environment["GH_TEST_FAIL"] = "1"
        result = self.run_helper("get")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("gh auth login", result.stdout)
        self.assertNotIn(self.token, result.stdout + result.stderr)

    def test_empty_token_is_not_returned_as_credentials(self):
        self.environment["GH_TEST_TOKEN"] = ""
        result = self.run_helper("get")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("gh auth login", result.stdout)

    def test_list_contains_account_but_no_token(self):
        result = self.run_helper("list", payload="unused")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"ghcr.io": "test-user"})
        self.assertNotIn(self.token, result.stdout + result.stderr)

    def test_list_is_empty_without_login(self):
        self.environment["GH_TEST_FAIL"] = "1"
        result = self.run_helper("list")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {})
        self.assertNotIn(self.token, result.stdout + result.stderr)

    def test_store_and_erase_preserve_gh_credentials(self):
        for action in ("store", "erase"):
            with self.subTest(action=action):
                result = self.run_helper(
                    action, payload=json.dumps({"Secret": self.token})
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Credentials are managed by gh", result.stdout)
                self.assertNotIn(self.token, result.stdout + result.stderr)
                self.assertFalse(self.call.exists())

    def test_invalid_actions_do_not_call_gh(self):
        for arguments in ((), ("unknown",), ("get", "extra")):
            with self.subTest(arguments=arguments):
                result = self.run_helper(*arguments)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.call.exists())


if __name__ == "__main__":
    unittest.main()
