# Configuration reference

English | [简体中文](configuration.zh-CN.md)

This reference covers host inventory, Pi startup defaults, and every sing-box,
DeepSeek Harness, GHCR authentication, and Tailscale option provided by this
repository. Module option entries are generated from Nix declarations, including types, defaults, examples,
and source links. Defaults describe the modules; profiles and host
inventory supply the values used on a particular machine. An option without a
default is required when its feature is enabled.

## Pi startup defaults

Set `pi.model = { provider = "provider-id"; id = "model-id"; };` and
`pi.thinkingLevel` in [hosts/darwin.nix](../hosts/darwin.nix) or
[hosts/linux.nix](../hosts/linux.nix). Omitted values use Pi defaults; see
[the schema](../modules/pi/startup-defaults-type.nix) for accepted values.

The deployment command creates Git-ignored `hosts/inventory.local.nix` if absent,
preserves existing files, and loads it on every build and switch. Pi overrides
use `{ laptop.pi.thinkingLevel = "high"; }`.
Omitted fields inherit; `null` clears a default, and `model` replaces the provider
and ID together. Rebuild and switch to apply changes; Pi's global settings remain
read-only. Keep credentials out of both inventories: ignored overrides also
enter the Nix store.

Both platform inventories may contain `hermes` overrides; see
[Hermes configuration](../modules/hermes/README.md#local-overrides). Other override
fields are rejected.

Direct Nix or rebuild commands use tracked defaults unless passed
`--override-input host-local "path:$PWD/hosts/inventory.local.nix"`.

## Darwin host fields

Edit [hosts/darwin.nix](../hosts/darwin.nix). Each top-level attribute names a
`darwinConfigurations` entry. Supply these fields for each host:

| Host field | Purpose or module option |
| --- | --- |
| `system` | Package architecture, such as `aarch64-darwin`. |
| `username` | Primary user account managed by nix-darwin and Home Manager. |
| `homeDirectory` | Absolute home directory for the primary user. |
| `authorizedKeyFiles` | Public key paths passed to nix-darwin's `users.users.<name>.openssh.authorizedKeys.keyFiles`. |
| `homebrew.casks` | Machine-specific casks added to the shared application list in the [Homebrew profile](../profiles/system/darwin/homebrew.nix); use `[]` for none. |
| `pi` | Optional Pi startup defaults passed to `modules.pi.defaults`; see [the schema](../modules/pi/startup-defaults-type.nix). |
| `hermes` | Attribute set passed to official `services.hermes-agent`; disabled on both Macs by default. See [Hermes configuration](../modules/hermes/README.md). |

## Linux host fields

Edit [hosts/linux.nix](../hosts/linux.nix). Each top-level attribute names a
`homeConfigurations` entry. Supply these fields for each host:

| Host field | Purpose or module option |
| --- | --- |
| `system` | Package architecture, such as `x86_64-linux` or `aarch64-linux`. |
| `username` | `home.username`. |
| `homeDirectory` | Absolute `home.homeDirectory`. |
| `authorizedKeyFiles` | Public key paths combined into Home Manager's `~/.ssh/authorized_keys`. |
| `pi` | Optional Pi startup defaults passed to `modules.pi.defaults`; see [the schema](../modules/pi/startup-defaults-type.nix). |
| `deepseekHarness.publicHost` | `modules.deepseek-harness.service.publicHost`, using the node's actual MagicDNS hostname. |
| `dockerGhcr` | Optional attribute set passed to `modules.docker-ghcr`; enables GHCR authentication through a named GitHub CLI account. See [setup and login](../modules/docker-ghcr/README.md). |
| `deepseekHarness.port` | `modules.deepseek-harness.service.port`. |
| `deepseekHarness.proxyPort` | `modules.deepseek-harness.service.proxyPort`. |
| `deepseekHarness.httpsPort` | `modules.tailscale.serve.httpsPort`. The Harness public port follows it. |
| `singBox` | Attribute set passed to `modules.sing-box`; supply `listenPort` and at least one node source. |
| `hermes` | Attribute set passed to official `services.hermes-agent`; model, state paths, private env-file paths, and messaging settings. |

For example, a host can include:

```nix
deepseekHarness = {
  port = 3080;
  proxyPort = 3081;
  httpsPort = 8443;
};
singBox = {
  listenPort = 21009;
  subscription.requestFile = "/home/alice/.config/sing-box/subscription.curl";
  routing.directDomainSuffixes = [ "internal" ];
};
```

Every `modules.sing-box.<option>` below is available as `singBox.<option>` in a
host entry. For example, `modules.sing-box.routing.directDomains` becomes
`singBox.routing.directDomains`. Omitted settings use module defaults unless
a profile supplies a value. The Linux profile enables sing-box by default;
set `singBox.enable = false` to disable it for one host.
Configure `singBox.subscription.requestFile`, `singBox.nodesFile`, or both.
Both default to `null`; local-only input does not download a subscription.
Subscription requests, node definitions, and proxy credentials remain in private
runtime files; the inventory may contain their paths.

The [Linux profile](../profiles/home/linux.nix) enables the features and connects
Serve to the private Harness proxy. It derives the public URL and trusted
authority from the hostname and HTTPS port. Port 443 is omitted from the URL;
other HTTPS ports are included. The sing-box, Harness backend, and Harness
proxy must use distinct loopback ports. Serve's HTTPS port belongs to the
tailnet listener and is not part of that loopback conflict check.

## Platform and configuration scope

Register shared public-key paths in
[the SSH key catalog](../modules/ssh/public-keys/default.nix).
[hosts/default.nix](../hosts/default.nix) passes the catalog as `sshKeys` to both
host inventories. Select keys by name, such as
`authorizedKeyFiles = [ sshKeys.personal ];`.

Set `authorizedKeyFiles` per host in [hosts/linux.nix](../hosts/linux.nix) or
[hosts/darwin.nix](../hosts/darwin.nix). Linux combines the files into a managed
`~/.ssh/authorized_keys`; Darwin passes them to nix-darwin's native
`users.users.<name>.openssh.authorizedKeys.keyFiles`. An empty list authorizes
no keys through that managed source. These files contain public keys only;
never add private keys. Tailscale SSH uses its own authorization policy.

- sing-box runs as a Linux systemd user service.
- GHCR authentication is enabled per host; the helper uses the host-provided
  Docker daemon and Compose.
- Hermes supports Linux user services and macOS launchd agents; both Macs default
  to disabled. See its [configuration guide](../modules/hermes/README.md).
- Harness policy applies on macOS and Linux. macOS uses the official desktop
  application; the Web backend and private proxy are Linux user services.
- Tailscale's `enable`, `incoming.enable`, and `ssh.enable` options apply to
  macOS and Linux. `outboundProxy` and `serve` options apply to Linux.

Edit shared enable switches and service wiring in the platform profiles.
Package selection belongs in [flake.nix](../flake.nix). On macOS, Tailscale is
configured in the [system profile](../profiles/system/darwin/default.nix), and
Harness policy in the [Home Manager profile](../profiles/home/darwin.nix).

## Maintaining this reference

Option entries are generated from Nix declarations; this introduction comes
from [configuration-intro.md](configuration-intro.md). Follow the
[generation and validation instructions](development.md#generated-reference)
after editing either source.
