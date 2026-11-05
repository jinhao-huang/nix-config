# Tailscale ingress on macOS

English | [简体中文](README.zh-CN.md)

Runs a userspace Tailscale daemon for inbound access while Surge handles egress.
System routing, DNS, and the shared Surge profile remain unchanged. The custom
module avoids the DNS resolver file added by nix-darwin's `services.tailscale`.
Use this as the only host Tailscale daemon; Surge's embedded client is separate.

## Enroll and connect

After [macOS first activation](../../docs/darwin.md#first-activation), enroll
the installed daemon once. Later starts reuse its saved identity.

`enabled = true` requests a running connection but does not initiate browser
authentication while logged out. For first enrollment, trigger authentication
without modifying locked preferences:

```sh
sudo tailscale debug localapi POST login-interactive
sudo tailscale status --json
```

The first command normally returns no response body. Authentication is
asynchronous; retry status after a few seconds if `AuthURL` is still empty.
Open that URL in a browser and approve the device, then confirm
`BackendState` becomes `Running`. Connect to this node's address from
`sudo tailscale ip -4`, rather than Surge's node. If authentication stalls,
inspect the logs below.

Ordinary TCP/UDP traffic is forwarded to `127.0.0.1` on the same port; services
must listen there and generally see a local source address. Tailnet rules should
allow only intended peers, since reachable localhost services are exposed too.
Both Macs disable built-in Tailscale SSH and forward tailnet TCP 22 to
[macOS Remote Login](../../profiles/system/darwin/remote-login/README.md), using
the configured public keys. Existing tailnet hostnames still work outside the
LAN; tailnet rules must allow TCP 22.

## Zed remote development

Built-in SSH is disabled because its macOS
[exit-status bug](https://github.com/tailscale/tailscale/issues/18256) can cause
Zed to skip remote-server installation. After an upstream fix, set
`modules.tailscale.ssh.enable = true` in the
[Darwin profile](../../profiles/system/darwin/default.nix) and allow the local
account in the tailnet SSH policy. Rebuild and switch, then verify with Tailscale
SSH enabled that `ssh -o ControlPath=none -T user@host 'exit 37'` returns exit
status `37` and Zed installs a missing remote server.

## Maintain

Both platform modules use `modules.tailscale.package` for the daemon and CLI.
The flake selects Tailscale from `nixpkgs-unstable`. Update that input for new
Tailscale releases and Go security fixes. Verify both versions with the selected
package's `tailscale version` before activating. Check releases weekly and
prioritize applicable security bulletins.
Client update checks and auto-apply are disabled; Nix manages installation.
A new build takes effect only after activation reloads the daemon.

Configure ingress and SSH in the
[Darwin profile](../../profiles/system/darwin/default.nix).
Nix generates a locked native configuration, so CLI preference changes and
`up`/`login` are not the enrollment workflow. Activating a configuration change
reloads the daemon and can interrupt connections. Explicitly set `false` or an
empty list to clear a preference; omitting a field can preserve its previous value.

When changing SSH servers, verify public-key access first and any new host-key
fingerprint through a trusted connection before updating `known_hosts`.

The [native configuration schema](https://tailscale.com/docs/reference/tailscaled/tailscaled-config-file)
is still alpha, and `debug localapi` is not a stable CLI interface; check both
when updating Tailscale. Node identity and
runtime state live in `/var/lib/tailscale-ingress`, survive disabling the module,
and are not restored by Nix rollback. Keep credentials and state outside Git
and the Nix store.

For service status and logs:

```sh
sudo launchctl print system/com.tailscale.tailscaled
sudo tailscale debug daemon-logs
```
