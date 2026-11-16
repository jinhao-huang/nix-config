"""Synchronize private Hermes state and restart services after native activation."""

from contextlib import ExitStack
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from hermes_constants import clear_named_profile_deleted
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


def apply(policy, injected=None):
    # Read and validate all external inputs before changing usable state.
    states = validate(policy, injected)
    root = Path(policy["hermesHome"])
    profiles = {name: root / "profiles" / name for name in states if name != "default"}
    old_umask = os.umask(0o077)
    try:
        with ExitStack() as cleanup:
            backups = {}
            candidates = {}
            changed = had_state = False
            for name, (config, environment) in states.items():
                home = profiles.get(name, root)
                for directory in [home, *(home / subdir for subdir in policy["stateDirs"])]:
                    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
                    directory.chmod(0o700)

                config_path, env_path = home / "config.yaml", home / ".env"
                managed = [config_path, env_path, home / ".managed"]
                if name != "default":
                    managed.extend([home / "SOUL.md", home / ".no-bundled-skills"])
                previous = {path: read_existing(path) for path in managed}
                changed |= previous[config_path] != config or previous[env_path] != environment
                had_state |= previous[config_path] is not None or previous[env_path] is not None

                stage = Path(
                    cleanup.enter_context(tempfile.TemporaryDirectory(prefix=".activation-", dir=home))
                )
                # Stage on the destination filesystem so rollback needs only renames.
                for index, (path, content) in enumerate(previous.items()):
                    backup = stage / f"previous-{index}" if content is not None else None
                    if backup is not None:
                        backup.write_bytes(content)
                    backups[path] = backup
                candidate = stage / "environment"
                candidate.write_bytes(environment)
                candidates[env_path] = candidate

            # Retain pending work across interruptions and failed restarts.
            if changed and had_state:
                replace_file(root / ".restart-needed", b"")
            try:
                subprocess.run([policy["stateSetup"]], check=True)
                for path, candidate in candidates.items():
                    os.replace(candidate, path)
            except (OSError, subprocess.CalledProcessError):
                for path, backup in backups.items():
                    if backup is None:
                        path.unlink(missing_ok=True)
                    else:
                        os.replace(backup, path)
                raise

            # Make recreated profiles visible only after their state is complete.
            for home in profiles.values():
                clear_named_profile_deleted(home)
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
            inactive_codes = (112, 113)  # launchd: domain or service not found
        else:
            probe = [manager, "--user", "is-active", "--quiet", f"{service}.service"]
            command = [manager, "--user", "restart", f"{service}.service"]
            inactive_codes = (3, 4)  # systemd: inactive or unknown unit
        result = subprocess.run(probe, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            subprocess.run(command, check=True)
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
