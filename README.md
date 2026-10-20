## Configuration reference

See the [configuration reference](docs/configuration.md) for Linux host fields
and all sing-box, DeepSeek Harness, and Tailscale options, including defaults,
examples, and constraints.

## Choose a Darwin profile

Set the profile for the current machine before running the commands below:

```sh
darwin_profile=laptop
# Use `desktop` on the desktop Mac.
```

Set the variable again after opening a new shell. The profile names describe
the machine's role and are independent of its hardware model or macOS hostname.

## First-time setup

On a new machine, `darwin-rebuild` is not available until nix-darwin has been
activated for the first time. Before the first activation, authenticate Proton
Pass as the regular user so its launch agent does not race with interactive
session initialization:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
```

Then run the initial activation from the repository root:

```sh
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ".#$darwin_profile"
```

If the full build requires transparent proxying, download the latest official
Surge Mac release, place `Surge.app` at `/Applications/Surge.app`, open it, and
enable Enhanced Mode before running the command above. Homebrew Bundle uses its
adoption flow for an existing app declared as a cask, so the full activation
registers the manually placed application as the managed `surge` cask instead
of installing a conflicting second copy.

The `-H` option gives the root process its own home directory and avoids Nix's
warning that `/Users/jinhaohuang` is not owned by root. It does not change the
user targeted by the nix-darwin or Home Manager configuration.

During the first build, Nix asks whether to trust the `cache.numtide.com`
substituter and its public key declared by this flake. This is a security prompt,
not a build failure. Choose `Allow always` when the repository and the Numtide
cache are trusted, or `yes for now` to allow them only for the current build.
Declining the prompt disables that binary cache and may cause more packages to
be built locally.

Restart the terminal after the command completes so the updated environment is
loaded.

### GitHub CLI authentication

Home Manager installs GitHub CLI and configures it to use SSH for Git
operations. Authentication remains machine-local runtime state so credentials
never enter the repository or the Nix store. After the first activation, sign
in as the regular user:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

The `--skip-ssh-key` option keeps SSH key management with the Proton Pass agent.
The interactive login stores the OAuth token in the system credential store
when available. Do not add tokens to `programs.gh`, `home.sessionVariables`, or
other Nix values. For headless automation, inject `GH_TOKEN` from the runtime
secret store instead of persisting it in this configuration.

### Proton Pass session lifecycle

If the configuration was activated before Proton Pass was authenticated, stop
the already loaded SSH agent before logging in, then reactivate the
configuration:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
sudo darwin-rebuild switch --flake ".#$darwin_profile"
```

Authentication and launch-agent lifecycles are intentionally managed
separately. Stop the agent before explicitly logging out so it cannot retain
loaded SSH keys in memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, set `darwin_profile` again and run
`sudo darwin-rebuild switch --flake ".#$darwin_profile"` to load the agent in
the current user session. Future user sessions load it automatically.

## Subsequent rebuilds

```sh
darwin_profile=laptop # Use `desktop` on the desktop Mac.
sudo darwin-rebuild switch --flake ".#$darwin_profile"
```

## Pi startup defaults

Set `pi.model = { provider = "provider-id"; id = "model-id"; };` and
`pi.thinkingLevel` in [the Darwin inventory](hosts/darwin.nix) or
[the Linux inventory](hosts/linux.nix). Omitted values use Pi defaults.

For local overrides, create the Git-ignored `hosts/inventory.local.nix`, for
example `{ laptop.pi.thinkingLevel = "high"; }`, then build from the repository
root:

```sh
nix build --no-link ".#darwinConfigurations.$darwin_profile.system" \
  --override-input host-local "path:$PWD/hosts/inventory.local.nix"
```

Pass the same override when switching; without it, only tracked defaults apply.
Omitted fields inherit; `null` clears a default, and `model` replaces the provider
and ID together. Changes require rebuilding and switching; Pi's global settings
remain read-only. Keep credentials out of both inventories: ignored overrides
also enter the Nix store.

## Linux development servers

`hosts/linux.nix` declares each server's account, architecture, ports, and routing.
On `iscas-r750xa`, run the commands below as `huangjh` from the repository root,
using the existing Lix installation (no sudo).

### First-time setup

Before switching, review existing shell startup files and preserve any required
lab initialization in the shell modules. Obtain the Home Manager CLI selected
by this configuration, then build and activate the user environment:

```sh
hm_cli=$(nix build --no-link --print-out-paths \
  .#homeConfigurations.iscas-r750xa.config.programs.home-manager.package)
"$hm_cli/bin/home-manager" -b before-hm switch --flake .#iscas-r750xa
```

The `-b before-hm` option moves conflicting existing files to paths with the
`.before-hm` suffix. It preserves the files, but does not keep their startup
behavior.

### Subsequent updates

```sh
home-manager switch --flake .#iscas-r750xa
```

### Optional validation and troubleshooting

To preview activation, run this after setting `hm_cli` above and before the
actual switch. The `-n` option skips activation changes, but may still build
or download packages:

