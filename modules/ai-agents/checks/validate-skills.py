"""Validate bundled skill provenance, discovery metadata, and relative links."""

import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

import jsonschema
import yaml
from markdown_it import MarkdownIt


def unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    return json.loads(path.read_text(), object_pairs_hook=unique_keys)


def read_frontmatter(path):
    text = path.read_text()
    if not text.startswith("---\n"):
        raise ValueError("missing YAML frontmatter")
    header, separator, _ = text[4:].partition("\n---\n")
    if not separator:
        raise ValueError("unterminated YAML frontmatter")
    data = yaml.safe_load(header)
    if not isinstance(data, dict):
        raise ValueError("frontmatter must be a mapping")
    return data


def validate(root):
    root = root.resolve()
    errors = []
    schema = read_json(root / "checks/skill-sources.schema.json")
    validator = jsonschema.Draft202012Validator(
        schema, format_checker=jsonschema.FormatChecker()
    )
    registered = {}
    markdown = MarkdownIt()
    for path in sorted((root / "skill-sources").glob("*.json")):
        try:
            source = read_json(path)
            validator.validate(source)
        except (ValueError, jsonschema.ValidationError) as error:
            errors.append(
                f"{path.name}: {error.message if isinstance(error, jsonschema.ValidationError) else error}"
            )
            continue
        expected = (
            source["repository"]
            .removeprefix("https://github.com/")
            .replace("/", "-")
            .lower()
            if source["kind"] == "upstream"
            else "local"
        )
        if path.stem != expected:
            errors.append(f"{path.name}: expected source filename {expected}.json")
        if source["kind"] == "upstream":
            license_path = (root / source["license"]).resolve()
            if not license_path.is_relative_to(root) or not license_path.is_file():
                errors.append(
                    f"{path.name}: license must be an existing file inside the module"
                )
        for name, skill in source["skills"].items():
            if name in registered:
                errors.append(
                    f"{name}: registered in both {registered[name]} and {path.name}"
                )
            registered[name] = path.name
            if skill["local_path"] != f"skills/{name}":
                errors.append(f"{path.name}: {name} must use local_path skills/{name}")
            if source["kind"] == "upstream":
                upstream_path = Path(skill["upstream_path"])
                if upstream_path.is_absolute() or ".." in upstream_path.parts:
                    errors.append(f"{path.name}: {name} has an invalid upstream_path")

    bundles = {}
    for path in sorted((root / "skills").iterdir()):
        if path.is_symlink() or not path.is_dir():
            errors.append(
                f"skills/{path.name}: expected a bundled directory; external skills belong in profiles"
            )
            continue
        bundles[path.name] = path
        if (
            not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", path.name)
            or len(path.name) > 64
        ):
            errors.append(f"skills/{path.name}: invalid skill name")
        if not (path / "SKILL.md").is_file():
            errors.append(f"skills/{path.name}: missing SKILL.md")
            continue
        try:
            metadata = read_frontmatter(path / "SKILL.md")
            if metadata.get("name") != path.name:
                errors.append(f"{path.name}: frontmatter name must match its directory")
            description = metadata.get("description")
            if (
                not isinstance(description, str)
                or not description.strip()
                or len(description) > 1024
            ):
                errors.append(
                    f"{path.name}: description must contain 1-1024 characters"
                )
            explicit = metadata.get("disable-model-invocation", False)
            if not isinstance(explicit, bool):
                errors.append(
                    f"{path.name}: disable-model-invocation must be a boolean"
                )
            openai = path / "agents/openai.yaml"
            policy = yaml.safe_load(openai.read_text()) if openai.exists() else {}
            if not isinstance(policy, dict) or not isinstance(
                policy.get("policy", {}), dict
            ):
                raise ValueError("agents/openai.yaml and its policy must be mappings")
            implicit = policy.get("policy", {}).get("allow_implicit_invocation", True)
            if not isinstance(implicit, bool) or implicit != (not explicit):
                errors.append(
                    f"{path.name}: Claude and Codex invocation policies disagree"
                )
        except (ValueError, yaml.YAMLError) as error:
            errors.append(f"{path.name}: {error}")

        for file in sorted(path.rglob("*")):
            if file.is_symlink():
                errors.append(
                    f"{file.relative_to(root)}: bundled files must not be symlinks"
                )
            elif file.suffix == ".md":
                for block in markdown.parse(file.read_text()):
                    for token in block.children or []:
                        target = (
                            token.attrGet("href")
                            if token.type == "link_open"
                            else token.attrGet("src")
                            if token.type == "image"
                            else None
                        )
                        if not target:
                            continue
                        link = urlsplit(target)
                        if (
                            link.scheme
                            or link.netloc
                            or not link.path
                            or link.path.startswith(("/", "~"))
                        ):
                            continue
                        resolved = (file.parent / unquote(link.path)).resolve()
                        if not resolved.is_relative_to(root) or not resolved.exists():
                            errors.append(
                                f"{file.relative_to(root)}: broken module-relative link {target}"
                            )

    for name in sorted(bundles.keys() - registered.keys()):
        errors.append(f"{name}: missing source record")
    for name in sorted(registered.keys() - bundles.keys()):
        errors.append(f"{name}: source record has no bundled skill")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root", nargs="?", type=Path, default=Path(__file__).resolve().parent.parent
    )
    arguments = parser.parse_args()
    errors = validate(arguments.root)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        "Skill source records, metadata, invocation policies, and relative links are valid."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
