"""Validate declarative Hermes prerequisites without writing state or exposing secrets."""

import json
from pathlib import Path
import re
import stat
import sys

from dotenv import dotenv_values
from hermes_yaml import safe_load


def validate(policy):
    settings = safe_load(Path(policy["configFile"]).read_text()) or {}
    model = settings.get("model", {})
    if not isinstance(model, dict) or not all(
        isinstance(model.get(key), str) and model[key].strip()
        for key in ("provider", "default")
    ):
        raise ValueError(
            "Set hermes.settings.model.provider and model.default for this host "
            "in the inventory or hosts/inventory.local.nix."
        )

    environment = dict(policy["environment"])
    for filename in policy["environmentFiles"]:
        path = Path(filename)
        metadata = path.stat()
        if not stat.S_ISREG(metadata.st_mode) or stat.S_IMODE(metadata.st_mode) & 0o077:
            raise ValueError(f"Environment file must be a private regular file (0600 or 0400): {path}")
        # Match upstream: public environment first, then each private file in order.
        with path.open() as source:
            environment.update(dotenv_values(stream=source, interpolate=False))

    if settings.get("platforms", {}).get("telegram", {}).get("enabled", False):
        if not (environment.get("TELEGRAM_BOT_TOKEN") or "").strip():
            raise ValueError("Telegram is enabled; provide TELEGRAM_BOT_TOKEN in an environment file.")
        allow_all = (environment.get("TELEGRAM_ALLOW_ALL_USERS") or "").strip().lower()
        if allow_all not in ("", "0", "false", "no", "off"):
            raise ValueError("Use explicit TELEGRAM_ALLOWED_USERS instead of TELEGRAM_ALLOW_ALL_USERS.")
        users = (environment.get("TELEGRAM_ALLOWED_USERS") or "").split(",")
        if not users or any(not re.fullmatch(r"[1-9][0-9]*", user.strip()) for user in users):
            raise ValueError("Telegram needs TELEGRAM_ALLOWED_USERS with comma-separated numeric user IDs.")


if __name__ == "__main__":
    try:
        validate(json.loads(Path(sys.argv[1]).read_text()))
    except (OSError, ValueError) as error:
        print(f"hermes-agent: {error}", file=sys.stderr)
        sys.exit(1)
