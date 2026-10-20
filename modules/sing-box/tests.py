"""Failure-oriented tests; run with python3 modules/sing-box/tests.py."""

import importlib.util
import json
import os
import socket
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

spec = importlib.util.spec_from_file_location(
    "sing_box_runtime", Path(__file__).with_name("runtime.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.root.chmod(0o700)
        request = self.root / "subscription.curl"
        request.write_text('url = "https://example.invalid/private-token"\n')
        request.chmod(0o600)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        self.policy = {
            "stateDirectory": str(self.root / "state"),
            "requestFile": str(request),
            "nodesFile": None,
            "credentialsFile": str(self.root / "state/auth.json"),
            "username": "tester",
            "curl": "curl",
            "systemctl": "systemctl",
            "singBox": "/test/sing-box",
            "packageId": "original-package",
            "listenPort": port,
            "noProxy": ["localhost", "127.0.0.1", "internal"],
            "baseConfig": {
                "inbounds": [{"type": "mixed", "listen_port": port}],
                "route": {"final": "proxy"},
                "outbounds": [{"type": "direct", "tag": "direct"}],
            },
        }
        self.runtime = module.Runtime(self.policy)
        self.runtime.initialize()
        self.document = {
            "outbounds": [
                {"type": "vless", "tag": "node-a", "server": "example.invalid"}
            ]
        }
        self.downloads = 0
        self.download_status = 0
        self.check_status = 0
        self.process = mock.patch.object(
            module.subprocess, "run", side_effect=self.subprocess
        )
        self.process.start()
        self.addCleanup(self.process.stop)

    def subprocess(self, arguments, **kwargs):
        if arguments[0] == "curl":
            self.downloads += 1
            Path(arguments[arguments.index("--output") + 1]).write_text(
                json.dumps(self.document)
            )
            self.assertNotIn("https_proxy", kwargs["env"])
            return subprocess.CompletedProcess(arguments, self.download_status)
        if arguments[1] == "check":
            kwargs["stderr"].write("private validation diagnostic")
            return subprocess.CompletedProcess(arguments, self.check_status)
        return subprocess.CompletedProcess(arguments, 0, stdout="")

    def active_snapshot(self):
        candidate = self.runtime.prepare()
        self.runtime.publish("current", candidate)
        return candidate

    def configure_local_nodes(self, document, *, subscription=False):
        path = self.root / "nodes.json"
        path.write_text(json.dumps(document))
        path.chmod(0o600)
        self.policy["nodesFile"] = str(path)
        if not subscription:
            self.policy["requestFile"] = None
        self.runtime = module.Runtime(self.policy)
        return path

    def test_only_independent_nodes_are_imported(self):
        self.document.update(
            {"inbounds": [{"type": "tun"}], "dns": {"unknown-new-field": True}}
        )
        self.document["outbounds"] += [
            {"type": "direct", "tag": "direct"},
            {"type": "selector", "tag": "proxy"},
        ]
        self.document["outbounds"][0]["domain_resolver"] = "provider-only-dns"
        config = module.read_json(self.runtime.prepare() / "config.json")
        self.assertEqual(
            [o["type"] for o in config["outbounds"]], ["direct", "urltest", "vless"]
        )
        self.assertEqual(config["outbounds"][-1]["tag"], "node/subscription/node-a")
        self.assertEqual(config["outbounds"][-1]["domain_resolver"], "local-dns")
        self.assertEqual(config["inbounds"][0]["type"], "mixed")

    def test_dependencies_unknown_types_duplicates_and_empty_sources_fail(self):
        invalid = [
            [{"type": "vless", "tag": "x", "detour": "missing"}],
            [{"type": "vless", "tag": "x", "tls": {"certificate_path": "private.pem"}}],
            [{"type": "wireguard", "tag": "x"}],
            [{"type": [], "tag": "x"}],
            [{"type": "vless", "tag": "x"}, {"type": "vless", "tag": "x"}],
            [{"type": "selector", "tag": "proxy"}],
        ]
        for source in ("subscription", "local"):
            for outbounds in invalid:
                with (
                    self.subTest(source=source, outbounds=outbounds),
                    self.assertRaises(module.Failure),
                ):
                    module.import_nodes({"outbounds": outbounds}, source)

    def test_local_nodes_need_no_subscription_and_keep_module_policy(self):
        self.runtime.request.unlink()
        self.document.update(
            {"inbounds": [{"type": "tun"}], "route": {"final": "foreign"}}
        )
        self.document["outbounds"] += [{"type": "selector", "tag": "foreign"}]
        self.document["outbounds"][0]["domain_resolver"] = "provider-only-dns"
        path = self.configure_local_nodes(self.document)
        original = path.read_bytes()
        snapshot = self.runtime.prepare()
        config = module.read_json(snapshot / "config.json")
        self.assertEqual(self.downloads, 0)
        self.assertFalse((snapshot / "download.log").exists())
        self.assertEqual(path.read_bytes(), original)
        self.assertEqual(config["route"]["final"], "proxy")
        self.assertEqual(config["inbounds"][0]["type"], "mixed")
        self.assertEqual(config["outbounds"][-1]["tag"], "node/local/node-a")
        self.assertEqual(config["outbounds"][-1]["domain_resolver"], "local-dns")

    def test_local_and_subscription_nodes_share_a_group_without_tag_collisions(self):
        local = {
            "outbounds": [
                {"type": "trojan", "tag": "node-a", "server": "local.invalid"}
            ]
        }
        self.configure_local_nodes(local, subscription=True)
        config = module.read_json(self.runtime.prepare() / "config.json")
        tags = ["node/local/node-a", "node/subscription/node-a"]
        self.assertEqual(config["outbounds"][1]["outbounds"], tags)
        self.assertEqual([n["tag"] for n in config["outbounds"][2:]], tags)
        self.assertEqual(config["outbounds"][2]["server"], "local.invalid")
        self.assertEqual(self.downloads, 1)

    def test_local_node_reordering_keeps_service_but_content_changes_are_read(self):
        nodes = [
            {"type": "trojan", "tag": tag, "server": "local.invalid"}
            for tag in ("b", "a")
        ]
        path = self.configure_local_nodes({"outbounds": nodes})
        old = self.active_snapshot()
        nodes.reverse()
        path.write_text(json.dumps({"outbounds": nodes}))
        candidate = self.runtime.prepare()
        self.assertEqual(
            (old / "config.json").read_bytes(), (candidate / "config.json").read_bytes()
        )
        with (
            mock.patch.object(self.runtime, "ready", return_value=True),
            mock.patch.object(self.runtime, "restart") as restart,
        ):
            self.runtime.apply(candidate)
        restart.assert_not_called()
        nodes[0]["server"] = "changed.invalid"
        path.write_text(json.dumps({"outbounds": nodes}))
        config = module.read_json(self.runtime.prepare() / "config.json")
        self.assertEqual(config["outbounds"][2]["server"], "changed.invalid")
        self.assertEqual(self.downloads, 0)

    def test_invalid_local_sources_preserve_current_without_partial_publication(self):
        old = self.active_snapshot()
        invalid = [
            '{"outbounds": ["private-password',
            "[]",
            '{"outbounds": []}',
            '{"outbounds": ["private-password"]}',
            '{"outbounds": [{"type": "private-password", "tag": "x"}]}',
            'vless://private-password@example.invalid:443',
            json.dumps(
                {"outbounds": [{"type": "vless", "tag": "x", "detour": "missing"}]}
            ),
        ]
        for content in invalid:
            with self.subTest(content=content):
                path = self.configure_local_nodes(self.document, subscription=True)
                path.write_text(content)
                with self.assertRaises(module.Failure) as failure:
                    self.runtime.prepare()
                self.assertNotIn("private-password", str(failure.exception))
                self.assertEqual(self.runtime.snapshot(), old)
        self.check_status = 1
        self.configure_local_nodes(self.document, subscription=True)
        with self.assertRaises(module.Failure):
            self.runtime.prepare()
        self.assertEqual(self.runtime.snapshot(), old)

    def test_local_source_permissions_links_and_missing_files_preserve_current(self):
        old = self.active_snapshot()
        path = self.configure_local_nodes(self.document)
        path.chmod(0o644)
        with self.assertRaises(module.Failure):
            self.runtime.prepare()
        path.chmod(0o600)
        target = path.rename(self.root / "target.json")
        path.symlink_to(target)
        with self.assertRaises(module.Failure):
            self.runtime.prepare()
        path.unlink()
        with self.assertRaises(FileNotFoundError):
            self.runtime.prepare()
        self.assertEqual(self.runtime.snapshot(), old)
        self.assertEqual(self.downloads, 1)

    def test_node_sources_have_a_bounded_read(self):
        old = self.active_snapshot()
        path = self.configure_local_nodes(self.document)
        with path.open("wb") as stream:
            stream.truncate(module.SOURCE_SIZE_LIMIT + 1)
        with self.assertRaisesRegex(module.Failure, "8 MiB"):
            self.runtime.prepare()
        self.assertEqual(self.runtime.snapshot(), old)
        self.assertEqual(self.downloads, 1)

    def test_no_node_source_fails_before_credentials_or_downloads(self):
        self.policy["requestFile"] = None
        runtime = module.Runtime(self.policy)
        with self.assertRaisesRegex(module.Failure, "nodesFile"):
            runtime.prepare()
        self.assertEqual(self.downloads, 0)
        self.assertFalse(runtime.credentials.exists())

    def test_each_prepare_downloads_but_never_publishes(self):
        old = self.active_snapshot()
        auth = self.runtime.credentials.read_bytes()
        with mock.patch.object(self.runtime, "preflight_port"):
            self.runtime.prepare()
        self.assertEqual(self.downloads, 2)
        self.assertEqual(self.runtime.snapshot(), old)
        self.assertEqual(self.runtime.credentials.read_bytes(), auth)

    def test_download_and_validation_failure_preserve_current(self):
        old = self.active_snapshot()
        for failure in ("download_status", "check_status"):
            with (
                self.subTest(failure=failure),
                mock.patch.object(self.runtime, "preflight_port"),
            ):
                setattr(self, failure, 1)
                with self.assertRaises(module.Failure):
                    self.runtime.prepare()
                self.assertEqual(self.runtime.snapshot(), old)
                setattr(self, failure, 0)

    def test_secret_permissions_and_occupied_port_fail(self):
        self.runtime.request.chmod(0o644)
        with self.assertRaises(module.Failure):
            self.runtime.prepare()
        self.assertEqual(self.downloads, 0)
        self.runtime.request.chmod(0o600)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", self.policy["listenPort"]))
            listener.listen()
            with self.assertRaisesRegex(module.Failure, "listenPort"):
                self.runtime.prepare()
        self.assertEqual(self.downloads, 0)

    def test_preflight_accepts_a_reusable_port_after_a_closed_connection(self):
        with socket.socket() as listener:
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            listener.bind(("127.0.0.1", 0))
            listener.listen()
            port = listener.getsockname()[1]
            with socket.create_connection(("127.0.0.1", port)) as client:
                connection, _ = listener.accept()
                connection.close()
                self.assertEqual(client.recv(1), b"")
        self.runtime.preflight_port(port)

    def test_occupied_port_requires_matching_current_port_and_authentication(self):
        self.active_snapshot()
        port = self.policy["listenPort"]
        with (
            socket.socket() as listener,
            mock.patch.object(self.runtime, "ready") as ready,
        ):
            listener.bind(("127.0.0.1", port))
            listener.listen()
            ready.return_value = True
            self.runtime.preflight_port(port)
            ready.return_value = False
            with self.assertRaises(module.Failure):
                self.runtime.preflight_port(port)
            with socket.socket() as foreign:
                foreign.bind(("127.0.0.1", 0))
                foreign.listen()
                ready.return_value = True
                with self.assertRaises(module.Failure):
                    self.runtime.preflight_port(foreign.getsockname()[1])

    def test_ready_requires_active_service_and_valid_socks_authentication(self):
        snapshot = self.active_snapshot()
        with mock.patch.object(module.socket, "create_connection") as connect:
            connection = connect.return_value.__enter__.return_value
            for active, response, expected in (
                (False, [], False),
                (True, [b"\x05\x00"], False),
                (True, [b"\x05\x02", b"\x01\x01"], False),
                (True, [b"\x05\x02", b"\x01\x00"], True),
            ):
                with self.subTest(active=active, response=response):
                    connection.recv.side_effect = response
                    result = subprocess.CompletedProcess([], 0 if active else 3)
                    with mock.patch.object(
                        self.runtime, "systemctl", return_value=result
                    ):
                        self.assertEqual(self.runtime.ready(snapshot), expected)
                    if not active:
                        connect.assert_not_called()

    def test_unchanged_snapshot_keeps_service(self):
        self.active_snapshot()
        candidate = self.runtime.prepare()
        with (
            mock.patch.object(self.runtime, "ready", return_value=True),
            mock.patch.object(self.runtime, "restart") as restart,
        ):
            self.runtime.apply(candidate)
        restart.assert_not_called()
        self.assertFalse(candidate.exists())

    def test_package_change_restarts_even_with_unchanged_configuration(self):
        old = self.active_snapshot()
        self.policy["packageId"] = "updated-package"
        candidate = self.runtime.prepare()
        self.assertEqual(
            (old / "config.json").read_bytes(), (candidate / "config.json").read_bytes()
        )
        with (
            mock.patch.object(self.runtime, "ready", return_value=True),
            mock.patch.object(self.runtime, "restart") as restart,
        ):
            self.runtime.apply(candidate)
        restart.assert_called_once_with(candidate)

    def test_startup_failure_restores_configuration_and_reports_current_package(self):
        old = self.active_snapshot()
        self.policy["singBox"] = "/test/new-sing-box"
        self.policy["packageId"] = "updated-package"
        candidate = self.runtime.prepare()

        def restart(snapshot):
            if snapshot == candidate:
                raise module.Failure("injected startup failure")

        with (
            mock.patch.object(
                self.runtime, "restart", side_effect=restart
            ) as restart_call,
            self.assertRaisesRegex(
                module.Failure,
                "previous configuration is running with the current sing-box package",
            ),
        ):
            self.runtime.apply(candidate)
        self.assertEqual(self.runtime.snapshot(), old)
        self.assertEqual(
            restart_call.call_args_list, [mock.call(candidate), mock.call(old)]
        )
        self.assertNotIn("singBox", module.read_json(old / "runtime.json"))
        with mock.patch.object(
            module.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)
        ) as check:
            self.runtime.check_config(old)
        self.assertEqual(check.call_args.args[0][0], "/test/new-sing-box")

    def test_recovery_failure_is_explicit(self):
        old = self.active_snapshot()
        self.policy["singBox"] = "/test/new-sing-box"
        candidate = self.runtime.prepare()
        with (
            mock.patch.object(
                self.runtime, "restart", side_effect=module.Failure("failed")
            ),
            self.assertRaisesRegex(
                module.Failure, "restore the previous Home Manager generation"
            ),
        ):
            self.runtime.apply(candidate)
        self.assertEqual(self.runtime.snapshot(), old)

    def test_initial_startup_failure_removes_current(self):
        candidate = self.runtime.prepare()
        with (
            mock.patch.object(
                self.runtime, "restart", side_effect=module.Failure("failed")
            ),
            self.assertRaisesRegex(module.Failure, "no previous configuration exists"),
        ):
            self.runtime.apply(candidate)
        self.assertIsNone(self.runtime.snapshot())

    def test_wrapper_passes_credentials_only_in_child_environment(self):
        snapshot = self.active_snapshot()
        command = ["program", "argument with spaces"]
        with (
            mock.patch.object(self.runtime, "ready", return_value=True),
            mock.patch.object(module.os, "execvpe") as execute,
        ):
            self.runtime.with_proxy(command)
        executable, arguments, environment = execute.call_args.args
        auth = module.read_json(snapshot / "config.json")["inbounds"][0]["users"][0]
        self.assertEqual((executable, arguments), (command[0], command))
        self.assertNotIn(auth["password"], " ".join(arguments))
        self.assertIn(auth["password"], environment["http_proxy"])
        self.assertTrue(environment["all_proxy"].startswith("socks5h://"))
        self.assertEqual(environment["no_proxy"], environment["NO_PROXY"])
        self.assertIn("internal", environment["no_proxy"])

    def test_wrapper_does_not_start_command_without_managed_service(self):
        self.active_snapshot()
        with (
            mock.patch.object(self.runtime, "ready", return_value=False),
            mock.patch.object(module.os, "execvpe") as execute,
            self.assertRaises(module.Failure),
        ):
            self.runtime.with_proxy(["program"])
        execute.assert_not_called()

    def test_snapshot_and_credentials_permissions(self):
        snapshot = self.runtime.prepare()
        for path in (self.runtime.state, self.runtime.snapshots, snapshot):
            self.assertEqual(path.stat().st_mode & 0o777, 0o700)
        for path in (
            self.runtime.credentials,
            snapshot / "config.json",
            snapshot / "runtime.json",
        ):
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_restart_does_not_reset_an_unloaded_inactive_unit(self):
        snapshot = self.active_snapshot()
        response = subprocess.CompletedProcess([], 0, stdout="inactive\n")
        with (
            mock.patch.object(
                self.runtime, "systemctl", return_value=response
            ) as control,
            mock.patch.object(self.runtime, "ready", return_value=True),
        ):
            self.runtime.restart(snapshot)
        self.assertNotIn(
            mock.call("reset-failed", "sing-box.service"), control.call_args_list
        )
        self.assertIn(mock.call("restart", "sing-box.service"), control.call_args_list)

    def test_private_secrets_inside_git_are_rejected(self):
        (self.root / ".git").mkdir()
        with self.assertRaisesRegex(module.Failure, "outside Git"):
            self.runtime.prepare()
        self.assertEqual(self.downloads, 0)

    def test_missing_credentials_in_git_are_rejected_before_creation(self):
        repository = self.root / "repository"
        (repository / ".git").mkdir(parents=True)
        credentials = repository / "secrets/auth.json"
        self.policy["credentialsFile"] = str(credentials)
        runtime = module.Runtime(self.policy)
        with self.assertRaisesRegex(module.Failure, "outside Git"):
            runtime.prepare()
        self.assertFalse(credentials.parent.exists())

    def test_private_runtime_state_cannot_be_initialized_in_git(self):
        repository = self.root / "repository"
        (repository / ".git").mkdir(parents=True)
        self.policy["credentialsFile"] = str(self.root / "external-auth.json")
        for state in (repository, repository / "state"):
            with self.subTest(state=state):
                self.policy["stateDirectory"] = str(state)
                runtime = module.Runtime(self.policy)
                with self.assertRaisesRegex(module.Failure, "outside Git"):
                    runtime.initialize()
                self.assertEqual(list(repository.iterdir()), [repository / ".git"])

    def test_symlinked_home_ancestor_keeps_snapshot_references_valid(self):
        alias = self.root / "home-alias"
        alias.symlink_to(self.root, target_is_directory=True)
        self.policy["stateDirectory"] = str(alias / "state")
        runtime = module.Runtime(self.policy)
        candidate = runtime.prepare()
        runtime.publish("current", candidate)
        self.assertEqual(runtime.snapshot(), candidate)


class LingerTests(unittest.TestCase):
    def exercise(self, mode):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            loginctl = root / "loginctl"
            loginctl.write_text(
                "#!/usr/bin/env python3\n"
                "import os,sys\nfrom pathlib import Path\n"
                "root=Path(os.environ['LINGER_FIXTURE']); mode=os.environ['LINGER_CASE']\n"
                "if 'enable-linger' in sys.argv:\n"
                " (root/'enabled').touch(); sys.exit(1 if mode=='denied' else 0)\n"
                "count=root/'queries'; n=int(count.read_text())+1 if count.exists() else 1; count.write_text(str(n))\n"
                "if mode=='query-error' or (mode=='verify-error' and n>1): sys.exit(1)\n"
                "if mode=='unexpected': print('unknown')\n"
                "elif mode=='empty': print('')\n"
                "elif mode in ('yes','manager-error') or (n>1 and mode!='no-effect'): print('yes')\n"
                "else: print('no')\n"
            )
            systemctl = root / "systemctl"
            systemctl.write_text('#!/bin/sh\n[ "$LINGER_CASE" != manager-error ]\n')
            loginctl.chmod(0o700)
            systemctl.chmod(0o700)
            environment = dict(os.environ)
            environment.update(
                PATH=str(root) + os.pathsep + environment["PATH"],
                LINGER_CASE=mode,
                LINGER_FIXTURE=str(root),
            )
            helper = (
                Path(__file__).resolve().parents[2] / "profiles/home/ensure-linger.sh"
            )
            result = subprocess.run(
                ["bash", "-euo", "pipefail", str(helper)],
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            return (
                result,
                (root / "enabled").exists(),
                int((root / "queries").read_text()),
            )

    def test_enabled_state_is_unchanged(self):
        result, enabled, queries = self.exercise("yes")
        self.assertEqual(result.returncode, 0)
        self.assertFalse(enabled)
        self.assertEqual(queries, 1)

    def test_disabled_state_is_enabled_and_verified(self):
        result, enabled, queries = self.exercise("no")
        self.assertEqual(result.returncode, 0)
        self.assertTrue(enabled)
        self.assertEqual(queries, 2)

    def test_every_linger_and_user_manager_failure_is_explicit(self):
        for mode in (
            "query-error",
            "denied",
            "verify-error",
            "no-effect",
            "unexpected",
            "empty",
            "manager-error",
        ):
            with self.subTest(mode=mode):
                result, _, _ = self.exercise(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(result.stderr.strip())


if __name__ == "__main__":
    os.umask(0o077)
    unittest.main()
