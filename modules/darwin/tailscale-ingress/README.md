# Tailscale ingress on macOS

Runs a userspace Tailscale daemon for inbound access while Surge handles egress.
System routing, DNS, and the shared Surge profile remain unchanged. The custom
module avoids the DNS resolver file added by nix-darwin's `services.tailscale`.
Use this as the only host Tailscale daemon; Surge's embedded client is separate.

## Enroll and connect

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
`sudo tailscale ip -4`, rather than Surge's node. Subsequent starts reuse the
identity. If authentication stalls, inspect the logs below.

Ordinary TCP/UDP traffic is forwarded to `127.0.0.1` on the same port; services
must listen there and generally see a local source address. Tailnet rules should
allow only intended peers, since reachable localhost services are exposed too.
Tailscale SSH is enabled and requires both TCP 22 access and an SSH policy for
the local account. It uses its own server and authentication, independent of
macOS Remote Login and `authorized_keys`.

## Maintain

Edit preferences in [default.nix](default.nix). Nix generates a locked native
configuration, so CLI preference changes and `up`/`login` are not the enrollment
workflow. Activating a configuration change reloads the daemon and can interrupt
connections. Explicitly set `false` or an empty list to clear a preference;
omitting a field can preserve its previous value.

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
