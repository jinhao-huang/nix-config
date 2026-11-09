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

## Hermes over HTTPS

The `desktop` host's [`hermesServe`](../../hosts/darwin.nix) exposes the
[Hermes Dashboard](../hermes/README.md) through tailnet HTTPS. Before switching:

- In Proton Pass, create a Login item matching `passwordRef`. Generate a random
  password of 32 letters and digits, and use the managed macOS username for login.
- Enable [MagicDNS and HTTPS certificates](https://tailscale.com/docs/how-to/set-up-https-certificates)
  in the tailnet. Confirm that `sudo tailscale status --json` reports the
  configured hostname in `Self.DNSName` (with a trailing dot).
- [Allow access](https://tailscale.com/docs/reference/examples/grants) to TCP
  `443` on that node for your own identity. Remove grants that also allow direct
  access to the Dashboard's backend port. Preserve the existing SSH access.

After [switching](../../README.md#build-and-switch), keep the macOS user logged
in so its Hermes LaunchAgent can run. Serve waits for the password-protected
Dashboard before publishing the endpoint. Open `/chat` on the node's HTTPS
URL from a device on the tailnet, sign in, and send a message. If Serve is
not available, check `sudo tailscale serve status` and `/var/log/tailscale-serve.log`.

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
Nix locks native preferences unless Serve is enabled. Serve needs write access
to register its foreground mapping, which launchd manages. Use the enrollment
flow above. Activating a configuration change reloads the daemon and can
interrupt connections. Explicitly set `false` or an empty list to clear a
preference; omitting a field can preserve its previous value.

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
