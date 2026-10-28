"""Prepare private sing-box snapshots and coordinate their systemd activation."""

import copy
from contextlib import contextmanager
import errno
import json
import os
import secrets
import shutil
import socket
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import quote


class Failure(Exception):
    pass


SOURCE_SIZE_LIMIT = 8 * 1024 * 1024
NODE_TYPES = {
    "anytls",
    "http",
    "hysteria",
    "hysteria2",
    "shadowsocks",
    "socks",
    "trojan",
    "tuic",
    "vless",
    "vmess",
}
NON_NODE_TYPES = {"selector", "urltest", "direct", "block", "dns"}
DEPENDENCIES = {
    "detour",
    "bind_interface",
    "inet4_bind_address",
    "inet6_bind_address",
    "protect_path",
    "routing_mark",
    "netns",
    "network_strategy",
    "network_type",
    "fallback_network_type",
    "plugin",
    "plugin_opts",
    "certificate_provider",
}
PROXY_VARIABLES = {
    "http_proxy",
    "https_proxy",
    "all_proxy",
    "ftp_proxy",
    "no_proxy",
}


def canonical_directory(path):
    # Resolve home aliases while preserving the leaf for no-follow checks.
    return path.parent.resolve() / path.name


@contextmanager
def directory_fd(path, *, create=False, missing_ok=False):
    parent = path.parent.resolve()
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
    fd = os.open(parent.anchor, flags)
    try:
        for part in (*parent.parts[1:], path.name):
            info = os.fstat(fd)
            # User-owned XDG parents may be group-writable; leave them unchanged.
            writable_by_others = info.st_mode & (0o022 if info.st_uid == 0 else 0o002)
            if info.st_uid not in (0, os.getuid()) or (
                writable_by_others and not info.st_mode & stat.S_ISVTX
            ):
                raise Failure(f"Unsafe ancestor directory for private data: {path}")
            try:
                child = os.open(part, flags, dir_fd=fd)
            except FileNotFoundError:
                if create:
                    os.mkdir(part, mode=0o700, dir_fd=fd)
                    child = os.open(part, flags, dir_fd=fd)
                elif missing_ok:
                    yield None
                    return
                else:
                    raise
            os.close(fd)
            fd = child
        yield fd
    finally:
        os.close(fd)


def check_directory(info, path, *, check_mode=True):
    if info.st_uid != os.getuid():
        raise Failure(
            f"Private directory must be owned by UID {os.getuid()} "
            f"(got UID {info.st_uid}): {path}"
        )
    if check_mode and stat.S_IMODE(info.st_mode) != 0o700:
        raise Failure(
            f"Private directory must have mode 0700 "
            f"(got {stat.S_IMODE(info.st_mode):04o}): {path}"
        )


def private_directory(path):
    private_location(path)
    with directory_fd(path, create=True) as fd:
        info = os.fstat(fd)
        check_directory(info, path, check_mode=False)
        if stat.S_IMODE(info.st_mode) != 0o700:
            os.fchmod(fd, 0o700)
        check_directory(os.fstat(fd), path)


def private_location(path):
    resolved = path.resolve()
    if resolved.is_relative_to("/nix/store") or any(
        (p / ".git").exists() for p in (resolved, *resolved.parents)
    ):
        raise Failure(
            f"Private data must be outside Git working trees and the Nix store: {path}"
        )


def check_secret(info, path, *, check_mode=True):
    if not stat.S_ISREG(info.st_mode):
        raise Failure(
            f"Secret must be a regular file, not a link or special file: {path}"
        )
    if info.st_uid != os.getuid():
        raise Failure(
            f"Secret must be owned by UID {os.getuid()} "
            f"(got UID {info.st_uid}): {path}"
        )
    if info.st_nlink != 1:
        raise Failure(f"Secret must not have multiple hard links: {path}")
    mode = stat.S_IMODE(info.st_mode)
    if not mode & 0o400 or (check_mode and mode not in (0o400, 0o600)):
        raise Failure(
            f"Secret must be owner-readable with mode 0400 or 0600 "
            f"(got {mode:04o}): {path}"
        )


