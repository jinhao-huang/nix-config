"""Failure-oriented checks for the skill catalog validator."""

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "validate_skills", Path(__file__).with_name("validate-skills.py")
)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class SkillValidationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "checks").mkdir()
        shutil.copyfile(
            Path(__file__).with_name("skill-sources.schema.json"),
            self.root / "checks/skill-sources.schema.json",
        )
        (self.root / "skill-sources").mkdir()
        self.skill = self.root / "skills/alpha"
        self.skill.mkdir(parents=True)
        self.document = self.skill / "SKILL.md"
        self.document.write_text(
            "---\nname: alpha\ndescription: Run alpha tasks.\n---\n\nRun alpha.\n"
        )
        self.source = self.root / "skill-sources/local.json"
        self.source.write_text(
            json.dumps(
                {
                    "kind": "local",
                    "reviewed_on": "2026-10-21",
                    "skills": {
                        "alpha": {
                            "local_path": "skills/alpha",
                            "notes": "Local workflow.",
                        }
                    },
                }
            )
        )

    def assert_invalid(self, message):
        self.assertTrue(
            any(message in error for error in validator.validate(self.root)), message
        )

    def test_valid_local_and_upstream_sources(self):
        beta = self.root / "skills/beta"
        beta.mkdir()
        (beta / "SKILL.md").write_text(
            "---\nname: beta\ndescription: Run beta tasks.\n---\n\n"
            "Read [alpha](../alpha/SKILL.md).\n"
        )
        (beta / "LICENSE").write_text("Upstream license.\n")
        (self.root / "skill-sources/example-skills.json").write_text(
            json.dumps(
                {
                    "kind": "upstream",
                    "repository": "https://github.com/example/skills",
                    "revision": "a" * 40,
                    "reviewed_on": "2026-10-21",
                    "license": "skills/beta/LICENSE",
                    "skills": {
                        "beta": {
                            "local_path": "skills/beta",
                            "upstream_path": "beta",
                            "adaptations": [],
                        }
                    },
                }
            )
        )
        self.assertEqual(validator.validate(self.root), [])

    def test_missing_and_orphaned_records(self):
        data = json.loads(self.source.read_text())
        data["skills"] = {
            "beta": {"local_path": "skills/beta", "notes": "Missing bundle."}
        }
        self.source.write_text(json.dumps(data))
        self.assert_invalid("alpha: missing source record")
        self.assert_invalid("beta: source record has no bundled skill")

    def test_duplicate_records_and_json_keys(self):
        duplicate = self.root / "skill-sources/duplicate.json"
        shutil.copyfile(self.source, duplicate)
        self.assert_invalid("registered in both")
        duplicate.write_text('{"kind":"local","kind":"upstream"}')
        self.assert_invalid("duplicate JSON key")

    def test_invalid_source_metadata(self):
        data = json.loads(self.source.read_text())
        data["reviewed_on"] = "2026-13-01"
        self.source.write_text(json.dumps(data))
        self.assert_invalid("not a 'date'")
        data["reviewed_on"] = "2026-10-21"
        data["revision"] = "main"
        self.source.write_text(json.dumps(data))
        self.assert_invalid("local.json:")

    def test_bundle_name_and_description(self):
        self.document.write_text(
            "---\nname: beta\ndescription: ''\n---\n\nRun alpha.\n"
        )
        self.assert_invalid("name must match")
        self.assert_invalid("description must contain")

    def test_invocation_policy_mismatch(self):
        self.document.write_text(
            self.document.read_text().replace(
                "name: alpha", "name: alpha\ndisable-model-invocation: true"
            )
        )
        self.assert_invalid("invocation policies disagree")
        (self.skill / "agents").mkdir()
        (self.skill / "agents/openai.yaml").write_text(
            "policy:\n  allow_implicit_invocation: false\n"
        )
        self.assertEqual(validator.validate(self.root), [])

    def test_broken_supporting_link_but_not_code_examples(self):
        (self.skill / "references").mkdir()
        reference = self.skill / "references/guide.md"
        reference.write_text("Read [details](missing.md).\n")
        self.assert_invalid("broken module-relative link missing.md")
        reference.write_text("```markdown\n[example](missing.md)\n```\n")
        self.assertEqual(validator.validate(self.root), [])

    def test_external_symlinks_are_not_bundles(self):
        (self.root / "skills/external").symlink_to("/nonexistent/application/skills")
        self.assert_invalid("external skills belong in profiles")


if __name__ == "__main__":
    unittest.main()
