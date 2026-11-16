"""Validate declarative Hermes prerequisites without writing state or exposing secrets."""

import json
from io import StringIO
from pathlib import Path
import re
import stat
import sys

from dotenv import dotenv_values
from dotenv.parser import parse_stream
from hermes_yaml import safe_load


def validate_config(filename, environment):
    config = Path(filename).read_bytes()
    settings = safe_load(config) or {}
    model = settings.get("model", {})
    if not isinstance(model, dict) or not all(
        isinstance(model.get(key), str) and model[key].strip()
        for key in ("provider", "default")
    ):
        raise ValueError(
            "Set hermes.settings.model.provider and model.default for this host "
            "in the inventory or hosts/inventory.local.nix."
        )

    if settings.get("platforms", {}).get("telegram", {}).get("enabled", False):
        if not (environment.get("TELEGRAM_BOT_TOKEN") or "").strip():
            raise ValueError("Telegram is enabled; provide TELEGRAM_BOT_TOKEN in an environment file.")
        allow_all = (environment.get("TELEGRAM_ALLOW_ALL_USERS") or "").strip().lower()
        if allow_all not in ("", "0", "false", "no", "off"):
            raise ValueError("Use explicit TELEGRAM_ALLOWED_USERS instead of TELEGRAM_ALLOW_ALL_USERS.")
        users = (environment.get("TELEGRAM_ALLOWED_USERS") or "").split(",")
        if not users or any(not re.fullmatch(r"[1-9][0-9]*", user.strip()) for user in users):
            raise ValueError("Telegram needs TELEGRAM_ALLOWED_USERS with comma-separated numeric user IDs.")

    return config


def validate(policy, injected=None):
    content = "".join(f"{key}={value}\n" for key, value in policy["environment"].items())
    for filename in policy["environmentFiles"]:
        path = Path(filename)
        metadata = path.stat()
        if not stat.S_ISREG(metadata.st_mode) or stat.S_IMODE(metadata.st_mode) & 0o077:
            raise ValueError(f"Environment file must be a private regular file (0600 or 0400): {path}")
        content += "\n" + path.read_text()

    if keys := policy.get("protonPassKeys"):
        if injected is None:
            injected = sys.stdin.read()
        resolved = dotenv_values(stream=StringIO(injected), interpolate=False)
        for key in keys:
            value = resolved.get(key) or ""
            if not value.strip() or re.search(r"\{\{\s*pass://", value):
                raise ValueError(f"Proton Pass did not resolve a value for {key}.")
        content += "\n" + injected

    # Public environment first, then private files in order, then injected values.
    environment = dotenv_values(stream=StringIO(content), interpolate=False)
    states = {"default": (validate_config(policy["configFile"], environment), content.encode())}
    if profiles := policy.get("namedProfiles"):
        # Retain the quoting of the last assignment for each selected key.
        assignments = {
            binding.key: binding.original.string.strip("\r\n")
            for binding in parse_stream(StringIO(content))
            if binding.key is not None
        }
        for name, profile in profiles.items():
            selected = {}
            for key in profile["environmentKeys"]:
                value = environment.get(key) or ""
                if not value.strip():
                    raise ValueError(f"Hermes profile {name} needs {key} in the configured environment.")
                selected[key] = value
            profile_content = "".join(f"{assignments[key]}\n" for key in selected).encode()
            states[name] = (validate_config(profile["configFile"], selected), profile_content)
    return states


if __name__ == "__main__":
    try:
        validate(json.loads(Path(sys.argv[1]).read_text()))
    except (OSError, ValueError) as error:
        print(f"hermes-agent: {error}", file=sys.stderr)
        sys.exit(1)
