# macOS setup

English | [简体中文](darwin.zh-CN.md)

Run from the repository root as the regular user. Select the machine's role;
it is independent of the hardware model and macOS hostname:

```sh
darwin_profile=laptop # Use desktop on the desktop Mac.
```

Set this variable again in each new shell.

## First activation

Nix must already be installed. If the build needs transparent proxying, place
the official Surge Mac release at `/Applications/Surge.app`, open it, and enable
Enhanced Mode first. Homebrew Bundle adopts this copy as the managed `surge`
cask during activation.

Authenticate Proton Pass before its launch agent starts, then activate
nix-darwin. These commands also work before `darwin-rebuild` is available:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$darwin_profile"
```

Nix may ask to trust this flake's `cache.numtide.com` substituter and public key.
Choose `Allow always` or `yes for now` if you trust the repository and cache.
Declining disables that cache and can require local builds. Restart the terminal
after activation to load the environment.

## GitHub CLI

Sign in after activation:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

`--skip-ssh-key` leaves SSH key management with the Proton Pass agent. The token
uses the system credential store when available. Keep it out of Nix values;
inject `GH_TOKEN` from a runtime secret store for headless automation.

## Proton Pass session recovery and logout

If activation preceded authentication, stop the agent before logging in, then
reactivate:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
nix run .#deploy -- switch "$darwin_profile"
```

Stop the agent before explicitly logging out so loaded SSH keys leave memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, switch to reload the agent in the current user session.
Future user sessions load it automatically.

## Remote access and Harness

- [Tailscale ingress](../modules/tailscale/README.md) covers enrollment,
  connection checks, and logs. Surge continues to handle egress.
- [macOS Remote Login](../profiles/system/darwin/remote-login/README.md) uses
  separate authorization from Tailscale SSH.
- Open **DeepSeek Harness**, installed by Homebrew, and add an API key in
  **Settings → Models**. Credentials and sessions stay under `~/.dsh`.
  [Harness policy](../modules/deepseek-harness/default.nix) disables telemetry,
  additional session-log uploads, and Desktop product analytics; model requests
  still send task context.

For routine rebuilds and input updates, see the [README](../README.md).