def private_file(path, *, check_mode=True, repair=False):
    private_location(path)
    with directory_fd(path.parent) as parent_fd:
        check_directory(
            os.fstat(parent_fd), path.parent, check_mode=check_mode and not repair
        )
        info = os.stat(path.name, dir_fd=parent_fd, follow_symlinks=False)
        check_secret(info, path, check_mode=check_mode and not repair)
        flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC | os.O_NONBLOCK
        fd = os.open(path.name, flags, dir_fd=parent_fd)
        try:
            opened = os.fstat(fd)
            check_secret(opened, path, check_mode=check_mode and not repair)
            if (info.st_dev, info.st_ino) != (opened.st_dev, opened.st_ino):
                raise Failure(f"Secret changed during validation: {path}")
            if repair:
                mode = stat.S_IMODE(opened.st_mode) & 0o600
                if stat.S_IMODE(os.fstat(parent_fd).st_mode) != 0o700:
                    os.fchmod(parent_fd, 0o700)
                if stat.S_IMODE(opened.st_mode) != mode:
                    os.fchmod(fd, mode)
                check_directory(os.fstat(parent_fd), path.parent)
                check_secret(os.fstat(fd), path)
        finally:
            os.close(fd)


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        os.chmod(path, 0o600)
        json.dump(value, stream, sort_keys=True, indent=2, ensure_ascii=False)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())


def read_json(path, *, size_limit=None):
    try:
        if size_limit is None:
            content = path.read_text()
        else:
            with path.open("rb") as stream:
                content = stream.read(size_limit + 1)
            if len(content) > size_limit:
                raise Failure(f"Node source exceeds the 8 MiB limit: {path}")
        return json.loads(content)
    except (ValueError, UnicodeError) as error:
        # Parser exceptions can include node contents or passwords.
        raise Failure(f"Invalid JSON in private file: {path}") from error


