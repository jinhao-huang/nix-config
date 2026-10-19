# Configuration reference

This reference covers Linux host fields and every sing-box, DeepSeek Harness,
and Tailscale option provided by this repository. Option entries are generated
from their Nix declarations, including types, defaults, examples, and source
links. Defaults describe the modules; profiles and host inventory supply the
values used on a particular machine. An option without a default is required
when its feature is enabled.

## Linux host fields

Edit [hosts/linux.nix](../hosts/linux.nix). Each top-level attribute names a
`homeConfigurations` entry. Supply these fields for each host:

| Host field | Purpose or module option |
| --- | --- |
| `system` | Package architecture, such as `x86_64-linux` or `aarch64-linux`. |
| `username` | `home.username`. |
| `homeDirectory` | Absolute `home.homeDirectory`. |
| `tailscaleHostname` | `modules.deepseek-harness.service.publicHost`, using the node's actual MagicDNS hostname. |
| `deepseekHarness.port` | `modules.deepseek-harness.service.port`. |
| `deepseekHarness.proxyPort` | `modules.deepseek-harness.service.proxyPort`. |
| `deepseekHarness.httpsPort` | `modules.tailscale.serve.httpsPort`. The Harness public port follows it. |
| `singBox` | Attribute set passed to `modules.sing-box`; supply `listenPort` and any optional settings below. |

For example, a host can include:

```nix
deepseekHarness = {
  port = 3080;
  proxyPort = 3081;
  httpsPort = 8443;
};
singBox = {
  listenPort = 21009;
  routing.directDomainSuffixes = [ "internal" ];
};
```

Every `modules.sing-box.<option>` below is available as `singBox.<option>` in a
host entry. For example, `modules.sing-box.routing.directDomains` becomes
`singBox.routing.directDomains`. Omitted settings use module defaults unless
a profile supplies a value. The Linux profile enables sing-box by default;
set `singBox.enable = false` to disable it for one host.
Subscription URLs, headers, and proxy credentials remain in private runtime
files; the inventory may contain their paths.

The [Linux profile](../profiles/home/linux.nix) enables the features and connects
Serve to the private Harness proxy. It derives the public URL and trusted
authority from the hostname and HTTPS port. Port 443 is omitted from the URL;
other HTTPS ports are included. The sing-box, Harness backend, and Harness
proxy must use distinct loopback ports. Serve's HTTPS port belongs to the
tailnet listener and is not part of that loopback conflict check.

## Platform and configuration scope

- sing-box runs as a Linux systemd user service.
- Harness policy applies on macOS and Linux. macOS uses the official desktop
  application; the Web backend and private proxy are Linux user services.
- Tailscale's `enable`, `incoming.enable`, and `ssh.enable` options apply to
  macOS and Linux. `outboundProxy` and `serve` options apply to Linux.

Edit shared enable switches and service wiring in the platform profiles.
Package selection belongs in [flake.nix](../flake.nix). On macOS, Tailscale is
configured in the [system profile](../profiles/system/darwin/default.nix), and
Harness policy in the [Home Manager profile](../profiles/home/darwin.nix).

## Regenerate and check

From the repository root:

```sh
nix run .#update-configuration-reference
```

Edit option descriptions and examples in the linked Nix declarations, and edit
this introduction in `docs/configuration-intro.md`. The generated
`docs/configuration.md` is checked against the current declarations by
`checks.<system>.configuration-reference`. Build the `configuration-reference`
package to obtain both `configuration.md` and machine-readable `options.json`.
Generation does not read secrets or activate services.
