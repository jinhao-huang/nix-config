"""Publish the target's Proton Pass credentials through its configured SSH alias."""

import base64
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


RECEIVE = """
set -eu
umask 077
directory=${1%/*}
mkdir -p -- "$directory"
chmod 700 -- "$directory"
# A complete newline-terminated record is required before replacing the file.
IFS= read -r encoded
test -n "$encoded"
temporary=$(mktemp -- "$directory/.hermes.env.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
printf '%s' "$encoded" | base64 -d > "$temporary"
mv -fT -- "$temporary" "$1"
"""


def publish(ssh, target):
    entries = []
    for key in target["keys"]:
        value = os.environ.pop(key, "")
        if (
            not value.strip()
            or value.startswith("pass://")
            or "${" in value
            or value.splitlines() != [value]
        ):
            raise ValueError(f"Missing or unsupported Proton Pass value for {key}.")
        # Hermes's profile reader handles escaped backslashes and double quotes.
        quoted = value.replace("\\", "\\\\").replace('"', '\\"')
        entries.append(f'{key}="{quoted}"\n')
    payload = base64.b64encode("".join(entries).encode()) + b"\n"
    command = shlex.join(["bash", "-c", RECEIVE, "hermes-secrets", target["path"]])
    subprocess.run([ssh, "-T", target["destination"], command], input=payload, check=True)
    print(f"Published Hermes credentials to {target['destination']}:{target['path']}.")


def main(inventory, proton_pass, ssh, *args):
    targets = json.loads(Path(inventory).read_text())
    if args == ("--help",):
        print("Usage: hermes-secrets HOST\nTargets: " + ", ".join(targets))
        return
    if len(args) == 2 and args[0] == "--publish" and args[1] in targets:
        publish(ssh, targets[args[1]])
        return
    if len(args) != 1 or args[0] not in targets:
        raise ValueError("Usage: hermes-secrets HOST (choose " + ", ".join(targets) + ")")

    host = args[0]
    os.execv(
        proton_pass,
        [
            proton_pass, "run", "--env-file", targets[host]["references"], "--",
            sys.executable, __file__, inventory, proton_pass, ssh, "--publish", host,
        ],
    )


if __name__ == "__main__":
    try:
        main(*sys.argv[1:])
    except subprocess.CalledProcessError:
        sys.exit("hermes-secrets: SSH publication failed.")
    except (OSError, ValueError) as error:
        sys.exit(f"hermes-secrets: {error}")
