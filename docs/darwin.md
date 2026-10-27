# macOS setup

English | [简体中文](darwin.zh-CN.md)

Run from the repository root as the regular user. Select the machine's role;
it is independent of the hardware model and macOS hostname:

```sh
deploy_host=laptop # Use desktop on the desktop Mac.
```

Set this variable again in each new shell.

## Before first activation

Nix and Git must already be installed. Check `username`, `homeDirectory`,
`authorizedKeyFiles`, and the application choices in
[hosts/darwin.nix](../hosts/darwin.nix) for the selected role. If enabling
Hermes, prepare its [model settings and secret file](../modules/hermes/README.md)
now; otherwise leave it disabled for this activation.

If the build needs transparent proxying, place
the official Surge Mac release at `/Applications/Surge.app`, open it, and enable
Enhanced Mode first. Homebrew Bundle adopts this copy as the managed `surge`
cask during activation.

Authenticate Proton Pass before its launch agent starts:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
```

## First activation

Activate nix-darwin once after the preparation above. This command also works
before `darwin-rebuild` is available:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host"
```

Nix may ask to trust this flake's `cache.numtide.com` substituter and public key.
Choose `Allow always` or `yes for now` if you trust the repository and cache.
Declining disables that cache and can require local builds. Restart the terminal
after activation to load the environment.

## GitHub CLI

Sign in once after activation; later shells reuse the saved login:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

`--skip-ssh-key` leaves SSH key management with the Proton Pass agent. The token
uses the system credential store when available. Keep it out of Nix values;
inject `GH_TOKEN` from a runtime secret store for headless automation.

## Hermes

Hermes is optional and disabled on `laptop` and `desktop` by default. If you
enabled it before activation, open the CLI/TUI:

```sh
hermes --tui
```

If the gateway is enabled, check it with:

```sh
launchctl print "gui/$UID/org.nix-community.home.hermes-agent"
tail -n 50 ~/Library/Logs/hermes-agent.err.log
```

Surge handles egress. To enable Hermes later or update it, follow the
[Hermes configuration and maintenance guide](../modules/hermes/README.md), then
use the routine rebuild flow. Do not run `hermes update`.

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

## Maintenance and recovery

For routine rebuilds and input updates, see the [README](../README.md).
The following Proton Pass steps are recovery and logout procedures, not part
of first setup.

If activation preceded authentication, stop the agent before logging in, then
reactivate:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
nix run .#deploy -- switch "$deploy_host"
```

Stop the agent before explicitly logging out so loaded SSH keys leave memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, switch to reload the agent in the current user session.
Future user sessions load it automatically.
