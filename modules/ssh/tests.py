import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


INSTALLER = Path(__file__).with_name("install-authorized-keys.sh")


class AuthorizedKeysTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.store = self.root / "store"
        self.store.mkdir(mode=0o775)
        self.store.chmod(0o775)
        self.source = self.store / "authorized_keys"
        self.source.write_text("ssh-ed25519 example-key\n")
        self.target = self.home / ".ssh" / "authorized_keys"

    def install(self, source=None, check=True):
        return subprocess.run(
            ["bash", "-euo", "pipefail", str(INSTALLER), str(source or self.source), str(self.home)],
            check=check,
            capture_output=True,
            text=True,
        )

    def assert_installed(self):
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(self.target.read_bytes(), self.source.read_bytes())
        self.assertEqual(self.target.stat().st_uid, os.getuid())
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.target.parent.stat().st_mode), 0o700)
        self.assertEqual(list(self.target.parent.glob(".authorized_keys.*")), [])

    def test_replaces_store_link_with_regular_file(self):
        self.target.parent.mkdir()
        self.target.symlink_to(self.source)
        self.install()
        self.assert_installed()
        self.assertEqual(stat.S_IMODE(self.store.stat().st_mode), 0o775)

    def test_repeated_activation_updates_and_revokes_keys(self):
        self.install()
        self.install()
        self.assert_installed()
        self.source.write_text("")
        self.install()
        self.assert_installed()

    def test_failed_copy_preserves_existing_file(self):
        self.install()
        original = self.target.read_bytes()
        result = self.install(self.store / "missing", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.target.read_bytes(), original)
        self.assertEqual(list(self.target.parent.glob(".authorized_keys.*")), [])


if __name__ == "__main__":
    unittest.main()
