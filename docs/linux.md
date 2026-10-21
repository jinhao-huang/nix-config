# Linux setup and services

[hosts/linux.nix](../hosts/linux.nix) declares accounts, architectures, ports,
and routing. On `iscas-r750xa`, run from this checkout as `huangjh`, using the
existing Lix installation without sudo. Home Manager manages only the user
environment.

## First activation

Before switching, preserve required lab initialization from existing shell
startup files in the shell modules. Prepare the [sing-box inputs](#sing-box)
first, or disable it with `singBox.enable = false` in the host inventory.

```sh
nix run .#deploy -- switch iscas-r750xa -b before-hm
```

`-b before-hm` backs up conflicting files with a `.before-hm` suffix; their
startup behavior is not retained. Activation also requires user linger and
attempts to enable it; host policy denying this aborts activation.

To preview activation, add `-n`. It skips activation changes but can still build
or download packages and initialize the local inventory. For a build without
activation, use `nix run .#deploy -- build iscas-r750xa`. Check store or daemon
connection errors with `nix store ping`.

## Shell and SSH

Git uses the same SSH signing key on both platforms. Connect with
`ssh -A iscas-r750xa` when forwarding an agent containing that key; Linux keeps
the incoming `SSH_AUTH_SOCK`. `modules.ssh.includeHosts` selects the SSH host
inventory; put local SSH overrides in `~/.ssh/config.local`.

The login shell stays Bash; run `zsh` explicitly or use tmux. Keep project
language toolchains and CUDA dependencies in project environments.

## Tailscale

The [Linux profile](../profiles/home/linux.nix) enables a userspace systemd user
daemon, incoming access, and Tailscale SSH, with the outbound proxy disabled.
After activation, enroll once:

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

Open `AuthURL` to approve the device; `tailscale-user ip -4` gives its address.
For shared servers, assign a dedicated tag in Tailscale Console, allow your
account to reach TCP 22, and add an SSH rule for `huangjh`. Remove rules granting
the server access to other devices; disabling the proxy alone does not enforce
this restriction. See [grants](https://tailscale.com/docs/reference/syntax/grants).
Logs: `journalctl --user -u tailscaled`.

## sing-box

Create private `~/.config/sing-box/subscription.curl` outside Git, with directory
mode `0700` and file mode `0600`. Use native sing-box JSON over HTTPS:

```text
url = "https://subscription.example/private-token?format=json"
```

For local nodes, set `singBox.nodesFile` in the host inventory to a private JSON
file containing `{"outbounds": [...]}` with the same permissions. Set
`singBox.subscription.requestFile = null` to skip downloads, or combine both
sources in one automatic selection group. Only independent native sing-box nodes
are imported; share links are unsupported. See the
[option reference](configuration.md#modulessing-boxnodesfile) for constraints.

Each switch repairs permissions in sing-box's XDG config and state directories
for user-owned directories and configured regular files; read-only inputs stay
read-only. Links and wrong owners are rejected. Other locations require correct
permissions in advance.

The authenticated mixed listener binds loopback; an occupied port aborts
activation. Configure the port and routing in the host's `singBox` entry. Local
destinations and pinned China domains go direct; other requests use proxy nodes.
Add laboratory domains and directly reachable campus networks before use.
Tailnet-only targets require a separate userspace Tailscale exit.

For one command or a temporary proxy-enabled shell:

```sh
with-proxy git fetch
with-proxy bash
```

Login sessions receive a small `no_proxy`/`NO_PROXY` list. The wrapper reads
credentials and the active proxy's bypass list into the child environment and
refuses commands when the managed proxy is unavailable. Start a new
proxy-enabled shell after changing its port or credentials.

Each switch validates a private configuration and restarts only when needed.
Input or validation failure preserves the running proxy. Startup failure aborts
the switch and attempts recovery with the previous configuration and current
sing-box package. If recovery fails, restore the previous Home Manager generation
and its saved private configuration; binaries are not rolled back automatically.
Credentials are generated once in `~/.local/state/sing-box/auth.json` (mode
`0600`); Nix evaluation never reads secrets or puts them in the store.

Logs: `journalctl --user -u sing-box`. Private download and validation diagnostics
remain under `~/.local/state/sing-box/snapshots/`.

## DeepSeek Harness

The Web backend, private cookie proxy, and Tailscale Serve run as systemd user
services. Connect to Tailscale, then open the latest complete HTTPS launch URL,
including `?token=...`, from:

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

The URL contains a private token; keep the journal private. Bookmark the clean
URL after authentication; its cookie lasts 30 days by default. For
`dsh web authentication required`, reopen the latest complete launch URL.

Set the host's three Harness ports in [the inventory](../hosts/linux.nix);
proxy targets and the launch URL follow automatically. HTTPS requires MagicDNS,
tailnet HTTPS certificates, and an access rule allowing intended peers to the
configured HTTPS port (443 by default). The loopback proxy adds secure cookies;
Funnel is disabled.

Check ingress with `tailscale-user serve status` and
`systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve`.
For routine rebuilds and input updates, see the [README](../README.md).
