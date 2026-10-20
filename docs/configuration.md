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
| `singBox` | Attribute set passed to `modules.sing-box`; supply `listenPort` and at least one node source. |

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

## Option index

- [`modules.deepseek-harness.enable`](#modulesdeepseek-harnessenable)
- [`modules.deepseek-harness.package`](#modulesdeepseek-harnesspackage)
- [`modules.deepseek-harness.service.enable`](#modulesdeepseek-harnessserviceenable)
- [`modules.deepseek-harness.service.port`](#modulesdeepseek-harnessserviceport)
- [`modules.deepseek-harness.service.proxyPort`](#modulesdeepseek-harnessserviceproxyport)
- [`modules.deepseek-harness.service.publicHost`](#modulesdeepseek-harnessservicepublichost)
- [`modules.deepseek-harness.service.publicPort`](#modulesdeepseek-harnessservicepublicport)
- [`modules.sing-box.enable`](#modulessing-boxenable)
- [`modules.sing-box.listenPort`](#modulessing-boxlistenport)
- [`modules.sing-box.nodesFile`](#modulessing-boxnodesfile)
- [`modules.sing-box.package`](#modulessing-boxpackage)
- [`modules.sing-box.proxyCredentialsFile`](#modulessing-boxproxycredentialsfile)
- [`modules.sing-box.routing.directDomainSuffixes`](#modulessing-boxroutingdirectdomainsuffixes)
- [`modules.sing-box.routing.directDomains`](#modulessing-boxroutingdirectdomains)
- [`modules.sing-box.routing.directIpCidrs`](#modulessing-boxroutingdirectipcidrs)
- [`modules.sing-box.routing.proxyDomainSuffixes`](#modulessing-boxroutingproxydomainsuffixes)
- [`modules.sing-box.subscription.requestFile`](#modulessing-boxsubscriptionrequestfile)
- [`modules.tailscale.enable`](#modulestailscaleenable)
- [`modules.tailscale.incoming.enable`](#modulestailscaleincomingenable)
- [`modules.tailscale.outboundProxy.enable`](#modulestailscaleoutboundproxyenable)
- [`modules.tailscale.serve.enable`](#modulestailscaleserveenable)
- [`modules.tailscale.serve.httpsPort`](#modulestailscaleservehttpsport)
- [`modules.tailscale.serve.target`](#modulestailscaleservetarget)
- [`modules.tailscale.ssh.enable`](#modulestailscalesshenable)

## Module options

## modules\.deepseek-harness\.enable

Whether to enable DeepSeek Harness policy\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.package



DeepSeek Harness CLI package, required when the Linux Web service is
enabled and selected by the flake\. macOS uses the official desktop app\.



*Type:*
package



*Example:*

```nix
llm-agents.packages.${host.system}.dsh
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.service\.enable



Whether to enable the persistent Linux DeepSeek Harness Web service\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.service\.port



Loopback port for the Harness backend; it must differ from the proxy port\.



*Type:*
integer between 1 and 65535 (both inclusive)



*Default:*

```nix
3080
```



*Example:*

```nix
13080
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.service\.proxyPort



Loopback port for the cookie-rewriting proxy used by Tailscale Serve\.



*Type:*
integer between 1 and 65535 (both inclusive)



*Default:*

```nix
3081
```



*Example:*

```nix
13081
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.service\.publicHost



Tailnet HTTPS hostname, without a scheme or port, required when the Web
service is enabled\. The Linux inventory supplies tailscaleHostname\.



*Type:*
string matching the pattern \[a-zA-Z0-9]\[a-zA-Z0-9\.-]\*



*Example:*

```nix
"server.example.ts.net"
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.deepseek-harness\.service\.publicPort



Public HTTPS port advertised by the Web service\. The Linux profile
derives it from modules\.tailscale\.serve\.httpsPort\. Port 443 is omitted
from the launch URL; other ports enter both the URL and trusted host\.



*Type:*
integer between 1 and 65535 (both inclusive)



*Default:*

```nix
443
```



*Example:*

```nix
8443
```

*Declared by:*
 - [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)



## modules\.sing-box\.enable



Whether to enable an authenticated local HTTP/SOCKS proxy with private proxy nodes\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.package



The sing-box package to use\.



*Type:*
package



*Default:*

```nix
pkgs.sing-box
```



*Example:*

```nix
pkgs.sing-box
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.listenPort



Fixed loopback HTTP/SOCKS port, required when enabled\. The port must be
between 1024 and 65535; conflicts abort activation\. The Linux profile
also checks for conflicts with the Harness backend and proxy\.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Example:*

```nix
21009
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.nodesFile



Private runtime native sing-box JSON with an outbounds array, at most
8 MiB\. Only independent proxy nodes are imported; listeners, routing,
DNS, and proxy groups remain module-managed\. Node tags must be unique
within each source; local and subscription tags are namespaced separately\.
Changes take effect on the next switch\. Null disables local node input\.
Configure this option, subscription\.requestFile, or both\. Use an absolute
path outside Git and the Nix store\. The directory must have mode 0700 and
the file mode 0600; Nix never reads its contents\. Share links are not supported\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/home/alice/.config/sing-box/nodes.json"
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.proxyCredentialsFile



Private username/password JSON, generated once if absent\. Use an
absolute path outside the Nix store\. The file has mode 0600 and remains
runtime state; Nix never reads its contents\.



*Type:*
string



*Default:*

```nix
"${config.xdg.stateHome}/sing-box/auth.json"
```



*Example:*

```nix
"/home/alice/.local/state/sing-box/lab-auth.json"
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.routing\.directDomainSuffixes



Local domain suffixes, without a leading dot; also included in no_proxy\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "internal"
]
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.routing\.directDomains



Additional exact hostnames resolved locally and routed directly\.
localhost is always included\. These names also enter no_proxy and
NO_PROXY for login shells and with-proxy commands\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "git.lab.example"
]
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.routing\.directIpCidrs



Additional directly reachable campus or LAN networks in CIDR notation\.
Private IP destinations already go direct\. These rules apply inside
sing-box and are not added to no_proxy\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "203.0.113.0/24"
]
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.routing\.proxyDomainSuffixes



Domain suffixes routed through proxy nodes before the China
domain set is checked\. Private destinations and explicit direct
domain, suffix, and CIDR rules take precedence\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "proxy.example"
]
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.sing-box\.subscription\.requestFile



Private runtime curl configuration containing the HTTPS subscription URL
and headers\. The response must be native sing-box JSON with an outbounds
array, at most 8 MiB\. Null disables subscription downloads\. Configure
this option, nodesFile, or both; both sources join the same URLTest group\.
Use an absolute path outside Git and the Nix store\. The directory must
have mode 0700 and the file mode 0600; Nix never reads its contents\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/home/alice/.config/sing-box/lab.curl"
```

*Declared by:*
 - [modules/sing-box/default\.nix](../modules/sing-box/default.nix)



## modules\.tailscale\.enable



Whether to enable a userspace Tailscale daemon\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/tailscale/options\.nix](../modules/tailscale/options.nix)



## modules\.tailscale\.incoming\.enable



Whether to enable incoming tailnet connections to local services\. Userspace networking
forwards ordinary TCP/UDP traffic to loopback; tailnet access rules must
restrict which peers and ports can connect
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/tailscale/options\.nix](../modules/tailscale/options.nix)



## modules\.tailscale\.outboundProxy\.enable



Whether to enable a local SOCKS5 and HTTP proxy for outgoing tailnet connections on
127\.0\.0\.1:1055\. Available on Linux; this does not select an exit node
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)



## modules\.tailscale\.serve\.enable



Whether to enable a tailnet-only HTTPS reverse proxy on Linux\. Requires incoming\.enable,
MagicDNS, tailnet HTTPS certificates, and access to the selected HTTPS
port\. Enabling Serve unlocks native daemon preferences so the foreground
CLI can manage its mapping; Nix reapplies preferences on daemon startup
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)



## modules\.tailscale\.serve\.httpsPort



Tailnet HTTPS port for Tailscale Serve\.



*Type:*
integer between 1 and 65535 (both inclusive)



*Default:*

```nix
443
```



*Example:*

```nix
8443
```

*Declared by:*
 - [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)



## modules\.tailscale\.serve\.target



Loopback HTTP backend, required when Serve is enabled\. The Linux profile
derives this URL from the Harness proxy port\. The mapping exists for
the systemd service lifetime; Funnel is not enabled\.



*Type:*
string matching the pattern http://127\[\.]0\[\.]0\[\.]1:\[0-9]+



*Example:*

```nix
"http://127.0.0.1:3081"
```

*Declared by:*
 - [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)



## modules\.tailscale\.ssh\.enable



Whether to enable Tailscale SSH\. Requires incoming\.enable plus tailnet rules allowing TCP 22
and SSH access for the local account
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/tailscale/options\.nix](../modules/tailscale/options.nix)
