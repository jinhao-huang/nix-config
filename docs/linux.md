# Linux setup and services

English | [简体中文](linux.zh-CN.md)

On `iscas-r750xa`, run from this checkout as `huangjh`, using the existing Lix
installation without sudo. Home Manager manages the user environment; the host
OS and Nix daemon remain administrator-owned. Configure hosts in
[the inventory](../hosts/linux.nix); see the [option reference](configuration.md).

## First activation

Move required lab initialization into the managed shell modules, review
`authorizedKeyFiles`, and prepare the [sing-box inputs](#sing-box) before switching.
To skip sing-box, set `singBox.enable = false` in the host inventory.

```sh
nix run .#deploy -- switch iscas-r750xa -b before-hm
```

`-b before-hm` backs up conflicting files; their behavior is not retained.
Activation requires user linger and attempts to enable it; denial aborts the
switch. Add `-n` to preview activation, which may still build or download
packages and initialize the local inventory. See the [README](../README.md)
for builds and updates; diagnose Nix connection errors with `nix store ping`.

## Shell and SSH

The login shell stays Bash; use `zsh` or tmux explicitly. For Git signing,
connect with `ssh -A iscas-r750xa` and forward an agent containing the signing
key. Put local SSH overrides in `~/.ssh/config.local`.

Home Manager generates `~/.ssh/authorized_keys` from the host's
`authorizedKeyFiles` list; the system SSH daemon must read that path. Keep the
current session open and test a new ordinary SSH connection after switching.
Tailscale SSH stays enabled with its own authorization policy.

## Tailscale

Enroll the userspace daemon after activation:

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

Open `AuthURL` to approve the device; `tailscale-user ip -4` gives its address.
For shared servers, use a dedicated tag, allow inbound TCP 22 and SSH as
`huangjh`, and remove access to other devices in the
[tailnet policy](https://tailscale.com/docs/reference/syntax/grants).
Disabling the outbound proxy alone does not restrict access.
Logs: `journalctl --user -u tailscaled`.

## sing-box

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

Run `with-proxy git fetch` for one command or `with-proxy bash` for a shell.
The wrapper requires a running proxy; start a new shell after changing its port
or credentials. Tailnet-only destinations need a separate userspace Tailscale exit.

Failed input validation preserves the running proxy. If startup recovery fails,
restore the previous Home Manager generation and saved private configuration;
binaries are not rolled back automatically. Logs: `journalctl --user -u sing-box`;
private diagnostics: `~/.local/state/sing-box/snapshots/`.

## Hermes

Complete the [host and secret configuration](../modules/hermes/README.md), then
[switch](../README.md#build-and-switch) and open a new shell. User linger keeps
the gateway running after logout; open the CLI/TUI when needed:

```sh
systemctl --user status hermes-agent
journalctl --user -u hermes-agent -n 50 --no-pager
with-proxy hermes --tui
```

Verify a real model reply and Telegram exchange. Use `systemctl --user` for
gateway lifecycle commands. With sing-box enabled, the gateway starts through
`with-proxy` and restarts with it; run `hermes` directly when no proxy is needed.
Switch also restarts active Hermes services after settings or secret-file changes.
See [state ownership and removal](../modules/hermes/README.md#data-paths-and-removal)
before disabling or deleting data.

Upgrade the `hermes-agent` flake input and switch; avoid `hermes update`. Back up
`~/.hermes` first: Home Manager rollback does not restore application state.
`hermes --version` may show `v0.0.0`; identify the build by its printed commit and
`flake.lock`. Nix is an upstream
[Tier 2 platform](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support/).

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