def check_dependencies(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if item and (key in DEPENDENCIES or key.endswith(("_path", "_file"))):
                raise Failure(
                    f"Proxy node has an unsupported dependency field: {key}"
                )
            check_dependencies(item)
    elif isinstance(value, list):
        for item in value:
            check_dependencies(item)


def import_nodes(document, source):
    if not isinstance(document, dict) or not isinstance(
        document.get("outbounds"), list
    ):
        raise Failure(
            f"Node source {source} must be native sing-box JSON with an outbounds array."
        )
    nodes = []
    tags = set()
    for index, outbound in enumerate(document["outbounds"]):
        if not isinstance(outbound, dict):
            raise Failure(f"Node source {source} outbound {index} must be an object.")
        kind = outbound.get("type")
        if isinstance(kind, str) and kind in NON_NODE_TYPES:
            continue
        if not isinstance(kind, str) or kind not in NODE_TYPES:
            raise Failure(
                f"Node source {source} outbound {index} has an unsupported node type."
            )
        tag = outbound.get("tag")
        if not isinstance(tag, str) or not tag or tag in tags:
            raise Failure(
                f"Node source {source} node {index} needs a unique, nonempty tag."
            )
        tags.add(tag)
        node = copy.deepcopy(outbound)
        # Provider resolver references are replaced by the local bootstrap policy.
        node.pop("domain_resolver", None)
        check_dependencies(node)
        node["domain_resolver"] = "local-dns"
        node["tag"] = f"node/{source}/{tag}"
        nodes.append(node)
    if not nodes:
        raise Failure(
            f"Node source {source} contains no supported independent proxy nodes."
        )
    return nodes


def without_proxy_environment():
    return {
        key: value
        for key, value in os.environ.items()
        if key.lower() not in PROXY_VARIABLES
    }


class Runtime:
    def __init__(self, policy):
        self.policy = policy
        self.config = canonical_directory(Path(policy["configDirectory"]))
        self.state = canonical_directory(Path(policy["stateDirectory"]))
        self.snapshots = self.state / "snapshots"
        self.request = (
            Path(policy["requestFile"]) if policy["requestFile"] is not None else None
        )
        self.nodes = Path(policy["nodesFile"]) if policy["nodesFile"] is not None else None
        self.credentials = Path(policy["credentialsFile"])

    def systemctl(self, *arguments, check=True):
        result = subprocess.run(
            [self.policy["systemctl"], "--user", *arguments],
            capture_output=True,
            text=True,
            timeout=25,
            check=False,
        )
        if check and result.returncode:
            log = self.state / "systemd-error.log"
            log.write_text(result.stdout + result.stderr)
            log.chmod(0o600)
            raise Failure(f"systemd user operation failed; private diagnostics: {log}")
        return result

    def managed_file(self, path):
        return canonical_directory(path.parent) in (self.config, self.state)

    def check_inputs(self, *, allow_permission_repair=False):
        private_location(self.config)
        private_location(self.state)
        private_location(self.credentials)
        for directory in (self.config, self.state, self.snapshots):
            with directory_fd(directory, missing_ok=True) as fd:
                if fd is not None:
                    check_directory(
                        os.fstat(fd),
                        directory,
                        check_mode=not allow_permission_repair,
                    )
        if self.request is None and self.nodes is None:
            raise Failure("Configure subscription.requestFile, nodesFile, or both.")
        for path in (self.request, self.nodes):
            if path is not None:
                private_file(
                    path,
                    check_mode=not (
                        allow_permission_repair and self.managed_file(path)
                    ),
                )
        if self.credentials.exists() or self.credentials.is_symlink():
            private_file(
                self.credentials,
                check_mode=not (
                    allow_permission_repair and self.managed_file(self.credentials)
                ),
            )
        elif not self.managed_file(self.credentials):
            with directory_fd(self.credentials.parent) as fd:
                check_directory(os.fstat(fd), self.credentials.parent)

    def initialize(self):
        self.check_inputs(allow_permission_repair=True)
        # Only these module-owned directories and configured secrets are repaired.
        private_directory(self.config)
        private_directory(self.state)
        private_directory(self.snapshots)
        for path in (self.request, self.nodes, self.credentials):
            if path is not None and path.exists() and self.managed_file(path):
                private_file(path, repair=True)
        self.check_inputs()

    def snapshot(self, name="current"):
        link = self.state / name
        if not link.is_symlink():
            if link.exists():
                raise Failure(f"Expected a snapshot symlink: {link}")
            return None
        target = link.resolve(strict=True)
        if target.parent != self.snapshots or not target.is_dir():
            raise Failure(f"Invalid snapshot reference: {link}")
        return target

    def publish(self, name, snapshot):
        temporary = self.state / ("." + name + "-new")
        temporary.unlink(missing_ok=True)
        temporary.symlink_to(snapshot.relative_to(self.state))
        temporary.replace(self.state / name)

    def authentication(self):
        if not self.credentials.exists():
            if self.managed_file(self.credentials):
                private_directory(self.credentials.parent)
            write_json(
                self.credentials,
                {
                    "username": self.policy["username"],
                    "password": secrets.token_urlsafe(32),
                },
            )
        private_file(self.credentials)
        auth = read_json(self.credentials)
        if not isinstance(auth, dict) or set(auth) != {"username", "password"}:
            raise Failure("Proxy credentials must contain only username and password.")
        for value in auth.values():
            if (
                not isinstance(value, str)
                or not 1 <= len(value.encode()) <= 255
                or any(ord(c) < 32 for c in value)
            ):
                raise Failure(
                    "Proxy username and password must contain 1–255 UTF-8 bytes without control characters."
                )
        return auth

    def preflight_port(self, port):
        with socket.socket() as listener:
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                listener.bind(("127.0.0.1", port))
            except OSError as error:
                current = self.snapshot()
                if (
                    error.errno == errno.EADDRINUSE
                    and current
                    and read_json(current / "config.json")["inbounds"][0]["listen_port"]
                    == port
                    and self.ready(current)
                ):
                    return
                raise Failure(
                    f"Cannot bind 127.0.0.1:{port}; set modules.sing-box.listenPort to a free port."
                ) from error

    def check_config(self, snapshot):
        with (snapshot / "check.log").open("w") as log:
            os.chmod(log.name, 0o600)
            result = subprocess.run(
                [
                    self.policy["singBox"],
                    "check",
                    "-c",
                    str(snapshot / "config.json"),
                    "-D",
                    str(self.state),
                ],
                stdout=log,
                stderr=log,
                timeout=30,
                check=False,
            )
        if result.returncode:
            raise Failure(
                f"sing-box rejected the private configuration; details: {snapshot / 'check.log'}"
            )

    def subscription_nodes(self, candidate):
        response = candidate / "subscription.json"
        with (candidate / "download.log").open("w") as log:
            os.chmod(log.name, 0o600)
            result = subprocess.run(
                [
                    self.policy["curl"],
                    "--disable",
                    "--config",
                    str(self.request),
                    "--silent",
                    "--show-error",
                    "--fail",
                    "--location",
                    "--proto",
                    "=https",
                    "--proto-redir",
                    "=https",
                    "--connect-timeout",
                    "10",
                    "--max-time",
                    "60",
                    "--max-filesize",
                    str(SOURCE_SIZE_LIMIT),
                    "--output",
                    str(response),
                ],
                stdout=log,
                stderr=log,
                env=without_proxy_environment(),
                timeout=65,
                check=False,
            )
        if result.returncode:
            raise Failure(
                f"Subscription download failed; private diagnostics: {candidate / 'download.log'}"
            )
        os.chmod(response, 0o600)
        nodes = import_nodes(
            read_json(response, size_limit=SOURCE_SIZE_LIMIT), "subscription"
        )
        response.unlink()
        return nodes

    def prepare(self):
        self.check_inputs()
        self.systemctl("show-environment")
        keep = {self.snapshot(), self.snapshot("previous")}
        for path in self.snapshots.glob("snapshot-*"):
            if path not in keep and path.is_dir() and not path.is_symlink():
                shutil.rmtree(path)
        auth = self.authentication()
        self.preflight_port(self.policy["listenPort"])
        candidate = Path(tempfile.mkdtemp(prefix="snapshot-", dir=self.snapshots))
        try:
            nodes = []
            if self.nodes is not None:
                nodes += import_nodes(
                    read_json(self.nodes, size_limit=SOURCE_SIZE_LIMIT), "local"
                )
            if self.request is not None:
                nodes += self.subscription_nodes(candidate)
            nodes.sort(key=lambda node: node["tag"])
            config = copy.deepcopy(self.policy["baseConfig"])
            config["inbounds"][0]["users"] = [auth]
            config["outbounds"] += [
                {
                    "type": "urltest",
                    "tag": "proxy",
                    "outbounds": [n["tag"] for n in nodes],
                    "url": "https://www.gstatic.com/generate_204",
                    "interval": "3m",
                    "tolerance": 50,
                },
                *nodes,
            ]
            write_json(candidate / "config.json", config)
            write_json(
                candidate / "runtime.json",
                {
                    "packageId": self.policy["packageId"],
                    "noProxy": self.policy["noProxy"],
                },
            )
            self.check_config(candidate)
            return candidate
        except BaseException:
            # Keep only private diagnostics; never publish an invalid candidate.
            (candidate / "subscription.json").unlink(missing_ok=True)
            raise

    def ready(self, snapshot):
        config = read_json(snapshot / "config.json")
        inbound = config["inbounds"][0]
        if self.systemctl(
            "is-active", "--quiet", "sing-box.service", check=False
        ).returncode:
            return False
        auth = inbound["users"][0]
        try:
            with socket.create_connection(
                ("127.0.0.1", inbound["listen_port"]), timeout=1
            ) as connection:

                def receive(size):
                    data = b""
                    while len(data) < size:
                        chunk = connection.recv(size - len(data))
                        if not chunk:
                            break
                        data += chunk
                    return data

                connection.sendall(b"\x05\x01\x02")
                if receive(2) != b"\x05\x02":
                    return False
                username, password = (
                    auth["username"].encode(),
                    auth["password"].encode(),
                )
                connection.sendall(
                    b"\x01"
                    + bytes([len(username)])
                    + username
                    + bytes([len(password)])
                    + password
                )
                return receive(2) == b"\x01\x00"
        except OSError:
            return False

    def restart(self, snapshot):
        state = self.systemctl(
            "show", "sing-box.service", "-p", "ActiveState", "--value"
        ).stdout.strip()
        if state == "failed":
            self.systemctl("reset-failed", "sing-box.service")
        self.systemctl("restart", "sing-box.service")
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if self.ready(snapshot):
                return
            time.sleep(0.2)
        raise Failure(
            "sing-box did not become active with working SOCKS authentication."
        )

    def apply(self, candidate):
        if (
            candidate.parent != self.snapshots
            or candidate.is_symlink()
            or not candidate.is_dir()
        ):
            raise Failure("Invalid prepared snapshot.")
        old = self.snapshot()
        if (
            old
            and all(
                (old / name).read_bytes() == (candidate / name).read_bytes()
                for name in ("config.json", "runtime.json")
            )
            and self.ready(old)
        ):
            shutil.rmtree(candidate)
            print(
                "sing-box configuration is unchanged; the running proxy was retained."
            )
            return
        self.preflight_port(self.policy["listenPort"])
        if old:
            # Preserve the running snapshot even if activation is interrupted after publication.
            self.publish("previous", old)
        self.publish("current", candidate)
        try:
            self.restart(candidate)
        except BaseException as error:
            if old:
                self.publish("current", old)
                try:
                    self.restart(old)
                except Exception as recovery:
                    raise Failure(
                        "New proxy failed; the previous configuration was restored, but service recovery "
                        "with the current sing-box package also failed. Inspect journalctl --user -u sing-box; "
                        "restore the previous Home Manager generation and its saved private configuration if needed."
                    ) from recovery
                raise Failure(
                    "New proxy failed; the previous configuration is running with the current sing-box package. "
                    "Activation aborted."
                ) from error
            else:
                (self.state / "current").unlink()
                self.systemctl("stop", "sing-box.service")
                raise Failure(
                    "New proxy failed; no previous configuration exists. "
                    "Activation aborted; inspect journalctl --user -u sing-box."
                ) from error
        print(
            f"sing-box is ready on authenticated HTTP/SOCKS 127.0.0.1:{self.policy['listenPort']}."
        )

    def with_proxy(self, command):
        if not command:
            raise Failure("Usage: with-proxy COMMAND [ARGUMENT ...]")
        snapshot = self.snapshot()
        if snapshot is None or not self.ready(snapshot):
            raise Failure(
                "The managed sing-box proxy is unavailable; command was not started."
            )
        config = read_json(snapshot / "config.json")
        inbound = config["inbounds"][0]
        auth = inbound["users"][0]
        authority = f"{quote(auth['username'], safe='')}:{quote(auth['password'], safe='')}@127.0.0.1:{inbound['listen_port']}"
        environment = without_proxy_environment()
        environment.update(
            {
                "http_proxy": "http://" + authority,
                "https_proxy": "http://" + authority,
                "HTTPS_PROXY": "http://" + authority,
                "all_proxy": "socks5h://" + authority,
                "ALL_PROXY": "socks5h://" + authority,
                "no_proxy": ",".join(read_json(snapshot / "runtime.json")["noProxy"]),
            }
        )
        environment["NO_PROXY"] = environment["no_proxy"]
        os.execvpe(command[0], command, environment)


def main():
    os.umask(0o077)
    runtime = Runtime(read_json(Path(sys.argv[1])))
    action = sys.argv[2]
    if action == "prepare":
        print(runtime.prepare())
    elif action == "apply":
        runtime.apply(Path(sys.argv[3]))
    elif action == "with-proxy":
        runtime.with_proxy(sys.argv[3:])
    elif action == "check_inputs":
        runtime.check_inputs(allow_permission_repair=True)
    elif action == "initialize":
        runtime.initialize()
    else:
        raise Failure("Unknown sing-box runtime operation.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, TypeError, KeyError, UnicodeError):
        print("sing-box: Invalid private runtime data.", file=sys.stderr)
        sys.exit(1)
    except (Failure, OSError, subprocess.TimeoutExpired) as error:
        # Do not print subprocess commands: curl arguments can reference secrets.
        message = (
            "External operation timed out."
            if isinstance(error, subprocess.TimeoutExpired)
            else str(error)
        )
        print(f"sing-box: {message}", file=sys.stderr)
        sys.exit(1)