```sh
"$hm_cli/bin/home-manager" -n -b before-hm switch --flake .#iscas-r750xa
```

To check that the user environment builds without activating it:

```sh
nix build --no-link .#homeConfigurations.iscas-r750xa.activationPackage
```

A separate build is optional because `home-manager switch` also builds the
environment. If Nix reports store or daemon connection errors, check store
access with:

```sh
nix store ping
```

### Shell and SSH usage

Git uses the same SSH signing key on both platforms. For a forwarded agent,
connect with `ssh -A iscas-r750xa`; the agent must contain the signing key.
Linux keeps the incoming `SSH_AUTH_SOCK`. SSH host inventory is controlled by
`modules.ssh.includeHosts`; local overrides go in `~/.ssh/config.local`.
The login shell stays Bash; run `zsh` explicitly or use tmux. Language toolchains
and CUDA dependencies belong in project environments.

### Tailscale without sudo

Linux uses a systemd user service with incoming access and Tailscale SSH enabled;
the outbound proxy is disabled. Configure these in `profiles/home/linux.nix`.

After activation, enroll once using the user daemon's CLI:

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

Open `AuthURL` to approve the device; use `tailscale-user ip -4` for its address.
For shared servers, assign a dedicated tag in Tailscale Console, allow your
account to reach TCP 22, and add an SSH rule for `huangjh`. Remove rules granting
the server access to other devices; disabling the proxy alone does not enforce
this restriction. See [grants](https://tailscale.com/docs/reference/syntax/grants).

The Linux profile requires linger during activation and attempts to enable it;
activation fails if host policy denies it. Logs: `journalctl --user -u tailscaled`.

### sing-box without sudo

Create `~/.config/sing-box/subscription.curl` outside Git with directory mode
`0700` and file mode `0600`. Each switch repairs permissions in the sing-box XDG
config and state directories for user-owned directories and configured regular
files; read-only inputs stay read-only. Links and wrong owners are rejected;
custom locations elsewhere require correct permissions in advance.
Use native sing-box JSON over HTTPS:

```text
url = "https://subscription.example/private-token?format=json"
```

For local nodes, set `singBox.nodesFile` in [hosts/linux.nix](hosts/linux.nix) to a
private JSON file containing `{"outbounds": [...]}`, with the same permissions.
Set `singBox.subscription.requestFile = null` to skip downloads, or configure
both inputs to combine their nodes in one automatic selection group. Only
independent native sing-box nodes are imported; share links are not supported.

Each switch reads the configured sources, validates a private configuration, and
restarts only when needed. Input or validation failure preserves the running
proxy. Startup failure aborts the switch and attempts to restore the previous
configuration using the current sing-box package. If recovery fails, restore the
previous Home Manager generation and its saved private configuration; binaries
are not rolled back automatically. Proxy credentials are generated once in
`~/.local/state/sing-box/auth.json` (mode `0600`). No secret is read by Nix
evaluation or stored in the Nix store.

Configure the port and local routing in the host's `singBox` entry in
[the Linux inventory](hosts/linux.nix). The authenticated mixed listener binds
loopback; an occupied port aborts activation. Local destinations and pinned China
domains go direct; other requests
use proxy nodes. Add laboratory domains and directly reachable campus
networks before use. Tailnet-only targets need a separate userspace Tailscale exit.

For one command, or a temporary proxy-enabled shell:

```sh
with-proxy git fetch
with-proxy bash
```

Login sessions receive a small `no_proxy`/`NO_PROXY` list. The wrapper reads
credentials into the child environment and uses the active proxy's bypass list.
It refuses to run commands when the managed proxy is unavailable.
Start a new proxy-enabled shell after changing the port or credentials.
Logs: `journalctl --user -u sing-box`; private download/check diagnostics remain
under `~/.local/state/sing-box/snapshots/`.

## DeepSeek Harness

On macOS, open **DeepSeek Harness** after activation; Homebrew installs the
official desktop application. Configure an API key in **Settings → Models**.
Credentials and sessions stay under `~/.dsh`, outside Nix.
[Harness policy](modules/deepseek-harness/default.nix) disables telemetry,
additional session-log uploads, and Desktop product analytics; model requests
still send task context.

Linux runs the Web backend and Tailscale Serve as systemd user services. Connect
to Tailscale, then use the HTTPS launch URL printed in the backend journal:

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

Set each host's three ports in the [Linux inventory](hosts/linux.nix); proxy
targets and the launch URL follow automatically.

The URL includes a private launch token; do not share the journal. HTTPS requires
MagicDNS, tailnet HTTPS certificates, and an access rule allowing intended peers
to the configured HTTPS port (443 by default). A loopback proxy adds secure
cookies; no Funnel is enabled.
Check ingress with `tailscale-user serve status` and
`systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve`.

## How to update

### Update all input

nix flake update

### Update specific input

nix flake update <input-name>
