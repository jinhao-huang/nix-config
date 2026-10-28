# Linux setup and services

English | [简体中文](linux.zh-CN.md)

Run from this checkout as the Linux account managed by Home Manager, using the
installed Nix or Lix without sudo. Home Manager manages the user environment;
the host OS and Nix daemon remain administrator-owned. Configure hosts in
[the inventory](../hosts/linux.nix); see the [option reference](configuration.md).

## Before first activation

Nix or Lix and Git must already be available. Check the selected inventory
entry's `username`, `homeDirectory`, and `authorizedKeyFiles`. Move required
shell initialization into the managed shell modules. Keep an existing SSH
session open until a new connection has been tested after activation.

Prepare every enabled feature before switching:

- sing-box: prepare the [input files below](#sing-box-inputs), or set
  `singBox.enable = false` in the inventory.
- Hermes: prepare the [model settings and secret file](../modules/hermes/README.md).
  If no model is ready, set `hermes.enable = false` for this activation. Enabling
  Telegram also requires a bot token and allowed user IDs before activation.
- GHCR: set `dockerGhcr` in the inventory if needed. Authentication happens
  after activation; the host must provide Docker and Compose for image pulls.
- Harness and Tailscale Serve: check `deepseekHarness.publicHost` and HTTPS
  settings in the inventory. Tailnet enrollment happens after activation.

Activation requires a working systemd user manager and user linger. It attempts
to enable linger; ask the administrator to enable it if permission is denied.
The host administrator also maintains the Nix daemon and Docker networking.

### sing-box inputs

Create `~/.config/sing-box/subscription.curl` outside Git with directory mode
`0700` and file mode `0600`, requesting native sing-box JSON over HTTPS:

```text
url = "https://subscription.example/private-token?format=json"
```

Alternatively, set `singBox.nodesFile` to a private JSON file (mode `0600`) containing
`{"outbounds": [...]}` and `singBox.subscription.requestFile = null`.
Both sources can be combined; share links are unsupported. Configure ports,
lab-network bypasses, and input constraints using the
[option reference](configuration.md#modulessing-boxnodesfile).

## First activation

After the preparation above, activate once from the repository root.
Replace `example-host` with the target inventory key:

```sh
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
deploy_host=example-host
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host" -b before-hm
```

`switch` builds before activating. `-b before-hm` backs up conflicting files;
their behavior is not retained. A linger failure aborts the switch. Add `-n`
to preview activation, which may still build or download packages and initialize
the local inventory. Open a new shell after activation to load managed commands
and environment variables. Continue with the checks and authentication below;
do not repeat activation for each feature.

For later configuration or secret-file changes, use the routine
[build and switch flow](../README.md#build-and-switch). Diagnose Nix connection
errors with `nix store ping`.

## Shell and SSH

Home Manager does not change the account's login shell; use `zsh` or tmux
explicitly when needed. For Git signing, connect with `ssh -A <ssh-host>` using
the target's SSH alias and forward an agent containing the signing key.
Put local SSH overrides in `~/.ssh/config.local`.

The Linux profile sets `XDG_RUNTIME_DIR` to `/run/user/<UID>` when it is unset
or empty, preserving an existing value. Bash login, interactive, and SSH command
sessions load Home Manager's session variables; Zsh loads them from `.zshenv`.
This lets Tailscale SSH sessions use `systemctl --user`, `tailscale-user`, and
`with-proxy` directly. Reconnect after activation to load the new environment.
The host's systemd-logind and linger manage the runtime directory and user
manager; shell startup does not create or start them.

Home Manager activation combines the host's `authorizedKeyFiles` into a
user-owned regular `~/.ssh/authorized_keys` file with mode `0600`, inside a
`0700` `.ssh` directory. Each activation atomically replaces the file, so edit
the host's key list rather than the installed file. A custom activation step
is required because `home.file` creates Nix store symlinks, and a group-writable
store directory fails OpenSSH's `StrictModes` checks. The step respects dry-run
and preserves the existing file if copying fails.

The system SSH daemon must read that path. Keep the current session open and
test a new ordinary SSH connection after switching. Tailscale SSH stays enabled
with its own authorization policy.

## Tailscale

Enroll the userspace daemon once after first activation; later activations reuse
its saved identity:

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

If `AuthURL` is empty, retry status after a few seconds. Open the URL to approve
the device; `tailscale-user ip -4` gives its address.
For shared servers, use a dedicated tag, allow the required SSH port and managed
Linux account, and remove access to other devices in the
[tailnet policy](https://tailscale.com/docs/reference/syntax/grants).
Disabling the outbound proxy alone does not restrict access.
Logs: `journalctl --user -u tailscaled`.

## sing-box

If enabled, activation starts the proxy using the inputs prepared above.
Run `with-proxy git fetch` for one command or `with-proxy bash` for a shell.
The wrapper requires a running proxy; start a new shell after changing its port
or credentials. Tailnet-only destinations need a separate userspace Tailscale exit.

Failed input validation preserves the running proxy. If startup recovery fails,
restore the previous Home Manager generation and saved private configuration;
binaries are not rolled back automatically. Logs: `journalctl --user -u sing-box`;
private diagnostics: `~/.local/state/sing-box/snapshots/`.

## Private container images

If GHCR integration is enabled, complete the
[GitHub CLI authentication](../modules/docker-ghcr/README.md#authenticate)
before pulling private images. The Docker daemon and Compose remain host-owned.

## Hermes

If Hermes was enabled and prepared before activation, check the gateway and
open the CLI/TUI. Skip the service checks for CLI-only use. With sing-box
enabled, use `with-proxy` as below; otherwise run `hermes --tui` directly.
User linger keeps the gateway running after logout:

```sh
systemctl --user status hermes-agent
journalctl --user -u hermes-agent -n 50 --no-pager
with-proxy hermes --tui
```

Verify a real model reply and, if Telegram is enabled, a message exchange.
Use `systemctl --user` for
gateway lifecycle commands. With sing-box enabled, the gateway starts through
`with-proxy` and restarts with it.
Switch also restarts active Hermes services after settings or secret-file changes.
See [state ownership and removal](../modules/hermes/README.md#data-paths-and-removal)
before disabling or deleting data.

For enabling Hermes later, upgrades, and state backups, use the
[Hermes maintenance guide](../modules/hermes/README.md#maintenance).

## DeepSeek Harness

Enable MagicDNS and tailnet HTTPS certificates, and allow intended peers to
reach the configured Serve HTTPS port (443 by default). Connect to Tailscale,
then open the latest complete launch URL, including its private token, from:

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

Keep the journal private. Bookmark the clean URL after authentication; reopen
the launch URL if authentication expires. Check ingress with
`tailscale-user serve status` and
`systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve`.
