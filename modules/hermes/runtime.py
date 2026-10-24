"""Synchronize private Hermes state and restart services after native activation."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from validate import validate


def replace_file(path, content):
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(content)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def read_existing(path):
    return path.read_bytes() if path.exists() else None


def apply(policy):
    # Read and validate all external inputs before changing usable state.
    config, environment = validate(policy)
    home = Path(policy["hermesHome"])
    config_path, env_path = home / "config.yaml", home / ".env"
    previous_config, previous_env = read_existing(config_path), read_existing(env_path)
    changed = previous_config != config or previous_env != environment
    for directory in [home, *(home / name for name in policy["stateDirs"])]:
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        directory.chmod(0o700)

    old_umask = os.umask(0o077)
    try:
        with tempfile.TemporaryDirectory(prefix=".activation-", dir=home) as temporary:
            stage = Path(temporary)
            # Reserve rollback copies before upstream can overwrite config.yaml.
            # Renaming these back does not require free space for another copy.
            backups = [(config_path, previous_config), (env_path, previous_env)]
            for index, (_, content) in enumerate(backups):
                if content is not None:
                    (stage / f"previous-{index}").write_bytes(content)
            candidate = stage / "environment"
            candidate.write_bytes(environment)
            # Retain pending work across interruptions and failed restarts.
            if changed and (previous_config is not None or previous_env is not None):
                replace_file(home / ".restart-needed", b"")
            try:
                subprocess.run([policy["stateSetup"]], check=True)
                # Empty declarations publish an empty file, revoking old values.
                os.replace(candidate, env_path)
            except (OSError, subprocess.CalledProcessError):
                for index, (path, content) in enumerate(backups):
                    if content is None:
                        path.unlink(missing_ok=True)
                    else:
                        os.replace(stage / f"previous-{index}", path)
                raise
    finally:
        os.umask(old_umask)


def restart(policy):
    marker = Path(policy["hermesHome"]) / ".restart-needed"
    if not marker.exists():
        return
    manager = policy["manager"]
    for service in policy["services"]:
        if policy["platform"] == "darwin":
            target = f"gui/{os.getuid()}/org.nix-community.home.{service}"
            probe = [manager, "print", target]
            command = [manager, "kickstart", "-k", target]
            inactive_codes = (113,)  # launchd: service not found
            environment = os.environ.copy()
        else:
            probe = [manager, "--user", "is-active", "--quiet", f"{service}.service"]
            command = [manager, "--user", "restart", f"{service}.service"]
            inactive_codes = (3, 4)  # systemd: inactive or unknown unit
            environment = os.environ.copy()
            environment.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        result = subprocess.run(probe, env=environment, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            subprocess.run(command, env=environment, check=True)
        elif result.returncode not in inactive_codes:
            raise subprocess.CalledProcessError(result.returncode, probe)
    marker.unlink()


if __name__ == "__main__":
    try:
        policy = json.loads(Path(sys.argv[1]).read_text())
        {"apply": apply, "restart": restart}[sys.argv[2]](policy)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"hermes-agent: {error}", file=sys.stderr)
        sys.exit(1)
